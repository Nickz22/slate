import { api, wire, track } from "lwc";
import LightningModal from "lightning/modal";
import { NavigationMixin } from "lightning/navigation";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import getDivisions from "@salesforce/apex/L4GController.getDivisions";
import SERVICE_TYPE from "@salesforce/schema/Opportunity.Lead_Type__c";
import STAGENAME from "@salesforce/schema/Opportunity.StageName";
import { getRecord } from "lightning/uiRecordApi";
import getPricebook from "@salesforce/apex/L4GController.getPricebook";
import getOpportunityName from "@salesforce/apex/L4GController.getOpportunityName";

const FIELDS = ["Contact.AccountId"];

export default class L4gNewOpportunity extends NavigationMixin(LightningModal) {
  @api initialInquiry;
  @api objectName;
  @api contactId;
  @api isLightningForGmail = false;
  // only populated when used in the Opportunity New Override
  @api givenAccountId;
  get allServiceOptions() {
    return this._allServiceOptions;
  }
  set allServiceOptions(value) {
    this._allServiceOptions = value;
    this.getDivisions();
  }
  @track serviceTypeOptions;
  @track stageOptions;
  _allServiceOptions;
  defaultStage = "Qualification - Project";
  opportunityId;
  get accountId() {
    return this.givenAccountId || this._accountId;
  }
  set accountId(value) {
    this._accountId = value;
  }
  priceBookId;
  showSpinner = true;

  connectedCallback() {
    this.getDivisions();
  }

  @wire(getRecord, { recordId: "$contactId", fields: FIELDS })
  wiredContact({ error, data }) {
    if (data) {
      this.accountId = data.fields.AccountId.value;
    } else if (error) {
      console.error("Error retrieving account ID:", error);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: SERVICE_TYPE
  })
  serviceTypes({ data, error }) {
    if (data) {
      this.allServiceOptions = data.values;
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: STAGENAME
  })
  getStageName({ data, error }) {
    if (data) {
      const stageToExclude = [
        "Closed Won",
        "Closed Lost",
        "Proposal",
        "Negotiation"
      ];
      this.stageOptions = data?.values?.filter((val) => {
        return !stageToExclude.includes(val.value);
      });
    }
  }

  get header() {
    return `Create ${this.objectName}`;
  }

  get closeDate() {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, "0");
    const day = this.divisionNames?.includes("Slate")
      ? String(new Date(year, month, 0).getDate()).padStart(2, "0") // Last day of the month
      : String(today.getDate()).padStart(2, "0"); // Today's date

    return `${year}-${month}-${day}`;
  }

  handleSuccess(event) {
    this.showSpinner = false;
    this.opportunityId = event.detail.id;
    if (this.isLightningForGmail) {
      this.close(this.opportunityId);
    } else {
      this.navigateToNewRecord(this.opportunityId);
    }
  }

  navigateToNewRecord(recordId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Opportunity",
        actionName: "view"
      }
    });
  }

  handleCancel() {
    this.close(null);
  }

  async handleSubmit(event) {
    event.preventDefault();
    let fields = event.detail.fields;
    fields.Pricebook2Id = this.priceBookId;
    const inputs = this.template.querySelectorAll("lightning-combobox");
    inputs.forEach((input) => {
      fields[input.name] = input.value;
    });
    const leadType = fields.Lead_Type__c;
    fields.Name = await getOpportunityName({
      serviceType: leadType,
      accountId: fields.AccountId
    });
    if (!leadType) {
      this.handleError({
        detail: { detail: "Lead Type is required" }
      });
      return;
    }
    const fullServiceType = this.serviceTypeOptions?.find((option) =>
      option.value.includes(leadType)
    )?.label;
    const divisionPrepensionInServiceType = fullServiceType
      ?.toLowerCase()
      ?.includes("align")
      ? "align"
      : fullServiceType?.toLowerCase()?.includes("slate")
        ? "slate"
        : fullServiceType?.toLowerCase()?.includes("palermo")
          ? "palermo"
          : null;
    if (!divisionPrepensionInServiceType) {
      this.handleError({
        detail: { detail: "Division prepension in service type not found" }
      });
      return;
    }
    const divisionId =
      divisionPrepensionInServiceType &&
      this.divisions.find(
        (division) =>
          division.Name.toLowerCase() === divisionPrepensionInServiceType
      )?.Id;
    if (!divisionId) {
      this.handleError({
        detail: { detail: "Division ID not found" }
      });
      return;
    }
    fields.Division__c = divisionId;
    this.template.querySelector("lightning-record-edit-form").submit(fields);
    this.showSpinner = true;
  }

  handleError(event) {
    console.error(event?.detail?.detail);
    this.showSpinner = false;
  }

  async getDivisions() {
    this.divisions = await getDivisions();
    this.divisionNames = this.divisions.map((division) => division.Name);
    this.serviceTypeOptions = this.allServiceOptions?.filter((option) =>
      this.divisions.some((division) => option.label.startsWith(division.Name))
    );

    const data = await getPricebook();
    this.priceBookId = data.find((option) =>
      this.divisions.some((division) => option.Name.includes(division.Name))
    )?.Id;
    this.showSpinner = false;
  }
}
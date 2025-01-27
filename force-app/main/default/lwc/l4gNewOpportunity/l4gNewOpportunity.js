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
import cloneRecord from "@salesforce/apex/L4GController.cloneRecord";

const FIELDS = ["Contact.AccountId"];
const WON_PRODUCTION_TYPES = ['Slate - Brand Content Production','Slate - CGI','Slate - Brand Content','Slate - Motion','Slate - Studio & Eq','Align - Retouch','Palermo - Branding','Palermo - Content'];
const WON_POST_PRODUCTION_TYPES = ['Slate - Retouch','Align - Retouch'];
const SLATE_CGI_SERVICE = 'Slate - CGI';
const SLATE_RETOUCHING_SERVICE = 'Slate - Retouching - Slate';
const PALERMO_BRANDING_SERVICE = 'Palermo - Branding';
export default class L4gNewOpportunity extends NavigationMixin(LightningModal) {
  @api initialInquiry;
  @api objectName;
  @api contactId;
  @api recordId;
  @api latestOpp;
  @api hasExistingOpp = false;
  @api isCloned = false;
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
  get isNotOfAlignType(){
    return !(this.serviceType?.toLowerCase().includes('align') || (this.divisionNames?.length === 1 && this.divisionNames?.indexOf('Align') !== -1));
  }
  get showCloseDate(){
    return this.isNotOfAlignType && !(this.serviceType == SLATE_CGI_SERVICE || this.serviceType == SLATE_RETOUCHING_SERVICE);
  }
  get showShootDates(){
    return this.showCloseDate && (this.serviceType != PALERMO_BRANDING_SERVICE);
  }
  @track serviceTypeOptions;
  @track stageOptions;
  _allServiceOptions;
  _closeDate;
  defaultStage = "Qualification - Project";
  defaultServiceType;
  defaultLeadSource;
  opportunityId;
  wonProductionTypes = WON_PRODUCTION_TYPES;
  wonPostProductionTypes = WON_POST_PRODUCTION_TYPES;
  get accountId() {
    return this.givenAccountId || this._accountId;
  }
  set accountId(value) {
    this._accountId = value;
  }
  priceBookId;
  showSpinner = true;
  serviceType;


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
        "Closed Lost"
      ];
      this.stageOptions = data?.values?.filter((val) => {
        return !stageToExclude.includes(val.value);
      });
    }
  }
  
  get header() {
    return this.isCloned ? `Clone ${this.objectName}`:`Create ${this.objectName}`;
  }
  set closeDate(value){
    this._closeDate = value;
  }
  get closeDate() {
    if(this._closeDate){
      return this._closeDate;
    }
    else{
      return this.getCloseDate();
    }  
  }
  handleLoad(event) {
    if(this.isCloned){
      const inputFieldValue = event.detail?.records[this.recordId]?.fields?.Lead_Type__c?.value;
      this.defaultServiceType = inputFieldValue;
      this.defaultStage = (this.defaultServiceType.toLowerCase().includes('retouch')||this.defaultServiceType.toLowerCase().includes('retouching'))?'Won - Post Production':'Won - Production';	
      this.handleCloseDateChange(this.defaultServiceType);
      const leadSource = this.template.querySelector('lightning-input-field[data-field="LeadSource"]');
      leadSource.value = 'Return Client';
      const initialInquiry = this.template.querySelector('lightning-input-field[data-field="initialInquiry"]');
      initialInquiry.value = this.initialInquiry;
    }else if(this.hasExistingOpp){
      const leadSource = this.template.querySelector('lightning-input-field[data-field="LeadSource"]');
      leadSource.value = 'Return Client';
      this.defaultStage = this.latestOpp?.StageName || this.defaultStage;
      let serviceType = this.allServiceOptions.find((service)=>{
        return service.label?.toLowerCase() === this.latestOpp?.Lead_Type__c?.toLowerCase();
      } );
      
      this.serviceType = this.serviceType ? this.serviceType : serviceType?.label;
      this.defaultServiceType = serviceType?.value;
    }
}
  handleServiceTypeChange(event){
    this.handleCloseDateChange(event.target.value);
  }
  handleCloseDateChange(value){
    const selectedOption = this.allServiceOptions.find(option => option.value === value);
    if (selectedOption) {
        this.serviceType = selectedOption.label;
      }
    this.closeDate = this.getCloseDate();
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
    if(!this.showCloseDate) fields.CloseDate = this.closeDate;
    this.showSpinner = true;
    if (!leadType) {
      this.handleError({
        detail: { detail: "Lead Type is required" }
      });
      return;
    }
    const divisionPrepensionInServiceType = leadType
      ?.toLowerCase()
      ?.includes("align")
      ? "align"
      : leadType?.toLowerCase()?.includes("palermo")
        ? "palermo"
        : "slate";
    const divisionId =
      divisionPrepensionInServiceType &&
      this.divisions.find(
        (division) =>
          division.Name.toLowerCase() === divisionPrepensionInServiceType
      )?.Id;
    fields.Division__c = divisionId;
    if(this.isCloned){
      this.cloneOpportunity(this.recordId, fields);
      return;
    }
    this.template.querySelector("lightning-record-edit-form").submit(fields);
  }

  cloneOpportunity(recordId, fields){
    cloneRecord({ recordId: recordId, opportunityData: fields })
      .then((data) => {
        this.showSpinner = false;
        this.close(data);
      })
      .catch((error) => {
        this.error = error;
        console.error("Error cloning record:", error);
      });
  }
  handleError(event) {
    console.error(event?.detail?.detail);
    this.showSpinner = false;
  }
  getCloseDate(serviceType){
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, "0");
    const day = (this.serviceType?.includes("Slate") && this.showCloseDate)
      ? String(new Date(year, month, 0).getDate()).padStart(2, "0") // Last day of the month
      : String(today.getDate()).padStart(2, "0"); // Today's date

    return `${year}-${month}-${day}`;
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
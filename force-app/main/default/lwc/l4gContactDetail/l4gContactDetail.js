import { LightningElement, wire, api, track } from "lwc";
import cloneRecord from "@salesforce/apex/L4GController.cloneRecord";
import getFieldsToView from "@salesforce/apex/L4GController.getFieldsToView";
import getRelatedOpportunities from "@salesforce/apex/L4GController.getRelatedOpportunities";
import { refreshApex } from "@salesforce/apex";
import l4gNewOpportunity from "c/l4gNewOpportunity";
import getSfdcURL from "@salesforce/apex/L4GController.getSfdcURL";

export default class L4gContactDetail extends LightningElement {
    @api recordId;
    @api relatedListApiName = "Opportunity";
    @api initialInquiry;
    @track relatedRecords;
    @track error;
    @track columns = [];
    @track fields = [];

    _wiredMarketData;
    showSpinner = true;

    @wire(getSfdcURL)
    sfdcUrl;

    @wire(getFieldsToView, {
        fieldSetName: "L4G_NewContact",
        objectName: "Contact"
    })
    wiredFieldSet({ error, data }) {
        if (data) {
            this.fields = data;
        } else if (error) {
            this.error = error;
        }
    }

    createColumns(fields) {
        const actions = [{ label: "Clone", name: "clone" }];

        return [
            {
                label: "Name",
                fieldName: "url",
                type: "url",
                typeAttributes: {
                    label: { fieldName: "Name" },
                    tooltip: { fieldName: "tooltipText" },
                    target: '_blank'
                }
            },
            {
                label: "Stage",
                fieldName: "StageName",
                type: "Text"
            },
            {
                type: "action",
                typeAttributes: { rowActions: actions }
            }
        ];
    }

    @wire(getRelatedOpportunities, { contactId: "$recordId" })
    wiredRelatedList(wireResult) {
        const { error, data } = wireResult;
        this._wiredMarketData = wireResult;
        if (data) {
            this.columns = this.createColumns(data.fields);
            this.relatedRecords = data.map((row) => {
                return {
                    ...row,
                    tooltipText: this.tooltipContent(row),
                    url:`${this.sfdcUrl.data}/${row.Id}`
                };
            });
            this.showSpinner = false;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.relatedRecords = undefined;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case "clone":
                this.cloneRecord(row);
                break;
            default:
        }
    }

    connectedCallback(){
        refreshApex(this._wiredMarketData);
    }

    cloneRecord(row) {
        this.showSpinner = true;
        cloneRecord({ recordId: row.Id, emailContent: this.initialInquiry })
            .then(() => {
                return refreshApex(this._wiredMarketData);
            })
            .catch((error) => {
                this.error = error;
                console.error("Error cloning record:", error);
            });
    }
    tooltipContent(data) {
        let description = data["Opportunity_Descriptor__c"]
            ? data["Opportunity_Descriptor__c"]
            : "";
        let quoteName = data["SBQQ__PrimaryQuote__r"]
            ? data["SBQQ__PrimaryQuote__r"]["Name"]
            : "";
        return `Descriptor: ${description}\nQuote: ${quoteName}\nCloseDate: ${data["CloseDate"]}\n`;
    }
    async handleNewOpportunity() {
        this.showSpinner = true;
        const result = await l4gNewOpportunity.open({
            size: "large",
            description: "Accessible description of modal's purpose",
            objectName: "Opportunity",
            contactId: this.recordId,
            initialInquiry: this.initialInquiry
        });
        this.defaultRecordId = result;
        this.showSpinner = false;
        return refreshApex(this._wiredMarketData);
    }
    handleBackClick(event) {
        this.dispatchEvent(new CustomEvent("back"));
    }
}
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import getDivisionNames from '@salesforce/apex/L4GController.getDivisionNames';
import SERVICE_TYPE from "@salesforce/schema/Opportunity.Lead_Type__c";
import STAGENAME from "@salesforce/schema/Opportunity.StageName";
import { getRecord } from 'lightning/uiRecordApi';
import getPricebook from '@salesforce/apex/L4GController.getPricebook';
import getOpportunityName from '@salesforce/apex/L4GController.getOpportunityName';


const FIELDS = ['Contact.AccountId'];

export default class L4gNewOpportunity extends LightningModal {
    @api initialInquiry;
    @api objectName;
    @api contactId;
    @api
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
    defaultStage = 'Qualification - Project';
    opportunityId;
    accountId;
    priceBookId;
    showSpinner = true; // will be falsed by getDivisionNames

    connectedCallback() {
        const setDivisionName = async () => {
            this.divisionNames = await getDivisionNames();
            this.showSpinner = false;
        }
        setDivisionName();
    }

    @wire(getRecord, { recordId: '$contactId', fields: FIELDS })
    wiredContact({ error, data }) {
        if (data) {
            this.accountId = data.fields.AccountId.value;
        } else if (error) {
            console.error('Error retrieving account ID:', error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: SERVICE_TYPE })
    serviceTypes({ data, error }) {
        if (data) {
            this.allServiceOptions = data.values;
        }
    };

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: STAGENAME })
    getStageName({ data, error }) {
        if (data) {
            const stageToExclude = ['Closed Won', 'Closed Lost', 'Proposal', 'Negotiation'];
            this.stageOptions = data.values.filter((val) => {
                return !stageToExclude.includes(val.value);
            });
        }
    };
    get header() {
        return `Create ${this.objectName}`;
    }
    get closeDate() {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = this.divisionNames?.includes("Slate") 
            ? String(new Date(year, month, 0).getDate()).padStart(2, '0')  // Last day of the month
            : String(today.getDate()).padStart(2, '0');  // Today's date

        return `${year}-${month}-${day}`;
    }
    handleSuccess(event) {
        this.showSpinner = false;
        this.opportunityId = event.detail.id;
        this.close(this.opportunityId);
    }
    handleCancel(event) {
        this.close(null);
    }
    handleOkay() {
        this.template.querySelector('lightning-record-edit-form').submit();
    }
    async handleSubmit(event) {
        event.preventDefault();
        let fields = event.detail.fields;
        fields.Pricebook2Id = this.priceBookId;
        const inputs = this.template.querySelectorAll('lightning-combobox');
        inputs.forEach(input => {
            fields[input.name] = input.value;
        });
        const leadType = fields.Lead_Type__c;
        fields.Name = await getOpportunityName({serviceType: leadType, accountId: this.accountId});
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.showSpinner = true;
    }
    handleError(event) {
        console.error(event?.detail?.detail);
        this.showSpinner = false;
    }
    getDivisions() {
        getDivisionNames().then((result) => {
            this.serviceTypeOptions = this.allServiceOptions.filter(option =>
                result.some(prefix => option.label.startsWith(prefix))
            );
            getPricebook().then((data) => {
                this.priceBookId = data.find(option =>
                    result.some(prefix => option.Name.includes(prefix))
                )?.Id;
            })
        })
    }
}
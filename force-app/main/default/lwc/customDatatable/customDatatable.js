import { LightningElement, api, track, wire } from 'lwc';
import STAGENAME from "@salesforce/schema/Opportunity.StageName";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { updateRecord } from 'lightning/uiRecordApi';
import l4gNewOpportunity from "c/l4gNewOpportunity";

export default class CustomDatatable extends LightningElement {
    @api actions = [{ name: 'edit', label: 'Edit' },{ name: 'clone', label: 'Clone' }]; 
    @track editableRowId = null; 
    @track stageOptions; 
    _relatedRecords = []; 
    originalRecordData = {};
    showSpinner = false;
    @wire(getPicklistValues, {
        recordTypeId: "012000000000000AAA",
        fieldApiName: STAGENAME
    })
    getStageName({ data, error }) {
        if (data) {
            const stageToExclude = ["Closed Won", "Closed Lost"];
            this.stageOptions = data.values.filter(val => !stageToExclude.includes(val.value));
        }
    }

    @api
    get relatedRecords() {
        return this._relatedRecords.map(record => ({
            ...record,
            isEditable: record.Id === this.editableRowId
        }));
    }

    set relatedRecords(value) {
        this._relatedRecords = value ? JSON.parse(JSON.stringify(value)) : [];
    }

    handleInputChange(event) {
        const recordId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        const fieldValue = event.target.value;

        const record = this._relatedRecords.find(rec => rec.Id === recordId);
        if (record) {
            record[fieldName] = fieldValue;
        }
    }

    handleRowAction(event) {
        const actionName = event.target.title;
        const rowId = event.target.dataset.id;

        if (actionName === 'Edit') {
            this.startEditing(rowId);
        } else if(actionName === 'Clone'){
            this.showCloneModal(rowId);
        }
    }
    startEditing(rowId) {
        this.editableRowId = rowId;
        const record = this._relatedRecords.find(rec => rec.Id === rowId);
        if (record) {
            this.originalRecordData = { ...record };
        }
    }

    saveRow() {
        this.showSpinner = true;
        const updatedRecords = this._relatedRecords.filter(record => record.Id === this.editableRowId);
        if (updatedRecords) {
            const fields = {
                Id: updatedRecords[0]?.Id,
                Name: updatedRecords[0]?.Name,
                StageName: updatedRecords[0]?.StageName
            };
            console.log("updatedRecords",updatedRecords,fields);
                updateRecord({ fields })
                .then(() => {
                    console.log("Record Updated Successfully");
                    this.editableRowId = null;
                    this.showSpinner = false;
                    this.originalRecordData = {};
                })
                .catch(error => {
                    this.showSpinner = false;
                    this.revertChanges();
                });   
        }
    }
    revertChanges() {
        const record = this._relatedRecords.find(rec => rec.Id === this.editableRowId);
        if (record) Object.assign(record, this.originalRecordData); 
        this.editableRowId = null; 
    }

    cancelEdit() {
        this.revertChanges();
        this.editableRowId = null;
    }
    async showCloneModal(rowId){
        this.showSpinner = true;
        const result = await l4gNewOpportunity.open({
        size: "large",
        description: "Accessible description of modal's purpose",
        objectName: "Opportunity",
        contactId: this.recordId,
        initialInquiry: this.initialInquiry,
        isLightningForGmail: true,
        isCloned : true,
        recordId : rowId
        });
        //this.defaultRecordId = result;
        this.showSpinner = false;
        this.dispatchEvent(new CustomEvent('refreshdata'));
        //return refreshApex(this._wiredMarketData);
    }
}
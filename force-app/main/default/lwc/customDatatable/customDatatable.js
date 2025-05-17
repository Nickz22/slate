import { LightningElement, api, track, wire } from 'lwc';
import STAGENAME from "@salesforce/schema/Opportunity.StageName";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { updateRecord } from 'lightning/uiRecordApi';
import l4gNewOpportunity from "c/l4gNewOpportunity";
import { NavigationMixin } from "lightning/navigation";

export default class CustomDatatable extends NavigationMixin(LightningElement) {
    @api actions = [{ name: 'edit', label: 'Edit' }, { name: 'clone', label: 'Clone' }];
    @api initialInquiry;
    @track editableRowId = null;
    @track stageOptions;
    @track nameSortDirection = 'asc'; // Default sorting direction
    @track stageSortDirection = 'asc'; // Default sorting direction
    @track nameSortIcon = 'utility:arrowup'; // Icon for sorting Name
    @track stageSortIcon = 'utility:arrowup'; // Icon for sorting Stage
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
        const actionName = event.detail.value;
        const rowId = event.currentTarget.dataset.recordId;
        if (actionName === 'edit') {
            this.startEditing(rowId);
        } else if (actionName === 'clone') {
            this.showCloneModal(rowId);
        }else if (actionName === 'quote') {
            this.redirectToPrimaryQuote(rowId);
        }
    }

    redirectToPrimaryQuote(rowId){
        const record = this._relatedRecords.find(rec => rec.Id === rowId);
        if(record){
            this[NavigationMixin.Navigate](
            {
                type: "standard__webPage",
                attributes: {
                url: record.quoteUrl,
                },
            }
            );
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
            updateRecord({ fields })
                .then(() => {
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

    async showCloneModal(rowId) {
        this.showSpinner = true;
        const result = await l4gNewOpportunity.open({
            size: "large",
            description: "Accessible description of modal's purpose",
            objectName: "Opportunity",
            contactId: this.recordId,
            initialInquiry: this.initialInquiry,
            isLightningForGmail: true,
            isCloned: true,
            recordId: rowId
        });
        this.showSpinner = false;
        this.dispatchEvent(new CustomEvent('refreshdata'));
    }

    sortByName() {
        this.nameSortDirection = this.nameSortDirection === 'asc' ? 'desc' : 'asc';
        this.nameSortIcon = this.nameSortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
        this._relatedRecords.sort((a, b) => {
            return this.nameSortDirection === 'asc'
                ? a.Name.localeCompare(b.Name)
                : b.Name.localeCompare(a.Name);
        });
    }

    sortByStage() {
        this.stageSortDirection = this.stageSortDirection === 'asc' ? 'desc' : 'asc';
        this.stageSortIcon = this.stageSortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
        this._relatedRecords.sort((a, b) => {
            return this.stageSortDirection === 'asc'
                ? a.StageName.localeCompare(b.StageName)
                : b.StageName.localeCompare(a.StageName);
        });
    }
}
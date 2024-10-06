import { LightningElement,api,wire,track} from 'lwc';
import getFieldSet from '@salesforce/apex/L4GController.getFieldSet';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";


export default class L4gNewContact extends NavigationMixin(LightningElement) {
    _objectApiName;
    _fieldSetName;
    
    @api recordDetails;
    
    @api
    get objectApiName() {
        return this._objectApiName;
    }    
    set objectApiName(value) {
            this._objectApiName = value;
    }

    @api
    get fieldSetName() {
        return this._fieldSetName;
    }    
    set fieldSetName(value) {
            this._fieldSetName = value;
    }

    @track fieldSetValues = [];

    accountId;
    showSpinner = true;

    @wire(getFieldSet, { fieldSetName:'$fieldSetName' , objectName : '$objectApiName'})
    wiredFieldSet({ error, data }) {
        if (data) {
            this.fieldSetValues = data.map((val)=>{
                return {...val,'value':this.recordDetails[val.fieldName]||''}
            });
            this.showSpinner = false;
        } else if (error) {
            this.showSpinner = false;
            this.showToast('Error', error.body.message, 'error');
        }
    }

    connectedCallback(){
        this.accountId = this.recordDetails?.AccountId;
    }
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }
    handleSuccess(event) {
        this.showSpinner = false;
        this.showToast('Success', 'Record Created successfully', 'success');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                actionName: 'view'
            }
        });

    }

    handleError(event) {
        console.log(JSON.stringify(event.detail));
        this.showToast('Error', event.detail.message, 'error');
    }
    lookupRecord(event){
        this.accountId =  event.detail.selectedRecord;
        console.log('accId',this.accountId);
    }
    handleSubmit(event)
    {
        event.preventDefault();
        this.showSpinner = true;
        let fields = event.detail.fields; 
        console.log('fields',JSON.stringify(fields));
        fields.AccountId = this.accountId;
        fields.Make_This_Contact_Account_Primary__c = true;
        console.log('fields',JSON.stringify(fields));

        this.template.querySelector('lightning-record-edit-form').submit(fields); 
    }
}
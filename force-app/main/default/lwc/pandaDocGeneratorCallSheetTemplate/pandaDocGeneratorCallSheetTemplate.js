import { LightningElement, track, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDocumentList from '@salesforce/apex/PandaDocGeneratorICATemplate.getDocumentList';
import createDocument from '@salesforce/apex/PandaDocGeneratorICATemplate.createCallSheetDocument';
import sendDocument from '@salesforce/apex/PandaDocGeneratorICATemplate.sendDocument';
import getOpportunityName from '@salesforce/apex/PandaDocGeneratorICATemplate.getOpportunityName';

const actions = [
    { label: 'Create & Send', name: 'Create & Send' }
];

const dateFormat = { year: "numeric", month: "long", day: "2-digit", hour: "2-digit", minute: "2-digit"};

export default class PandaDocGeneratorCallSheetTemplate extends LightningElement {
    @track documentList;
    @track error;

    @track showRecipientDetailsScreen = true;
    @track showAllDocumetsScreen = false;

    @track documentName = '';

    documentId;
    @api recordId;

    @track DocumentDetailsColumns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Status', fieldName: 'status' },
        { label: 'Created Date', fieldName: 'date_created', type: 'date', typeAttributes:dateFormat },
        { label: 'Last Modified Date', fieldName: 'date_modified', type: 'date', typeAttributes:dateFormat },
        { label: 'Completed Date', fieldName: 'date_completed', type: 'date', typeAttributes:dateFormat },
        { label: 'Expiration Date', fieldName: 'expiration_date', type: 'date', typeAttributes:dateFormat },
        { label: 'Version', fieldName: 'version', type: 'number' }
    ];
    @track TemplateDetailsColumns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Created Date', fieldName: 'date_created', type: 'date', typeAttributes:dateFormat },
        { label: 'Last Modified Date', fieldName: 'date_modified', type: 'date', typeAttributes:dateFormat },
        { label: 'Version', fieldName: 'version', type: 'number' },
        {
            type: 'action',
            typeAttributes: { rowActions: actions },
        },
    ];

    connectedCallback() {
        this.documentId = null;

        setTimeout(() => {
            this.getOpportunityNameHelper();
        }, 50);
    }

    getOpportunityNameHelper(){
        this.spinnerStatus = true;
        console.log('this.recordId:: ', this.recordId);

        getOpportunityName({recordId: this.recordId})
			.then( (documentName) => {
                console.log('documentName:: ', documentName);
				this.documentName = 'Call Sheet - ' + documentName;
                this.spinnerStatus = false;
			})
			.catch((error) => {
                this.documentList = [];
				if (error) {
                    this.error = 'Something went wrong';
                    if (Array.isArray(error.body)) {
                        this.error = error.body.map(e => e.message).join(', ');
                    } else if (error.body && error.body.message && typeof error.body.message === 'string') {
                        this.error = error.body.message;
                    }
                }
                const event = new ShowToastEvent({
                    title: this.error,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.spinnerStatus = false;
			});
    }

    getDocumentHelper(){
        this.spinnerStatus = true;
        getDocumentList({documentId: this.documentId})
			.then( (pandadocs) => {
                console.log('pandadocs:: ', pandadocs);
				this.documentList = pandadocs.results;
                this.showRecipientDetailsScreen = false;
                this.showAllDocumetsScreen = true;
                this.spinnerStatus = false;
			})
			.catch((error) => {
                this.documentList = [];
				if (error) {
                    this.error = 'Something went wrong';
                    if (Array.isArray(error.body)) {
                        this.error = error.body.map(e => e.message).join(', ');
                    } else if (error.body && error.body.message && typeof error.body.message === 'string') {
                        this.error = error.body.message;
                    }
                }
                const event = new ShowToastEvent({
                    title: this.error,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.spinnerStatus = false;
			});
    }

    CreateAndSendDocumentHelper(event) {
        this.createDocumentHelper(true);
    }

    createDocumentHelper(sendDocument){
        this.spinnerStatus = true;
        createDocument({ recordId: this.recordId})//, documentName : this.documentName
			.then( (result) => {
                if(result){
                    const event = new ShowToastEvent({
                        title: 'Document Created Successfully',
                        variant: 'Success'
                    });
                    this.dispatchEvent(event);
                    this.documentId = result;
                    if(sendDocument){
                        setTimeout(function() {
                            this.sendDocumentHelper(result, true)
                          }.bind(this), 1500);
                    }
                    else{
                        this.spinnerStatus = false;
                    }
                }
                else{
                    const event = new ShowToastEvent({
                        title: 'Something went wrong during Document Creation!',
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                    this.spinnerStatus = false;
                }
			})
			.catch((error) => {
				if (error) {
                    this.error = 'Something went wrong during Document Creation!';
                    if (Array.isArray(error.body)) {
                        this.error = error.body.map(e => e.message).join(', ');
                    } else if (error.body && error.body.message && typeof error.body.message === 'string') {
                        this.error = error.body.message;
                    }
                }
                const event = new ShowToastEvent({
                    title: this.error,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.spinnerStatus = false;
			});
    }

    sendDocumentHelper(docId, showDocumentList){
        this.spinnerStatus = true;
        sendDocument({docId : docId})
			.then( (result) => {
                if(result){
                    const event = new ShowToastEvent({
                        title: 'Document Sent Successfully',
                        variant: 'Success'
                    });
                    this.dispatchEvent(event);
                    if(showDocumentList){
                        this.getDocumentHelper();
                    }
                    else{
                        this.spinnerStatus = false;
                    }
                }
                else{
                    const event = new ShowToastEvent({
                        title: 'Something went wrong!',
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                    this.spinnerStatus = false;
                }
			})
			.catch((error) => {
				if (error) {
                    this.error = 'Something went wrong!';
                    if (Array.isArray(error.body)) {
                        this.error = error.body.map(e => e.message).join(', ');
                    } else if (error.body && error.body.message && typeof error.body.message === 'string') {
                        this.error = error.body.message;
                    }
                }
                const event = new ShowToastEvent({
                    title: this.error,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.spinnerStatus = false;
			});
    }

    inputValueChange(event){
        this.documentName = event.currentTarget.value;
    }
}
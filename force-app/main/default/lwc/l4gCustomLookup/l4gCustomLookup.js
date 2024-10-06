import { LightningElement,api,wire} from 'lwc';
import fetchLookupData from '@salesforce/apex/L4GController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/L4GController.fetchDefaultRecord';
import L4gLightningModal from 'c/l4gLightningModal';

const DELAY = 300;
export default class L4gCustomLookup extends LightningElement {
    @api label = 'custom lookup label';
    @api placeholder = 'search...';
    @api iconName = 'standard:account';
    @api sObjectApiName = 'Account';
    @api defaultRecordId = '';
    // private properties 
    lstResult = [];
    hasRecords = true;
    searchKey = '';
    isSearchLoading = false;
    delayTimeout;
    selectedRecord = {};
    connectedCallback() {
        if (this.defaultRecordId != '') {
            this.fetchRecord();
        }
    }

    @wire(fetchLookupData, { searchKey: '$searchKey', sObjectApiName: '$sObjectApiName' })
    searchResult(value) {
        const { data, error } = value;
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length == 0 ? false : true;
            this.lstResult = JSON.parse(JSON.stringify(data));
        }
        else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
        }
    };

    handleKeyChange(event) {
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, DELAY);
    }
    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }
    handleRemove(event) {
        this.searchKey = '';
        this.selectedRecord = {};
        this.lookupUpdatehandler(undefined); 

        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
        event.preventDefault();
        return false;
    }

    handelSelectedRecord(event) {
        var objId = event.target.getAttribute('data-recid'); 
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); 
        this.lookupUpdatehandler(this.selectedRecord?.Id);
        this.handelSelectRecordHelper();
    }

    handelSelectRecordHelper() {
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');
    }

    lookupUpdatehandler(value) {
        const oEvent = new CustomEvent('lookupupdate',
            {
                'detail': { selectedRecord: value }
            }
        );
        this.dispatchEvent(oEvent);
    }

    async handleCreateNew(){
        const result = await L4gLightningModal.open({
            size: 'large',
            description: 'Accessible description of modal\'s purpose',
            content: 'Passed into content api',
        });
        this.defaultRecordId = result;
        console.log('acc id',result);
        await this.fetchRecord();
        this.lookupUpdatehandler(result);
    }
    fetchRecord(){
        fetchDefaultRecord({ recordId: this.defaultRecordId, 'sObjectApiName': this.sObjectApiName })
            .then((result) => {
                if (result != null) {
                    this.selectedRecord = result;
                    this.handelSelectRecordHelper();
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
            });
    }
}
import { LightningElement,track,api,wire} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getTeamMembers from '@salesforce/apex/cloneAccountTeamMembersHelper.getTeamMembers';
import getAccountName from '@salesforce/apex/cloneAccountTeamMembersHelper.getAccountName';
import getTeamMembersName from '@salesforce/apex/cloneAccountTeamMembersHelper.getTeamMembersName';
import cloneRecords from '@salesforce/apex/cloneAccountTeamMembersHelper.cloneRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Service Type', fieldName: 'Service_Type__c', type: 'text' },
    { label: 'Day Rate', fieldName: 'Day_Rate__c ', type: 'text' }
];

export default class CloneAccountTeamMembers extends LightningElement {
    
    @track isModalOpen = false;
    @track valueCheckBox = [];
    @api recordId;  
    @track teamMembers;
    @track error;
    @track options = [];
    @track teamMembersName = [];
    @track lookupValue;
    @track validform = true;
    @track teamMembersId = [];
    @track selectedItemsSet = new Set(this.selection);

    @track isLoading = false;
    @track Account;
    @track selection;
    @track accTeamList;
    @track AccountName;
    @track columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Service Type', fieldName: 'Service_Type__c'},
        { label: 'Day Rate', fieldName: 'Day_Rate__c'}
    ];
    @wire(getTeamMembers, { AccId: "$recordId" })
        myWiredTeamMembers({ error, data }) {
            if (data) {
               //this.selection = my_ids;
               this.accTeamList = data.accList;
               this.selection = data.selectedIdSet;
               console.log(this.selection);
               console.log(data.selectedIdSet);
               console.log(this.accTeamList);
            } else if (error) {
                this.error = error;
                this.teamMembers = undefined;
            }
    }

    
    items = [
        {
            label: this.Account,
            name: '1',
            expanded: true,
            items: [this.teamMembersName]
        }
    ];

    @api invoke() {  
        console.log('##### Action Called #####');
       
        
    }

    renderedCallback() {
       console.log(this.selection);
    }

    get selectedValues() {
        return this.value.join(',');
    }

    handleChange(e) {
        this.valueCheckBox = e.detail.value;
    }

    rowSelection(evt) {
        let loadedItemsSet = new Set();
        let updatedItemsSet = new Set();

        this.accTeamList.map((event) => {
                loadedItemsSet.add(event.Id);
            });

        if (evt.detail.selectedRows) {
                evt.detail.selectedRows.map((event) => {
                    updatedItemsSet.add(event.Id);
                });
            }

        updatedItemsSet.forEach((id) => {
                    if (!this.selectedItemsSet.has(id)) {
                        this.selectedItemsSet.add(id);
                        this.selection.push(id);
                    }
                });        
                
        loadedItemsSet.forEach((id) => {
                if (this.selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                    // Remove any items that were unselected.
                    this.selectedItemsSet.delete(id);
                    this.selection.pop(id);
                }
            });
                
         
            
       

        // console.log('in');
        // // List of selected items from the data table event.
        // let updatedItemsSet = new Set();
        // // List of selected items we maintain.
       
        // // List of items currently loaded for the current view.
        // let loadedItemsSet = new Set();
    
        
        // this.accTeamList.map((event) => {
        //     loadedItemsSet.add(event.Id);
        // });
    
        // console.log(loadedItemsSet);

        // if (evt.detail.selectedRows) {
        //     evt.detail.selectedRows.map((event) => {
        //         updatedItemsSet.add(event.Id);
        //     });
    
    
        //     // Add any new items to the selection a
        //     updatedItemsSet.forEach((id) => {
        //         if (!this.selectedItemsSet.has(id)) {
        //             this.selectedItemsSet.add(id);
        //             this.selection.push(id);
        //         }
        //     });        
        // }
    
    
        // loadedItemsSet.forEach((id) => {
        //     if (this.selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
        //         // Remove any items that were unselected.
        //         this.selectedItemsSet.delete(id);
        //         this.selection.pop(id);
        //     }
        // });
    
       
        // //this.selection = this.selectedItemsSet;
        // console.log('---selection---'+JSON.stringify(this.selection));
        // console.log(this.selectedItemsSet);
      }

    handleLookupChange(e){
        this.Account = e.detail.value[0];
        this.lookupValue = e.detail.value[0];
    }

    closeModal() {
        
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    

    @track currentStep = '1';
 
    handleOnStepClick(event) {
        this.currentStep = event.target.value;
    }
 
    get isStepOne() {
        return this.currentStep === "1";
    }
 
    get isStepTwo() {
        return this.currentStep === "2";
    }
 
    get isStepThree() {
        return this.currentStep === "3";
    }
 
    get isEnableNext() {
        return this.currentStep != "3";
    }
 
    get isEnablePrev() {
        return this.currentStep != "1";
    }
 
    get isEnableFinish() {
        return this.currentStep === "3";
    }
 
    handleNext(){
        

        if(this.currentStep == "1"){    
            if(this.selectedItemsSet.size == 0){
                this.validform = false;
                const event = new ShowToastEvent({
                    title: 'Warning!',
                    variant : 'warning',
                    message: 'Please select any team member!'
                });
                this.dispatchEvent(event);
            }
            else{
                this.currentStep = "2";
                
                selectedItemsSet.forEach((id) => {
                        this.selection.push(id);
                });   
            }
        }
        else if(this.currentStep = "2"){
            if(this.lookupValue === undefined){
                this.validform = false;
                const event = new ShowToastEvent({
                    title: 'Warning!',
                    variant : 'warning',
                    message: 'Please select an Account!'
                });
                this.dispatchEvent(event);
            }else{
                this.currentStep = "3";
                this.teamMembersName = [];
                getAccountName({AccId : this.Account})
                .then(result => {
                    this.AccountName = result;
                })
                .catch(error => {
                    this.error = error;
                });
                
                this.template.querySelector('[data-accid]').value = this.Account;
                
                getTeamMembersName({Ids : this.selection})
                .then(res => {
                    
                    for(const list of res){
                        const teamM = {
                            label: list,
                            name: list,
                            expanded: false,
                            items: []
                        };
                       
                        this.teamMembersName = [ ...this.teamMembersName, teamM ];
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            }

        
        }
    }
 
    handlePrev(){
        if(this.currentStep == "3"){
            this.currentStep = "2";
            this.template.querySelector('[data-accid]').value = this.Account;
        }
        else if(this.currentStep = "2"){
            this.currentStep = "1";
        }
    }
 
    handleFinish(){
        this.isLoading = true;
        cloneRecords({AccId : this.Account,Ids : this.valueCheckBox},)
        .then(result => {
            const event = new ShowToastEvent({
                title: 'Success!',
                variant : 'success',
                message: 'All team members cloned successfully!'
            });
            this.dispatchEvent(event);
            this.isLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            this.isLoading = false;
            const event = new ShowToastEvent({
                title: 'Error!',
                variant : 'error',
                message: 'The selected team members are already present in the Account: ' + this.AccountName + '.'
            });
            this.dispatchEvent(event);
        });
    }
}
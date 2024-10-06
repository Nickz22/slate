import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getAccountId from '@salesforce/apex/L4GController.getAccountId';
import checkIfContactExists from '@salesforce/apex/L4GController.checkIfContactExists';

export default class L4gPeopleDetails extends NavigationMixin(LightningElement) {

    @api people;
    @track contacts = [];
    @track recordDetails = {};
    emails = [];
    peopleDetails = [];
    showNewContactForm = false;

    connectedCallback() {
        this.fetchContacts();
        this.retrieveContacts();
    }
    fetchContacts() {
        // const jsonData = {
        //     "to": [
        //         {
        //             "name": "sitetracker/strk",
        //             "email": "strk@noreply.github.com",
        //             "full": "sitetracker/strk <strk@noreply.github.com>",
        //             "listType": "to"
        //         }
        //     ],
        //     "cc": [
        //         {
        //             "name": "Nicholas Zozaya",
        //             "email": "nzozaya@sitetracker.com",
        //             "full": "Nicholas Zozaya <nzozaya@sitetracker.com>"
        //         },
        //         {
        //             "name": "Review requested",
        //             "email": "review_requested@noreply.github.com",
        //             "full": "Review requested <review_requested@noreply.github.com>",
        //             "listType": "cc"
        //         }
        //     ],
        //     "bcc": [],
        //     "from": {
        //         "email": "notifications@github.com",
        //         "name": "Sean Glover",
        //         "replyTo": "reply+BCW5Z7YYV742GBRBYJ3MTEGFA3GVBEVBNHHJP3ZNZE@reply.github.com"
        //     }
        // };
        let jsonData = this.people;
        jsonData.to.forEach(contact => {
            this.peopleDetails.push({ ...contact});
            this.emails.push(contact.email);
        });

        jsonData.cc?.forEach(contact => {
            this.peopleDetails.push({ ...contact});
            this.emails.push(contact.email);
        });

        jsonData.bcc?.forEach(contact => {
            this.peopleDetails.push({ ...contact});
            this.emails.push(contact.email);
        });

        this.peopleDetails.push({ ...jsonData.from});
        this.emails.push(...jsonData.from.email);
    }

    async handleAddNew(event) {
        const email = event.target.dataset.email;
        console.log('event.target.dataset',JSON.stringify(event.target.dataset));
        this.recordDetails = this.contacts.find(data => data.email === email); 
        const accId = await getAccountId({domain:this.extractDomain(this.recordDetails.email)});
        const {FirstName, LastName} = this.splitFullName(this.recordDetails.name);
        this.recordDetails.FirstName = FirstName;
        this.recordDetails.LastName = LastName;
        this.recordDetails.Email = this.recordDetails.email;
        this.recordDetails.AccountId = accId;
        this.showNewContactForm = true;
    }

    handleView(event) {
        const contactId = event.target.dataset.targetId;
        console.log(`View clicked for: ${contactId}`);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: contactId,
                actionName: 'view'
            }
        });
    }

    splitFullName(fullName) {
        // Trim the input to remove any leading or trailing whitespace
        const trimmedName = fullName.trim();
    
        // Split the name into parts based on spaces
        const nameParts = trimmedName.split(' ');
    
        // If there's only one part, consider it as the first name
        if (nameParts.length === 1) {
            return {
                FirstName: '',
                LastName: nameParts[0]
            };
        }
    
        // The last part is the last name
        const LastName = nameParts.pop();
        
        // The remaining parts are the first name
        const FirstName = nameParts.join(' ');
    
        return {
            FirstName,
            LastName
        };
    }

    extractDomain(email) {
        const atIndex = email.indexOf('@');
        const dotIndex = email.indexOf('.com');
    
        if (atIndex !== -1 && dotIndex !== -1) {
            return email.slice(atIndex + 1, dotIndex);
        }
        
        return null;
    }
    
    retrieveContacts(){
        checkIfContactExists({emailIds : this.emails}).then(result=>{
            console.log('result',JSON.stringify(result));
            this.contacts = this.peopleDetails.map(ele=>{
                return {...ele, showAddNew:(result[ele.email]?false:true),showView:(result[ele.email]?true:false), Id:result[ele.email]};
            })
            console.log('this.contacts',JSON.stringify(this.contacts));
        });
    }
}
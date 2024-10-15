import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getAccountId from '@salesforce/apex/L4GController.getAccountId';
import checkIfContactExists from '@salesforce/apex/L4GController.checkIfContactExists';

export default class L4gPeopleDetails extends NavigationMixin(LightningElement) {

    @api messageBody;
    @api subject;
    @api
    get people() {
        return this._people;
    }
    set people(value) {
        if (value?.from) {
            this._people = value;
            this.peopleDetails = [];
            this.fetchContacts();
            this.retrieveContacts();
            return;
        }

    }
    get initialInquiry(){
        return `${this.subject}\n${this.messageBody}`;
    }
    @track contacts = [];
    @track recordDetails = {};
    _people;
    emails = [];
    peopleDetails = [];
    showNewContactForm = false;
    selectedContactId;
    showContactDetails = false;

    fetchContacts() {
        let jsonData = this.people;
        jsonData.to?.forEach(contact => {
            if(contact.email && !(contact.email.includes('@slate') || contact.email.includes('@palermo') || contact.email.includes('@align'))){
                this.peopleDetails.push({ ...contact });
                this.emails.push(contact.email);
            }
        });

        jsonData.cc?.forEach(contact => {
            if(contact.email && !(contact.email.includes('@slate') || contact.email.includes('@palermo') || contact.email.includes('@align'))){
                this.peopleDetails.push({ ...contact });
                this.emails.push(contact.email);
            }
        });

        jsonData.bcc?.forEach(contact => {
            if(contact.email && !(contact.email.includes('@slate') || contact.email.includes('@palermo') || contact.email.includes('@align'))){
                this.peopleDetails.push({ ...contact });
                this.emails.push(contact.email);
            }
        });

        if(!(jsonData.from.email.includes('@slate') || jsonData.from.email.includes('@palermo') || jsonData.from.email.includes('@align'))){
            this.peopleDetails.push({ ...jsonData.from });
            this.emails.push(jsonData.from.email);
        }
        
    }

    async handleAddNew(event) {
        const email = event.target.dataset.email;
        this.recordDetails = this.contacts.find(data => data.email === email);
        const accId = await getAccountId({ domain: this.extractDomain(this.recordDetails.email) });
        const { FirstName, LastName } = this.splitFullName(this.recordDetails.name);
        this.recordDetails.FirstName = FirstName;
        this.recordDetails.LastName = LastName;
        this.recordDetails.Email = this.recordDetails.email;
        this.recordDetails.AccountId = accId;
        this.showNewContactForm = true;
    }

    handleView(event) {
        this.selectedContactId = event.target.dataset.targetId;
        this.showContactDetails = true;
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

    retrieveContacts() {
        checkIfContactExists({ emailIds: this.emails }).then(result => {
            let contacts = this.peopleDetails.map(ele => {
                return { ...ele, showAddNew: ((result && result[ele.email]) ? false : true), showView: ((result && result[ele.email]) ? true : false), Id: result ? result[ele.email] : null };
            })
            this.contacts = JSON.parse(JSON.stringify(contacts));
        });
    }
    handleBack(){
        this.peopleDetails = [];
        this.fetchContacts();
        this.retrieveContacts();
        this.showContactDetails = false;
        this.showNewContactForm = false;
        return;
    }
}
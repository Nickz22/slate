import { LightningElement, api } from 'lwc';

export default class CustomContactNew extends LightningElement {
    @api recordId;
    @api messageBody;
    @api subject;
    @api people;

    @api source;

    connectedCallback() {
        console.log('Custom Contact New component loaded');
        console.log('Message Body:', this.messageBody);
        console.log('Subject:', this.subject);
        console.log('People:', this.people);
    }
}
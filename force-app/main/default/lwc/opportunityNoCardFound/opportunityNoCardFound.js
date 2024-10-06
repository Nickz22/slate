import { LightningElement,api,wire } from 'lwc';
import getPaymentCard from '@salesforce/apex/Caymentcardstatus.getPaymentCard';
export default class OpportunityNoCardFound extends LightningElement {
@api recordId;
isCardonAccount = false;
@wire(getPaymentCard, { recordId: "$recordId" })
        getPaymentCard({ error, data }) {
            if (data) {
                this.isCardonAccount = data;
               console.log('======>'+JSON.stringify(data));
            } else if (error) {
                this.error = error;
            }
    }
}
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createOrUpdateInvoice from '@salesforce/apex/CreateUpdateQBInvoiceByUser.CreateUpdateInvoice';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateUpdateInvoiceLwc extends LightningElement {
    @api recordId
    @track spinner = false

    handleSubmit() {
        this.spinner = true
        createOrUpdateInvoice({ recordId: this.recordId })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Your invoice Created/Updated Successfully!',
                    variant: 'success'
                })
            )
            this.spinner = false
            this.dispatchEvent(new CloseActionScreenEvent())
        })
        .catch(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You are not able to perform this operation, Please check with admin.',
                    variant: 'error'
                })
            )
            this.spinner = false
            this.dispatchEvent(new CloseActionScreenEvent())
        })
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent())
    }
}
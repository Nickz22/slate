import { api } from 'lwc';
import LightningModal from 'lightning/modal';
export default class L4gLightningModal extends LightningModal {
    @api content;
    accountId;
    handleSuccess(event) {
        this.accountId = event.detail.id;
        console.log('accountId',this.accountId);
        this.close(this.accountId);
    }
    handleOkay() {
        this.template.querySelector('lightning-record-edit-form').submit();
    } 
}
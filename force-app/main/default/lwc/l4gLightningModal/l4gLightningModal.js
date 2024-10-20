import { api } from "lwc";
import LightningModal from "lightning/modal";

export default class L4gLightningModal extends LightningModal {
  @api content;
  @api objectName;
  @api recordTypeId;
  @api contactId;
  showSpinner = false;
  accountId;

  get header() {
    return `Create ${this.objectName}`;
  }

  get isAccount() {
    return this.objectName.toLowerCase() === "account";
  }

  handleSuccess(event) {
    this.showSpinner = false;
    this.accountId = event.detail.id;
    this.close(this.accountId);
  }
  handleCancel(event) {
    this.showSpinner = false;
    this.close(null);
  }
  handleOkay() {
    if (this.isAccount) {
      this.template.querySelector("c-create-account").submit();
    } else {
      this.template.querySelector("lightning-record-edit-form").submit();
    }
  }
  handleSubmit(event) {
    this.showSpinner = true;
    event.preventDefault();
    let fields = event.detail.fields;
    if (this.objectName == "Opportunity") {
      fields.ContactId = this.contactId;
    }
    this.template.querySelector("lightning-record-form").submit(fields);
  }
  handleError(event) {
    console.error("Error", event?.detail?.detail);
    this.showSpinner = false;
  }
}

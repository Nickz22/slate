import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

export default class CustomContactNew extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  handleSubmit(event) {
    event.preventDefault(); // stop the form from submitting
    const fields = event.detail.fields;
    this.template.querySelector("lightning-record-edit-form").submit(fields);
  }

  handleSuccess(event) {
    const contactId = event.detail.id;
    this.showSuccessToast();
    this.navigateToNewRecord(contactId);
  }

  navigateToNewRecord(recordId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Contact",
        actionName: "view"
      }
    });
  }

  showSuccessToast() {
    const event = new ShowToastEvent({
      title: "Success",
      message: "Contact created successfully",
      variant: "success"
    });
    this.dispatchEvent(event);
  }
}

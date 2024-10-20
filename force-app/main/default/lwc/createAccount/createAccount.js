import { LightningElement, api } from "lwc";
import { createRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import WEBSITE_FIELD from "@salesforce/schema/Account.Website";

export default class CreateAccount extends NavigationMixin(LightningElement) {
  @api recordId;
  @api isLightningForGmail = false;
  name = "";
  website = "";

  handleNameChange(event) {
    this.name = event.target.value;
  }

  handleWebsiteChange(event) {
    this.website = event.target.value;
  }

  @api
  async submit() {
    const fields = {};
    fields[NAME_FIELD.fieldApiName] = this.name;
    fields[WEBSITE_FIELD.fieldApiName] = this.website;

    const recordInput = { apiName: ACCOUNT_OBJECT.objectApiName, fields };

    const account = await createRecord(recordInput).catch((error) => {
      console.error("Error creating account:", error);
      this.showErrorToast(error.body);
      return;
    });
    this.showSuccessToast();
    // Dispatch the custom event for modal use
    this.dispatchEvent(
      new CustomEvent("accountcreated", {
        detail: { id: account.id }
      })
    );
    // Navigate to the new record if we're not in modal
    if (!this.isLightningForGmail) {
      this.navigateToNewRecord(account.id);
    }
  }

  navigateToNewRecord(recordId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Account",
        actionName: "view"
      }
    });
  }

  showSuccessToast() {
    const event = new ShowToastEvent({
      title: "Success",
      message: "Account created successfully",
      variant: "success"
    });
    this.dispatchEvent(event);
  }

  showErrorToast(errorBody) {
    const event = new ShowToastEvent({
      title: "Error creating account",
      message: errorBody?.output?.errors[0]?.message ?? errorBody.message,
      variant: "error",
      mode: "dismissable"
    });
    this.dispatchEvent(event);
  }
}

import { LightningElement, api } from "lwc";
import { createRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import WEBSITE_FIELD from "@salesforce/schema/Account.Website";

export default class CreateAccount extends LightningElement {
  name = "";
  website = "";

  handleNameChange(event) {
    this.name = event.target.value;
  }

  handleWebsiteChange(event) {
    this.website = event.target.value;
  }

  @api submit() {
    const fields = {};
    fields[NAME_FIELD.fieldApiName] = this.name;
    fields[WEBSITE_FIELD.fieldApiName] = this.website;

    const recordInput = { apiName: ACCOUNT_OBJECT.objectApiName, fields };

    createRecord(recordInput)
      .then((account) => {
        // Dispatch the custom event
        this.dispatchEvent(
          new CustomEvent("accountcreated", {
            detail: { id: account.id }
          })
        );
      })
      .catch((error) => {
        console.error("Error creating account:", error);
        this.showErrorToast(error.body);
      });
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

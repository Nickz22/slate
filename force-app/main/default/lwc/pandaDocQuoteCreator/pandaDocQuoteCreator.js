import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createPandaDocQuote from "@salesforce/apex/PandaDocQuoteController.createPandaDocQuote";
import checkDocumentStatus from "@salesforce/apex/PandaDocQuoteController.checkDocumentStatus";
import attachDocumentToOpportunity from "@salesforce/apex/PandaDocQuoteController.attachDocumentToOpportunity";

export default class PandaDocQuoteCreator extends LightningElement {
  @api recordId;
  @track statusMessage = "Generating Quote";
  @track isLoading = true;
  statusUrl;
  documentId;
  pollingInterval;
  dotInterval;

  connectedCallback() {
    this.animateDots();
  }

  disconnectedCallback() {
    clearInterval(this.dotInterval);
  }

  animateDots() {
    let dots = 0;
    this.dotInterval = setInterval(() => {
      dots = (dots + 1) % 4;
      const dotsString = ".".repeat(dots);
      const loadingDots = this.template.querySelector(".loading-dots");
      if (loadingDots) {
        loadingDots.textContent = dotsString;
      }
    }, 200);
  }

  @wire(createPandaDocQuote, { opportunityId: "$recordId" })
  wiredQuoteCreation({ error, data }) {
    if (data) {
      this.handleQuoteCreation(data);
    } else if (error) {
      this.handleError(error);
    }
  }

  handleQuoteCreation(result) {
    this.statusUrl = result.statusUrl;
    this.documentId = result.documentId;
    this.statusMessage =
      "Waiting for the generated Quote to upload to Pandadoc";
    this.startPolling();
  }

  startPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
    }
    this.pollingInterval = setInterval(() => this.checkDocumentStatus(), 2000);
  }

  async checkDocumentStatus() {
    const result = await checkDocumentStatus({
      statusUrl: this.statusUrl
    }).catch((error) => {
      clearInterval(this.pollingInterval);
      this.handleError(error);
    });

    if (result && result.status === "document.draft") {
      clearInterval(this.pollingInterval);
      this.showPreview(result.id);
    }
  }

  async showPreview(documentId) {
    const previewUrl = `https://app.pandadoc.com/a/#/documents/${documentId}`;
    window.open(previewUrl, "_blank");

    await attachDocumentToOpportunity({
      opportunityId: this.recordId,
      documentId: documentId,
      documentName: `PandaDoc Quote - ${this.recordId}`
    }).catch((error) => {
      this.handleError(error);
      return;
    });
    this.statusMessage =
      "A copy of the Quote has been attached to the Opportunity, you may close this screen";
    this.isLoading = false;
    clearInterval(this.dotInterval);
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error) {
    this.isLoading = false;
    clearInterval(this.dotInterval);
    this.statusMessage = "An error occurred. Please try again.";
    this.showToast(
      "Error",
      error.body?.message || error.message || "Unknown error",
      "error"
    );
  }
}

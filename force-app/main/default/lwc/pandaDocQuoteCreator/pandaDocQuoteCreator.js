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
  maxPollingAttempts = 30; // Maximum number of polling attempts (60 seconds total)
  pollingAttempts = 0;
  quoteType = "";

  connectedCallback() {
    this.animateDots();
    this.setQuoteType();
  }

  disconnectedCallback() {
    clearInterval(this.dotInterval);
  }

  // a hack to discern which action launched this component so that I can pass the correct quote type to the Apex method
  setQuoteType() {
    const actionName =
      window.location.href.match(/\/quick\/([^?]+)/)?.[1] || "";

    if (actionName.includes("Generate_Quote")) {
      this.quoteType = "Estimate";
    } else if (actionName.includes("Generate_Invoice")) {
      this.quoteType = "Invoice";
    } else if (actionName.includes("Generate_Proposal")) {
      this.quoteType = "Proposal";
    } else {
      console.error("Unknown action name:", actionName);
      this.quoteType = "Unknown";
    }
  }

  get shouldFireWire() {
    return !!this.recordId && this.quoteType !== "Unknown";
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

  @wire(createPandaDocQuote, {
    opportunityId: "$recordId",
    quoteType: "$quoteType"
  })
  wiredQuoteCreation({ error, data }) {
    if (this.shouldFireWire) {
      if (data) {
        this.handleQuoteCreation(data);
      } else if (error) {
        this.handleError(error);
      }
    }
  }

  get timestamp() {
    return Date.now();
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
    this.pollingAttempts = 0;
    this.pollingInterval = setInterval(() => this.checkDocumentStatus(), 2000);
  }

  async checkDocumentStatus() {
    this.pollingAttempts++;
    if (this.pollingAttempts > this.maxPollingAttempts) {
      clearInterval(this.pollingInterval);
      this.handleError(
        new Error("Quote generation timed out. Please try again.")
      );
      return;
    }

    try {
      const result = await checkDocumentStatus({
        statusUrl: this.statusUrl
      });

      if (result && result.status === "document.draft") {
        clearInterval(this.pollingInterval);
        this.statusMessage = "Quote generated successfully, attaching to Opportunity";
        const attachResult = await this.attachDocumentToOpportunity(result.id);
        if (attachResult === 200) {
          this.statusMessage = "Success! Opening Quote in PandaDoc.";
          this.isLoading = false;
          setTimeout(() => this.showPreview(result.id), 1250);
        }
      } else if (result && result.status === "error") {
        clearInterval(this.pollingInterval);
        throw new Error("An error occurred while generating the quote.");
      }
    } catch (error) {
      clearInterval(this.pollingInterval);
      this.handleError(error);
    }
  }

  async attachDocumentToOpportunity(documentId) {
    try {
      await attachDocumentToOpportunity({
        opportunityId: this.recordId,
        documentId: documentId,
        documentName: `PandaDoc Quote - ${this.recordId}`,
        quoteType: this.quoteType
      });
      return 200;
    } catch (error) {
      this.handleError(error);
      return 500;
    }
  }

  async showPreview(documentId) {
    const previewUrl = `https://app.pandadoc.com/a/#/documents/${documentId}`;
    window.open(previewUrl, "_blank");
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error) {
    this.isLoading = false;
    clearInterval(this.dotInterval);
    clearInterval(this.pollingInterval);
    this.statusMessage = "An error occurred. Please try again.";
    this.showToast(
      "Error",
      error.body?.message || error.message || "Unknown error",
      "error"
    );
  }
}

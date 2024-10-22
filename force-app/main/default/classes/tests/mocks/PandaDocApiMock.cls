@isTest
global class PandaDocApiMock implements HttpCalloutMock {
  private Integer statusCode;
  private String status;
  private String body;
  public Map<String, Object> lastRequestBody;

  global PandaDocApiMock(Integer statusCode, String status, String body) {
    this.statusCode = statusCode;
    this.status = status;
    this.body = body;
  }

  global HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setStatusCode(this.statusCode);
    res.setStatus(this.status);

    // Set the appropriate Content-Type header based on the request
    if (req.getEndpoint().endsWith('/download')) {
      res.setHeader('Content-Type', 'application/pdf');
      res.setBodyAsBlob(EncodingUtil.base64Decode(this.body));
    } else {
      res.setHeader('Content-Type', 'application/json');
      res.setBody(this.body);
    }

    // Only try to deserialize if it's a POST request (document creation)
    if (req.getMethod() == 'POST') {
      this.lastRequestBody = (Map<String, Object>) JSON.deserializeUntyped(
        req.getBody()
      );
    }

    return res;
  }

  public static PandaDocApiMock createSuccessMock() {
    String successBody = JSON.serialize(
      new Map<String, Object>{
        'id' => 'mock-document-id',
        'name' => 'Mock Document',
        'status' => 'document.draft',
        'date_created' => DateTime.now()
          .format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''),
        'links' => new List<Map<String, String>>{
          new Map<String, String>{
            'rel' => 'status',
            'href' => 'https://api.pandadoc.com/public/v1/documents/mock-document-id'
          }
        }
      }
    );
    return new PandaDocApiMock(201, 'Created', successBody);
  }

  public static PandaDocApiMock createErrorMock() {
    String errorBody = JSON.serialize(
      new Map<String, Object>{
        'type' => 'validation_error',
        'message' => 'Mock validation error',
        'errors' => new List<String>{
          'Field X is required',
          'Field Y is invalid'
        }
      }
    );
    return new PandaDocApiMock(400, 'Bad Request', errorBody);
  }

  public static PandaDocApiMock createDocumentContentMock() {
    String mockPdfContent = 'Mock PDF Content';
    Blob mockBlob = Blob.valueOf(mockPdfContent);

    // Return the mock content directly as a Blob, mimicking the real API response
    return new PandaDocApiMock(200, 'OK', EncodingUtil.base64Encode(mockBlob));
  }

  public static PandaDocApiMock createDocumentStatusMock() {
    String statusBody = JSON.serialize(
      new Map<String, Object>{
        'status' => 'document.completed',
        'id' => 'mock-document-id',
        'name' => 'Mock Completed Document'
      }
    );
    return new PandaDocApiMock(200, 'OK', statusBody);
  }
}

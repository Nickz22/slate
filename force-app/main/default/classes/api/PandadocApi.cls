public with sharing class PandadocApi {
  private static final String API_KEY = '89384b2c4a6656a6457776748557bde540ed2a71';
  private static final String ENDPOINT = 'https://api.pandadoc.com/public/v1/documents';

  public class PandaDocException extends Exception {
  }

  public static Map<String, String> createDocument(
    Map<String, Object> requestBody
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(ENDPOINT);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'API-Key ' + API_KEY);
    req.setBody(JSON.serialize(requestBody));

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 201) {
      return parseSuccessResponse(res.getBody());
    } else {
      throw new PandaDocException(constructErrorMessage(res, requestBody));
    }
  }

  public static Map<String, String> checkDocumentStatus(String statusUrl) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(statusUrl);
    req.setMethod('GET');
    req.setHeader('Authorization', 'API-Key ' + API_KEY);

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      return new Map<String, String>{
        'status' => (String) responseBody.get('status'),
        'id' => (String) responseBody.get('id'),
        'name' => (String) responseBody.get('name')
      };
    } else {
      throw new PandaDocException(
        'Failed to check document status. Status: ' + res.getStatus()
      );
    }
  }

  private static Map<String, String> parseSuccessResponse(String responseBody) {
    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
      responseBody
    );
    String statusUrl = '';
    for (Object linkObj : (List<Object>) responseMap.get('links')) {
      Map<String, Object> link = (Map<String, Object>) linkObj;
      if (link.get('rel') == 'status') {
        statusUrl = (String) link.get('href');
        break;
      }
    }

    return new Map<String, String>{
      'documentId' => (String) responseMap.get('id'),
      'documentName' => (String) responseMap.get('name'),
      'documentStatus' => (String) responseMap.get('status'),
      'dateCreated' => (String) responseMap.get('date_created'),
      'statusUrl' => statusUrl,
      'infoMessage' => (String) responseMap.get('info_message')
    };
  }

  private static String constructErrorMessage(
    HttpResponse res,
    Map<String, Object> requestBody
  ) {
    String errorMessage =
      'Failed to create PandaDoc quote. Status: ' + res.getStatus();
    errorMessage += '\nStatus Code: ' + res.getStatusCode();
    errorMessage += '\nResponse Body: ' + res.getBody();

    try {
      Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      if (errorResponse.containsKey('errors')) {
        errorMessage +=
          '\nErrors: ' + JSON.serialize(errorResponse.get('errors'));
      }
    } catch (Exception e) {
      errorMessage += '\nError parsing response body: ' + e.getMessage();
    }

    return errorMessage;
  }

  public static Blob getDocumentContent(String documentId) {
    String endpoint =
      'https://api.pandadoc.com/public/v1/documents/' +
      documentId +
      '/download';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'API-Key ' + API_KEY);

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      return res.getBodyAsBlob();
    } else {
      throw new PandaDocException(
        'Error fetching document content: ' + res.getStatus()
      );
    }
  }
}

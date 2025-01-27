public with sharing class PandadocApi {
  private static final String SLATE_PRODUCTION_API_KEY = '14546b655c1076dd61665887c9ebe5dfb702254c';
  private static final String ALIGN_PRODUCTION_API_KEY = 'cbc4206ec4ce701c6ce9baa33dfc36022d3d33e1';
  private static final String PALERMO_PRODUCTION_API_KEY = '6918cc61962a1d26c7fb78eaac2339c054d6a090';
  private static final String ENDPOINT = 'https://api.pandadoc.com/public/v1/documents';

  public static final String SLATE_ORG_TYPE = 'slate';
  public static final String ALIGN_ORG_TYPE = 'align';
  public static final String PALERMO_ORG_TYPE = 'palermo';

  public class PandaDocException extends Exception {
  }

  private static String getApiKey(String orgType) {
    if (orgType == SLATE_ORG_TYPE) {
      return SLATE_PRODUCTION_API_KEY;
    } else if (orgType == ALIGN_ORG_TYPE) {
      return ALIGN_PRODUCTION_API_KEY;
    } else if (orgType == PALERMO_ORG_TYPE) {
      return PALERMO_PRODUCTION_API_KEY;
    }
    return null;
  }

  public static Map<String, String> createDocument(
    Map<String, Object> requestBody,
    String orgType
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(ENDPOINT);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'API-Key ' + getApiKey(orgType));
    req.setBody(JSON.serialize(requestBody));

    Http http = new Http();
    HttpResponse res = http.send(req);
    if (res.getStatusCode() == 201) {
      return parseSuccessResponse(res.getBody(), orgType);
    } else {
      throw new PandaDocException(constructErrorMessage(res));
    }
  }

  public static Map<String, String> checkDocumentStatus(
    String statusUrl,
    String orgType
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(statusUrl);
    req.setMethod('GET');
    req.setHeader('Authorization', 'API-Key ' + getApiKey(orgType));

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

  private static Map<String, String> parseSuccessResponse(
    String responseBody,
    String orgType
  ) {
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

  @TestVisible
  private static String constructErrorMessage(HttpResponse res) {
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

  public static Blob getDocumentContent(String documentId, String orgType) {
    String endpoint =
      'https://api.pandadoc.com/public/v1/documents/' +
      documentId +
      '/download';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'API-Key ' + getApiKey(orgType));
    req.setTimeout(120000);

    Http http = new Http();
    HttpResponse res = http.send(req);
    System.debug('res.getBody(): ' + JSON.serialize(res.getBody()));
    if (res.getStatusCode() == 200) {
      return res.getBodyAsBlob();
    } else {
      throw new PandaDocException(
        'Error fetching document content: ' + res.getStatus()
      );
    }
  }
}

@IsTest
public class PandaDocDocumentChangeTest {
  @IsTest
  static void testParse() {
    // Prepare test JSON
    String testJson = '{"event":"document_state_changed","data":{"id":"abc123","name":"Test Document","status":"document.completed","metadata":{"salesforce_opportunity_id":"006XXXXXXXXXXXXXXX","folder":"Test Folder"},"recipients":[{"id":"rec1","first_name":"John","last_name":"Doe","email":"john@example.com","recipient_type":"signer","has_completed":true,"roles":["Signer"]}],"sent_by":{"id":"user1","email":"sender@example.com","first_name":"Jane","last_name":"Smith"},"grand_total":{"amount":"1000.00"},"template":{"id":"temp1","name":"Test Template"}}}';

    // Act
    Test.startTest();
    PandaDocDocumentChange result = PandaDocDocumentChange.parse(testJson);
    Test.stopTest();

    // Assert
    Assert.isNotNull(result, 'Parsed result should not be null');
    Assert.areEqual(
      'document_state_changed',
      result.event,
      'Event should match'
    );

    // Assert DocumentData
    Assert.isNotNull(result.data, 'DocumentData should not be null');
    Assert.areEqual('abc123', result.data.id, 'Document ID should match');
    Assert.areEqual(
      'Test Document',
      result.data.name,
      'Document name should match'
    );
    Assert.areEqual(
      'document.completed',
      result.data.status,
      'Document status should match'
    );

    // Assert Metadata
    Assert.isNotNull(result.data.metadata, 'Metadata should not be null');
    Assert.areEqual(
      '006XXXXXXXXXXXXXXX',
      result.data.metadata.salesforce_opportunity_id,
      'Opportunity ID should match'
    );
    Assert.areEqual(
      'Test Folder',
      result.data.metadata.folder,
      'Folder should match'
    );

    // Assert Recipients
    Assert.isNotNull(result.data.recipients, 'Recipients should not be null');
    Assert.areEqual(
      1,
      result.data.recipients.size(),
      'Should have one recipient'
    );
    Assert.areEqual(
      'John',
      result.data.recipients[0].first_name,
      'Recipient first name should match'
    );
    Assert.areEqual(
      'Doe',
      result.data.recipients[0].last_name,
      'Recipient last name should match'
    );
    Assert.areEqual(
      'john@example.com',
      result.data.recipients[0].email,
      'Recipient email should match'
    );
    Assert.isTrue(
      result.data.recipients[0].has_completed,
      'Recipient should have completed'
    );
    Assert.areEqual(
      1,
      result.data.recipients[0].roles.size(),
      'Recipient should have one role'
    );
    Assert.areEqual(
      'Signer',
      result.data.recipients[0].roles[0],
      'Recipient role should be Signer'
    );

    // Assert Sent By
    Assert.isNotNull(result.data.sent_by, 'Sent By should not be null');
    Assert.areEqual(
      'sender@example.com',
      result.data.sent_by.email,
      'Sender email should match'
    );

    // Assert Grand Total
    Assert.isNotNull(result.data.grand_total, 'Grand Total should not be null');
    Assert.areEqual(
      '1000.00',
      result.data.grand_total.amount,
      'Grand Total amount should match'
    );

    // Assert Template
    Assert.isNotNull(result.data.template, 'Template should not be null');
    Assert.areEqual(
      'temp1',
      result.data.template.id,
      'Template ID should match'
    );
    Assert.areEqual(
      'Test Template',
      result.data.template.name,
      'Template name should match'
    );
  }
}

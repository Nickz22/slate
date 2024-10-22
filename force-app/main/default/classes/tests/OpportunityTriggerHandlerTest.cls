@isTest
public with sharing class OpportunityTriggerHandlerTest {
  @isTest
  static void testSetOppName() {
    // Get the current date in YYMMDD format
    String currentDate = System.now().format('YYMMdd');

    // Test case 1: Brand Content
    String result1 = OpportunityTriggerHandler.setOppName(
      'Brand Content',
      'Acme Corp'
    );
    Assert.isTrue(
      result1.startsWith(currentDate + '_ACMECORP_BC'),
      'Brand Content test failed'
    );

    // Test case 2: Studio Rental
    String result2 = OpportunityTriggerHandler.setOppName(
      'Studio Rental',
      'Wayne Enterprises'
    );
    Assert.isTrue(
      result2.startsWith(currentDate + '_WAYNEENTERPRISES_SR'),
      'Studio Rental test failed'
    );

    // Test case 3: Motion
    String result3 = OpportunityTriggerHandler.setOppName(
      'Motion',
      'Stark Industries'
    );
    Assert.isTrue(
      result3.startsWith(currentDate + '_STARKINDUSTRIES_MT'),
      'Motion test failed'
    );

    // Test case 4: Retouching
    String result4 = OpportunityTriggerHandler.setOppName(
      'Retouching',
      'Daily Planet'
    );
    Assert.isTrue(
      result4.startsWith(currentDate + '_DAILYPLANET_RT'),
      'Retouching test failed'
    );

    // Test case 5: Casablanca - Motion Production
    String result5 = OpportunityTriggerHandler.setOppName(
      'Casablanca - Motion Production',
      'Oscorp'
    );
    Assert.isTrue(
      result5.startsWith(currentDate + '_OSCORP_CMP'),
      'Casablanca - Motion Production test failed'
    );

    // Test case 6: Palermo - Digital/UX
    String result6 = OpportunityTriggerHandler.setOppName(
      'Palermo - Digital/UX',
      'Umbrella Corp'
    );
    Assert.isTrue(
      result6.startsWith(currentDate + '_UMBRELLACORP_UX'),
      'Palermo - Digital/UX test failed'
    );

    // Test case 7: Align - CGI
    String result7 = OpportunityTriggerHandler.setOppName(
      'Align - CGI',
      'Cyberdyne Systems'
    );
    Assert.isTrue(
      result7.startsWith(currentDate + '_CYBERDYNESYSTEMS_CG'),
      'Align - CGI test failed'
    );

    // Test case 8: Default case (should return EC)
    String result8 = OpportunityTriggerHandler.setOppName(
      'Some Random Type',
      'Acme Corp'
    );
    Assert.isTrue(
      result8.startsWith(currentDate + '_ACMECORP_EC'),
      'Default case test failed'
    );
  }
}

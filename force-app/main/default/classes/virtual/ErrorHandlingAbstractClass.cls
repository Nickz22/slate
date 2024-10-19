public abstract class ErrorHandlingAbstractClass {
  protected abstract void executeWithErrorHandling();

  public void execute() {
    try {
      executeWithErrorHandling();
    } catch (Exception e) {
      try {
        sendErrorEmail(e);
      } catch (Exception emailEx) {
        throw new ErrorHandlingException(
          'Failed to send error email: ' +
            emailEx.getMessage() +
            ' while trying to send error email about: ' +
            e.getMessage()
        );
      }
    }
  }

  private void sendErrorEmail(Exception e) {
    List<User> admins = [
      SELECT Email
      FROM User
      WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
    ];
    List<String> toAddresses = new List<String>();
    for (User admin : admins) {
      toAddresses.add(admin.Email);
    }

    if (toAddresses.isEmpty()) {
      System.debug(
        'No active System Administrators found to send error email.'
      );
      return;
    }

    String subject = 'Error in ' + getClassName() + ': ' + e.getMessage();
    String body =
      'Error details:\n\n' +
      'Class: ' +
      getClassName() +
      '\n' +
      'Type: ' +
      e.getTypeName() +
      '\n' +
      'Message: ' +
      e.getMessage() +
      '\n' +
      'Line number: ' +
      e.getLineNumber() +
      '\n' +
      'Stack trace: ' +
      e.getStackTraceString();

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(toAddresses);
    mail.setSubject(subject);
    mail.setPlainTextBody(body);

    try {
      List<Messaging.SendEmailResult> results = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ mail }
      );
      for (Messaging.SendEmailResult result : results) {
        if (result.isSuccess()) {
          System.debug('Email sent successfully');
        } else {
          for (Messaging.SendEmailError error : result.getErrors()) {
            throw new ErrorHandlingException(
              'Error sending email. Error code: ' +
                error.getStatusCode() +
                ', Message: ' +
                error.getMessage()
            );
          }
        }
      }
    } catch (Exception emailEx) {
      throw new ErrorHandlingException(
        'Failed to send error email: ' + emailEx.getMessage()
      );
    }
  }

  // Get the name of the class that's actually using this abstract class
  private String getClassName() {
    return String.valueOf(this).split(':')[0];
  }

  public class ErrorHandlingException extends Exception {
  }
}

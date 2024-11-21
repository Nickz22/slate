/**
 * @description Wrapper for a PandaDoc quote recipient
 * @author Team A
 * @date 2024-02-20
 */
public class PandadocQuoteRecipient {
  public String email;
  public String first_name;
  public String last_name;
  public String role;
  public String recipient_type;

  public PandadocQuoteRecipient(String email, String firstName, String lastName, String role) {
      this.email = email;
      this.first_name = firstName;
      this.last_name = lastName;
      this.role = role;
  }

  public PandadocQuoteRecipient(String email, String firstName, String lastName, String role, String recipientType) {
      this.email = email;
      this.first_name = firstName;
      this.last_name = lastName;
      this.role = role;
      this.recipient_type = recipientType;
  }
}
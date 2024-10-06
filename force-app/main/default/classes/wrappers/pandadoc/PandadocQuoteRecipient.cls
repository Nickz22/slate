/**
 * @description Wrapper for a PandaDoc quote recipient
 * @author Team A
 * @date 2024-02-20
 */
public with sharing class PandadocQuoteRecipient {
  public String email;
  public String firstName;
  public String lastName;
  public String role;

  public PandadocQuoteRecipient(
    String email,
    String firstName,
    String lastName,
    String role
  ) {
    this.email = email;
    this.firstName = firstName;
    this.lastName = lastName;
    this.role = role;
  }
}

//////////////////////////////////////////////////
//Code by: Smeet Pari
//Description: Used in round-robin email service to read incoming email responses to availability emails that were sent to account team members
//Test Class: RoundRobinTest
/////////////////////////////////////////////////
@isTest // deprecated
global class TeamRoundRobinHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email,
        Messaging.InboundEnvelope envelope
    ) {
        return null;
    }
}

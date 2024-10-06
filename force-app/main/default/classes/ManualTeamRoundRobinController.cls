//////////////////////////////////////////////////
//Code by: Smeet Pari
//Description: Send out w/ attachments, availibility emails to account team members matching quote line item products. Also handles sending to next member if any member declines.
//Test Class: RoundRobinTest
/////////////////////////////////////////////////

public class ManualTeamRoundRobinController {
    
    @InvocableMethod(label='Start Manual Round-Robin' description='Starts sending availability emails to Account team members based on quote line items.')
    public static void startManualRoundRobin(List<manualRoundRobinRequest> requests)
    {
        for (manualRoundRobinRequest request : requests) {
            List<Id> accountTeamIdList = new List<Id>();
            accountTeamIdList = request.accountTeamIds.split(';');
            executeRoundRobin(request.quoteId, accountTeamIdList);
        }
    }
    
    private static void executeRoundRobin(Id quoteId, List<Id> accountTeamIds)
    {
        TeamRoundRobinController.preselectedTeam = accountTeamIds;
        TeamRoundRobinController.startRoundRobin(new List<Id>{quoteId});
    }
    
    public class manualRoundRobinRequest {
        @InvocableVariable(required=true)
        public ID quoteId;
        
        @InvocableVariable(required=true)
        public String accountTeamIds;
    }
}
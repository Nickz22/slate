List<AccountShare> accShares = [
  SELECT Id
  FROM AccountShare
  WHERE UserOrGroupId = '005PD000001OpIX'
];
List<OpportunityShare> oppShares = [
  SELECT Id
  FROM OpportunityShare
  WHERE UserOrGroupId = '005PD000001OpIX'
];

database.delete(accShares,false);
database.delete(oppShares,false);

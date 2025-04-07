//Add default admin user to the chat queue and grant chat access and adds default role for community user creation
User usr = [SELECT Id FROM User WHERE Name = 'User User'];
usr.UserPermissionsLiveAgentUser = true;
usr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'NKS' LIMIT 1]?.Id;
usr.CRM_NAV_Ident__c = 'Z999999'; //Setting default nav ident for the scratch user
update usr;

Group scratchQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Scratch_Chat_Queue'];
try{
    insert new GroupMember(UserOrGroupId = usr.Id, GroupId = scratchQueue.Id);
}
catch(Exception ex) {
    //Probably failed due to rerun of script
}

//Create community user
Account personAccount = [SELECT FirstName, LastName, PersonContactId FROM Account WHERE INT_PersonIdent__c = '12345678901'];
//Create user
Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Scratch Community Profile' Limit 1];
String userName  = personAccount.FirstName + '.' +personAccount.LastName + '@' + URL.getOrgDomainUrl().getHost();
User user1 = new User(
    UserName = userName,
    FirstName = personAccount.FirstName,
    LastName = personAccount.LastName,
    Alias = 'test123',
    email = userName,
    ContactId = personAccount.PersonContactId,
    ProfileId = portalProfile.Id,
    EmailEncodingKey = 'UTF-8',
    CommunityNickname = 'test12345',
    TimeZoneSidKey = 'America/Los_Angeles',
    LocaleSidKey = 'en_US',
    LanguageLocaleKey = 'en_US'
);
Database.insert(user1);

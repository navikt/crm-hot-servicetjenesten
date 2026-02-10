//Dummy data script for creating community user and associated dummy data
Contact personContact = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Account.CRM_Person__r.Name = '12345678901' LIMIT 1];


Case accCase = [SELECT Id, AccountId FROM Case WHERE Subject = 'TEST SUBJECT' LIMIT 1];
accCase.AccountId = personContact.AccountId;
update accCase;

//Create a dummy thread
Thread__c thread = new Thread__c();
thread.CRM_Account__c = personContact.AccountId;
thread.CRM_Contact__c = personContact.Id;
thread.CRM_isActive__c = true;
thread.CRM_Related_Object__c = accCase.Id;
insert thread;

Message__c message = new Message__c(CRM_Thread__c = thread.Id,
                    CRM_From_Contact__c = personContact.Id,
                    CRM_Message_Text__c = 'Dette er en testmelding :)',
                    CRM_Read_Datetime__c = Datetime.now(),
                    CRM_Sent_Date__c = Datetime.now().addDays(-1));

insert message;

// Merging person acccount with person
Account personAcc2 = [SELECT Id, FirstName, LastName, CRM_Person__c  FROM Account WHERE INT_PersonIdent__c = '25839399971' LIMIT 1];

Person__c person2 = [SELECT Id FROM Person__c WHERE Name = '12345678902' LIMIT 1];
personAcc2.CRM_Person__c = person2.Id;
update personAcc2;

// Update case to be related to the merged person account
Case accCase2 = [SELECT Id, AccountId FROM Case WHERE Subject = 'TEST AAP' LIMIT 1];
accCase2.AccountId = personAcc2.Id;
update accCase2;
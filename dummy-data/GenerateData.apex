//Dummy data script for creating community user and associated dummy data
Contact personContact = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Account.CRM_Person__r.Name = '12345678901' LIMIT 1];


Case accCase = [SELECT Id, AccountId FROM Case LIMIT 1];
accCase.AccountId = personContact.AccountId;

//Create a dummy thread
Thread__c thread = new Thread__c();
thread.CRM_Account__c = personContact.AccountId;
Thread.CRM_Contact__c = personContact.Id;
thread.CRM_isActive__c = true;
thread.CRM_Related_Object__c = accCase.Id;
insert thread;

Message__c message = new Message__c(CRM_Thread__c = thread.Id,
                    CRM_From_Contact__c = personContact.Id,
                    CRM_Message_Text__c = 'Dette er en testmelding :)',
                    CRM_Read_Datetime__c = Datetime.now(),
                    CRM_Sent_Date__c = Datetime.now().addDays(-1));

insert message;

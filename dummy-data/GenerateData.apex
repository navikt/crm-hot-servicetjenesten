//Dummy data script for STO case and thread, to be able to test the integration with STO
Contact personContact = [SELECT Id, AccountId FROM Contact WHERE Account.CRM_Person__r.Name = '12345678901' LIMIT 1];

RecordType recordTypeSTO = [SELECT Id FROM RecordType WHERE DeveloperName = 'STO_Case' LIMIT 1];

Case accCase = [SELECT Id, AccountId FROM Case WHERE Subject = 'TEST SUBJECT' LIMIT 1];
accCase.AccountId = personContact.AccountId;
accCase.RecordTypeId = recordTypeSTO.Id;
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
                    CRM_Message_Text__c = 'Hei, jeg vil søke om hjelpemiddel :)',
                    CRM_Read_Datetime__c = Datetime.now(),
                    CRM_Sent_Date__c = Datetime.now().addDays(-1));

insert message;

// Update thread with reference to case and api reference to be able to link it to the case and have it show in STO
Thread__c threadSTO = [SELECT Id, CRM_Case__c, CRM_API_Reference__c, CRM_Henvendelse_BehandlingsId__c FROM Thread__c WHERE Id  = :thread.Id];
threadSTO.CRM_Case__c = accCase.Id;
threadSTO.CRM_Henvendelse_BehandlingsId__c = threadSTO.CRM_API_Reference__c;
update threadSTO;

// Update case with reference to thread to give access to STO messages
Case caseStoToUpdate = [SELECT Id, NKS_Henvendelse_BehandlingsId__c FROM Case WHERE Id = :accCase.Id];
caseStoToUpdate.NKS_Henvendelse_BehandlingsId__c = threadSTO.CRM_Henvendelse_BehandlingsId__c;
update caseStoToUpdate;

// Dummy date for conversation notes 
// Merging person acccount with person
Account personAcc2 = [SELECT Id, CRM_Person__c  FROM Account WHERE INT_PersonIdent__c = '25839399971' LIMIT 1];

Person__c person2 = [SELECT Id FROM Person__c WHERE Name = '12345678902' LIMIT 1];
personAcc2.CRM_Person__c = person2.Id;
update personAcc2;

// Update case to be related to the merged person account
Case accCase2 = [SELECT Id, AccountId FROM Case WHERE Subject = 'TEST AAP' LIMIT 1];
accCase2.AccountId = personAcc2.Id;
update accCase2;

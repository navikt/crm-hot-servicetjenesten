Account account1 = new Account();
account1.name = 'Jedi Order';
account1.INT_OrganizationNumber__c = '101010101';
insert account1;

Account account2 = new Account();
account2.name = 'The Empire';
account2.INT_OrganizationNumber__c = '202020202';
insert account2;

Account account3 = new Account();
account3.name = 'The Trade Federation';
account3.INT_OrganizationNumber__c = '303030303';
insert account3;

Account account4 = new Account();
account4.name = 'The Rebels';
account4.INT_OrganizationNumber__c = '404040404';
insert account4;

Account personAccount1 = new Account();
personAccount1.FirstName = 'JarJar';
personAccount1.LastName = 'Binks';
personAccount1.INT_PersonIdent__c = '01010101010';
personAccount1.INT_KrrMobilePhone__c = '00807060';
insert personAccount1;

Account personAccount2 = new Account();
personAccount2.FirstName = 'Darth';
personAccount2.LastName = 'Vader';
personAccount2.INT_PersonIdent__c = '02020202020';
personAccount2.INT_KrrMobilePhone__c = '00203040';
insert personAccount2;

Account personAccount3 = new Account();
personAccount3.FirstName = 'Luke';
personAccount3.LastName = 'Skywalker';
personAccount3.INT_PersonIdent__c = '03030303030';
personAccount3.INT_KrrMobilePhone__c = '87654321';
insert personAccount3;

Account personAccount4 = new Account();
personAccount4.FirstName = 'Han';
personAccount4.LastName = 'Solo';
personAccount4.INT_PersonIdent__c = '04040404040';
personAccount4.INT_KrrMobilePhone__c = '12345678';
insert personAccount4;


List<Account> allAccounts = [SELECT Name, LastName, FirstName, INT_PersonIdent__c FROM Account WHERE INT_PersonIdent__c != '' LIMIT 10];

Person__c person1 = new Person__c();
person1.Name = allAccounts[0].INT_PersonIdent__c;
person1.INT_Confidential__c = 'UGRADERT';
person1.INT_KrrEmail__c = 'fakeemail@navtest11.no';
person1.INT_BankAccountNumber__c = '10102040100';
person1.INT_ResidentialAddress__c = 'stedveien 12';
person1.INT_ResidentialZipCode__c = '0101';
//person1.INT_ResidentialPlace__c = 'Oslo';
person1.INT_KrrMobilePhone__c = '09010202';
person1.INT_LastUpdatedFromKRR__c = Datetime.now();
person1.INT_KrrIntegrationStatus__c = 'Completed';
person1.INT_LastName__c = allAccounts[0].LastName;
person1.INT_FirstName__c = allAccounts[0].FirstName;
insert person1;

Person__c person2 = new Person__c();
person2.Name = allAccounts[1].INT_PersonIdent__c;
person2.INT_Confidential__c = 'UGRADERT';
person2.INT_KrrEmail__c = 'fakeemail@navtest11.no';
person2.INT_BankAccountNumber__c = '10102040100';
person2.INT_ResidentialAddress__c = 'stedveien 12';
person2.INT_ResidentialZipCode__c = '0101';
//person2.INT_ResidentialPlace__c = 'Oslo';
person2.INT_KrrMobilePhone__c = '09010202';
person2.INT_LastUpdatedFromKRR__c = Datetime.now();
person2.INT_KrrIntegrationStatus__c = 'Completed';
person2.INT_LastName__c = allAccounts[1].LastName;
person2.INT_FirstName__c = allAccounts[1].FirstName;
insert person2;

Person__c person3 = new Person__c();
person3.Name = allAccounts[2].INT_PersonIdent__c;
person3.INT_Confidential__c = 'UGRADERT';
person3.INT_KrrEmail__c = 'fakeemail@navtest11.no';
person3.INT_BankAccountNumber__c = '10102040100';
person3.INT_ResidentialAddress__c = 'stedveien 12';
person3.INT_ResidentialZipCode__c = '0101';
//person3.INT_ResidentialPlace__c = 'Oslo';
person3.INT_KrrMobilePhone__c = '09010202';
person3.INT_LastUpdatedFromKRR__c = Datetime.now();
person3.INT_KrrIntegrationStatus__c = 'Completed';
person3.INT_LastName__c = allAccounts[2].LastName;
person3.INT_FirstName__c = allAccounts[2].FirstName;
insert person3;

Person__c person4 = new Person__c();
person4.Name = allAccounts[3].INT_PersonIdent__c;
person4.INT_Confidential__c = 'UGRADERT';
person4.INT_KrrEmail__c = 'fakeemail@navtest11.no';
person4.INT_BankAccountNumber__c = '10102040100';
person4.INT_ResidentialAddress__c = 'stedveien 12';
person4.INT_ResidentialZipCode__c = '0101';
//person4.INT_ResidentialPlace__c = 'Oslo';
person4.INT_KrrMobilePhone__c = '09010202';
person4.INT_LastUpdatedFromKRR__c = Datetime.now();
person4.INT_KrrIntegrationStatus__c = 'Completed';
person4.INT_LastName__c = allAccounts[3].LastName;
person4.INT_FirstName__c = allAccounts[3].FirstName;
insert person4;

//Merge Person__c and Account. Same fix as found in crm-nks-base/dummy-data
Map<String,List<Account>> accMap = new Map<String,List<Account>>();
for(Account acc : [SELECT Id, INT_PersonIdent__c, CRM_Person__r.CRM_Account__c FROM Account]) {
    if(String.isBlank(acc.INT_PersonIdent__c)) {
        continue;
    }

    if(accMap.containsKey(acc.INT_PersonIdent__c) == false) {
        accMap.put(acc.INT_PersonIdent__c, new List<Account>());
    }

    accMap.get(acc.INT_PersonIdent__c).add(acc);
}

for(String ident : accMap.keySet()) {
    if(accMap.get(ident).size() > 1) {
        Account master;
        List<Account> duplicates = new List<Account>();
        for(Account acc : accMap.get(ident)) {
            if(acc.CRM_Person__r.CRM_Account__c == null) {
                duplicates.add(new Account(Id = acc.Id));
            } else {
                master = new Account(Id = acc.Id);
            }
        }

        Database.merge(master, duplicates);
    }
}
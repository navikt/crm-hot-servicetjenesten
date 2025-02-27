@isTest
public class HOT_QuickTextSearchControllerTest {
    @TestSetup
    static void makeData() {
        HOT_ST_TestDataFactory.createQuickTexts(3);
        HOT_ST_TestDataFactory.createRecord(new QuickText(Name = 'Abb', nksAbbreviationKey__c = '01048800153', nksType__c = 'Abbreviation'));
    }

    @isTest
    static void testsearchRecords() {
        string text = '1';
        Test.startTest();
        List<HOT_QuickTextSearchController.QuickTextMessage> qt = HOT_QuickTextSearchController.searchRecords(text);
        Test.stopTest();

        System.assertEquals(1, qt.size());
    }
    @isTest
    static void testgetabbreviations(){
        Test.startTest();
        List<QuickText> qtList = HOT_QuickTextSearchController.getQuicktexts();
        Test.stopTest();
        System.assertEquals(qtList.size(), 1);
    }
}
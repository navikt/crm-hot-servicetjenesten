@IsTest
public with sharing class HOT_HjelpemiddelsentralControllerTest {
    @IsTest
    static void testGetAllHjelpemiddelSentraler() {
        List<HOT_HjelpemiddelsentralMapping__mdt> result = HOT_HjelpemiddelsentralController.getAllHjelpemiddelSentraler();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(14, result.size(), 'There should be 14 records returned');
    }
}

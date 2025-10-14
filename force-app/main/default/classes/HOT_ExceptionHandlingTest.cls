@IsTest
private class HOT_ExceptionHandlingTest {
    @IsTest
    public static void HOT_ExceptionHandlingTest() {
        //Create a failure in a try-catch
        Test.startTest();
        try {
            Integer i = 1 / 0;
        } catch (Exception e) {
            HOT_ExceptionHandling.HOT_ExceptionHandling(
                e, 
                'Exception', 
                'HOT_ExceptionHandling', 
                'No additional info'
                );
        }
        Test.stopTest();
    }

    @IsTest
    public static void HOT_ExceptionHandlingLoggingTest() {
        //Create a failure in a try-catch
        Test.startTest();
        try {
            Integer i = 1 / 0;
        } catch (Exception e) {
            HOT_ExceptionHandling.HOT_ExceptionHandling(
                e,
                'ExceptionLogging',
                'HOT_ExceptionHandling',
                'No additional info'
            );
        }
        Test.stopTest();
    }

    @IsTest
    public static void HOT_ExceptionHandlingNotificationTest() {
        //Create a failure in a try-catch
        Test.startTest();
        try {
            Integer i = 1 / 0;
        } catch (Exception e) {
            HOT_ExceptionHandling.HOT_ExceptionHandling(
                e,
                'ExceptionNotification',
                'HOT_ExceptionHandling',
                'No additional info'
            );
        }
        Test.stopTest();
    }

    @IsTest
    public static void HOT_ExceptionHandlingLoggingAndNotificationTest() {
        //Create a failure in a try-catch
        Test.startTest();
        try {
            Integer i = 1 / 0;
        } catch (Exception e) {
            HOT_ExceptionHandling.HOT_ExceptionHandling(
                e,
                'ExceptionLoggingNotification',
                'HOT_ExceptionHandling',
                'No additional info'
            );
        }
        Test.stopTest();
    }
}

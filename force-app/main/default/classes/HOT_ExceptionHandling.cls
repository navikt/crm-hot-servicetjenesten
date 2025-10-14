public class HOT_ExceptionHandling {
    public static void HOT_ExceptionHandling(Exception e, String runMethod, String source, String additonalInfo) {
        if (runMethod == 'Exception') {
            HOT_ExceptionHandling.HOT_ExceptionHandlingWithoutLogging(e, source, additonalInfo);
        } else if (runMethod == 'ExceptionLogging') {
            HOT_ExceptionHandling.HOT_ExceptionHandlingWithLogging(e, source, additonalInfo);
        } else if (runMethod == 'ExceptionNotification') {
            HOT_ExceptionHandling.HOT_ExceptionHandlingSendNotification(e, source, additonalInfo);
        } else if (runMethod == 'ExceptionLoggingNotification') {
            HOT_ExceptionHandling.HOT_ExceptionHandlingWithLoggingAndNotification(e, source, additonalInfo);
        }
    }

    public static void HOT_ExceptionHandlingWithoutLogging(Exception e, String source, String additonalInfo) {
        //simply handle exception with logging
        system.debug('Exception: ' + e.getMessage());
    }

    public static void HOT_ExceptionHandlingWithLogging(Exception e, String source, String additonalInfo) {
        LoggerUtility logger = new LoggerUtility(CRM_ApplicationDomain.Domain.HOT, source);
        string ex = 'Error: ' + e.getMessage() + '      ----      ' + ' Additional info: ' + additonalInfo;
        logger.errorAndPublish(ex);
        system.debug('Logger: ' + logger);
        system.debug('exceptiont text: ' + ex);
    }

    public static void HOT_ExceptionHandlingSendNotification(Exception e, String source, String additonalInfo) {
        /* Logic to send SMS or Email or both */
        system.debug('Exception: ' + e.getMessage());
    }

    public static void HOT_ExceptionHandlingWithLoggingAndNotification(
        Exception e,
        String source,
        String additonalInfo
    ) {
        LoggerUtility logger = new LoggerUtility(CRM_ApplicationDomain.Domain.HOT, source);
        string ex = 'Error: ' + e.getMessage() + '      ----      ' + ' Additional info: ' + additonalInfo;
        logger.errorAndPublish(ex);
        system.debug('Logger: ' + logger);
        system.debug('exceptiont text: ' + ex);

        /* Logic to send SMS or Email or both */
    }
}

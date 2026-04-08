/**
 * Scheduler and Batch class for archiving HoT news articles to Public 360.
 *
 * This class implements both Schedulable and Batchable interfaces to allow scheduled
 * execution of news archiving. When scheduled, it identifies articles marked for archiving
 * with a delete date of tomorrow and processes them one at a time to handle HTTP callouts.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since March 2026
 * @see HOT_NewsArchiveHandler
 */
public class HOT_NewsArchive_Scheduler implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    /**
     * The SOQL query used to retrieve news articles for archiving.
     */
    @TestVisible
    private static final String CUSTOM_QUERY =
        'SELECT Id, Name ' +
        'FROM NKS_Announcement__c ' +
        'WHERE RecordType.DeveloperName=\'HOT_News\' ' +
        'AND NKS_News_Archive__c=TRUE ' +
        'AND NKS_News_Delete_Date__c=TOMORROW ' +
        'AND NKS_News_Status__c=\'Published\'';

    /**
     * The query string that will be used in the batch job.
     */
    @TestVisible
    private String query = '';

    /**
     * Default constructor that initializes the query to find published HOT news articles
     * that are marked for archiving.
     */
    public HOT_NewsArchive_Scheduler() {
        this.query = CUSTOM_QUERY;
    }

    /**
     * Constructor that accepts a custom query.
     *
     * @param query The SOQL query to use for retrieving articles.
     */
    public HOT_NewsArchive_Scheduler(String query) {
        this.query = query;
    }

    /**
     * Schedulable execute method. Starts the batch job when the scheduled job runs.
     *
     * @param sc The SchedulableContext provided by the scheduler.
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new HOT_NewsArchive_Scheduler(query), 1);
    }

    /**
     * Batchable start method. Returns the query locator for the batch job.
     *
     * @param BC The BatchableContext provided by the batch framework.
     * @return Database.QueryLocator The query locator for retrieving articles.
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    /**
     * Batchable execute method. Processes each batch of articles by archiving them to Public 360.
     * Batch size is set to 1 to allow HTTP callouts per record.
     *
     * @param context The BatchableContext provided by the batch framework.
     * @param scope The list of NKS_Announcement__c records to process.
     */
    public void execute(Database.BatchableContext context, List<NKS_Announcement__c> scope) {
        HOT_NewsArchiveHandler handler = new HOT_NewsArchiveHandler();
        for (NKS_Announcement__c article : scope) {
            handler.execute(article);
        }
    }

    /**
     * Batchable finish method. Called after all batches have been processed.
     *
     * @param context The BatchableContext provided by the batch framework.
     */
    public void finish(Database.BatchableContext context) {
        return;
    }
}

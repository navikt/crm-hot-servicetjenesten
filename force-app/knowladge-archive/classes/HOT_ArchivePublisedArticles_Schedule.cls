/**
 * Scheduler and Batch class for archiving HoT knowledge articles to Public 360.
 *
 * This class implements both Schedulable and Batchable interfaces to allow scheduled
 * execution of knowledge archiving. When scheduled, it identifies articles marked for archiving
 * with a delete date of tomorrow and processes them one at a time to handle HTTP callouts.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since March 2026
 * @see HOT_knowledgeArchiveHandler
 */
public class HOT_ArchivePublisedArticles_Schedule implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    /**
     * The SOQL query used to retrieve knowledge articles for archiving.
     */
    @TestVisible
    private static final String CUSTOM_QUERY =
        'SELECT Id, Title, ArticleNumber, KnowledgeArticleId ' +
        'FROM Knowledge__kav ' +
        'WHERE LastPublishedDate=YESTERDAY ' +
        'AND PublishStatus=\'Online\' ' +
        'AND IsLatestVersion=true ' +
        'AND RecordType.DeveloperName = \'HOT_Kunnskapsartikkel\'';

    /**
     * The query string that will be used in the batch job.''
     */
    @TestVisible
    private String query = '';

    /**
     * Default constructor that initializes the query to find published HOT knowledge articles
     * that are marked for archiving.
     */
    public HOT_ArchivePublisedArticles_Schedule() {
        this.query = CUSTOM_QUERY;
    }

    /**
     * Constructor that accepts a custom query.
     *
     * @param query The SOQL query to use for retrieving articles.
     */
    public HOT_ArchivePublisedArticles_Schedule(String query) {
        this.query = query;
    }

    /**
     * Schedulable execute method. Starts the batch job when the scheduled job runs.
     *
     * @param sc The SchedulableContext provided by the scheduler.
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new HOT_ArchivePublisedArticles_Schedule(), 1);
    }

    /**
     * Batchable start method. Returns a QueryLocator for the batch job.
     *
     * @param BC The BatchableContext provided by the batch framework.
     * @return A QueryLocator for the batch job.
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    /**
     * Batchable execute method. Processes each batch of articles.
     *
     * @param context The BatchableContext provided by the batch framework.
     * @param scope The list of articles to process in this batch.
     */
    public void execute(Database.BatchableContext context, List<Knowledge__kav> scope) {
        HOT_KnowledgeArchiveHandler handler = new HOT_KnowledgeArchiveHandler();
        for (Knowledge__kav article : scope) {
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

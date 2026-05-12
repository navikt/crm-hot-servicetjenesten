/**
 * This class is used as the controller for the HOT_KnowledgeArticlePDF Visualforce page.
 *
 * @author Kenneth Sørensen
 * @group HOT Public 360 Integration
 * @since May 2026
 */
public with sharing class HOT_KnowledgeArticlePdfController {
    /**
     * The title of the knowledge article.
     */
    public string title { get; set; }
    public string summary { get; set; }
    public string userInformation { get; set; }
    public string article { get; set; }
    public string english { get; set; }
    public string nynorsk { get; set; }
    public string employerInformation { get; set; }
    public string employerInformationInternal { get; set; }
    public string internationalInformation { get; set; }
    public string internationalInformationInternal { get; set; }
    public string advisorInformation { get; set; }
    public string advisorInformationInternal { get; set; }
    public string navno { get; set; }
    public string legislation { get; set; }
    public string resources { get; set; }
    public string whoDoesWhat { get; set; }

    public HOT_KnowledgeArticlePdfController() {
        String id = ApexPages.CurrentPage().getparameters().get('id');
        Knowledge__kav kav = [
            SELECT
                Title,
                NKS_Summary__c,
                NKS_UserInformation__c,
                Article__c,
                NKS_Nynorsk__c,
                NKS_English__c,
                EmployerInformation__c,
                EmployerInformationInternal__c,
                InternationalInformation__c,
                InternationalInformationInternal__c,
                AdvisorInformation__c,
                AdvisorInformationInternal__c,
                NKS_Nav_no__c,
                NKS_Legislation__c,
                NKS_Resources__c,
                WhoDoesWhat__c
            FROM Knowledge__kav
            WHERE Id = :id
            LIMIT 1
        ];

        this.title = kav.Title;
        this.summary = kav.NKS_Summary__c;
        this.userInformation = kav.NKS_UserInformation__c;
        this.article = kav.Article__c;
        this.english = kav.NKS_English__c;
        this.nynorsk = kav.NKS_Nynorsk__c;
        this.employerInformation = kav.EmployerInformation__c;
        this.employerInformationInternal = kav.EmployerInformationInternal__c;
        this.internationalInformation = kav.InternationalInformation__c;
        this.internationalInformationInternal = kav.InternationalInformationInternal__c;
        this.advisorInformation = kav.AdvisorInformation__c;
        this.advisorInformationInternal = kav.AdvisorInformationInternal__c;
        this.navno = kav.NKS_Nav_no__c;
        this.legislation = kav.NKS_Legislation__c;
        this.resources = kav.NKS_Resources__c;
        this.whoDoesWhat = kav.WhoDoesWhat__c;
    }
}

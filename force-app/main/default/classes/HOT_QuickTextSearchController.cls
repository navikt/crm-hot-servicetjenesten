public with sharing class HOT_QuickTextSearchController {
    @AuraEnabled
    public static List<NKS_QuickTextSearchController.QuickTextMessage> searchRecords(String search) {
        List<NKS_QuickTextSearchController.QuickTextMessage> quickTexts = new List<NKS_QuickTextSearchController.QuickTextMessage>();
        for (QuickText qt : [SELECT Id, Name, Message FROM QuickText]) {
            if (
                qt.Message.toLowerCase().contains(search.toLowerCase()) ||
                qt.Name.toLowerCase().contains(search.toLowerCase())
            ) {
                quickTexts.add(new QuickTextMessage(qt.Id, qt.Name, qt.Message));
            }
        }
        return quickTexts;
    }

    public class QuickTextMessage {
        @AuraEnabled
        public Id RecordId { get; set; }
        @AuraEnabled
        public string Name { get; set; }
        @AuraEnabled
        public string Message { get; set; }
        @AuraEnabled
        public string Summary { get; set; }

        public QuickTextMessage(Id recordId, String name, String message) {
            this.RecordId = recordId;
            this.Name = name;
            this.Message = Message;
            if (this.Message.length() > 150) {
                this.Summary = this.Message.mid(0, 150) + '...';
            } else {
                this.Summary = this.Message;
            }
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<QuickText> getQuicktexts() {
        try {
            List<QuickText> qTextList = [
                SELECT Message, nksAbbreviationKey__c, Case_sensitive__c
                FROM QuickText
                WHERE nksType__c = 'Abbreviation'
            ];
            return qTextList;
        } catch (Exception e) {
            return null;
        }
    }
}
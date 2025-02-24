public class HOT_RelatedListController {
    /**
     * @description: Returns a list of records
     * @author Stian Ruud Schikora | 09-29-2020
     * @param parentId [String : Id of the record the LWC is displayed on]
     * @param objectApiName  [String : API name of object to return]
     * @param relationField  [String : Field API name relating the record to the parent]
     * @param parentRelationField [String : Field API name relating the parent to the child(s)]
     * @param parentObjectApiName [String : Object API name of the record the LWC is displayed on]
     * @param dateField [String : The date field to include in the UU header]
     * @param filterConditions [String : Optional filter conditions]
     * @param orderConditions [String : Optional order conditions ]
     * @return List<sObject>
     **/
    @AuraEnabled(cacheable=true)
    public static List<sObject> getCRMRelatedList(
        String parentId,
        String objectApiName,
        String relationField,
        String parentRelationField,
        String parentObjectApiName,
        String dateField,
        String filterConditions,
        String orderConditions
    ) {
        Set<String> parentRelationIds = getParentRelation(parentId, parentRelationField, parentObjectApiName);
        if (parentRelationIds.isEmpty()) {
            return new List<SObject>();
        }

        String query = 'SELECT Id' + (String.isBlank(dateField) ? '' : ', ' + dateField);
        query += ' FROM ' + objectApiName + ' WHERE ';
        query += String.isNotBlank(filterConditions) ? filterConditions.trim() + ' AND ' : '';
        // query +=  relationField + ' IN (SELECT ' + parentRelationField + ' FROM ' + parentObjectApiName + ' WHERE Id = \'' + parentId + '\')';
        query += relationField + ' IN :parentRelationIds ';
        query += 'ORDER BY ' + (orderConditions != null ? orderConditions : 'ID DESC');

        List<sObject> returnList = Database.query(query);
        return returnList;
    }

    @AuraEnabled
    public static List<sObject> getRelatedList(
        List<String> fieldNames,
        String parentId,
        String objectApiName,
        String relationField,
        String parentRelationField,
        String parentObjectApiName,
        String filterConditions
    ) {
        Set<String> parentRelationIds = getParentRelation(parentId, parentRelationField, parentObjectApiName);
        String query = 'SELECT ';

        //Appending fields to query string
        for (String field : fieldNames) {
            query += field + ', ';
        }

        query = query.removeEndIgnoreCase(', ') + ' FROM ' + objectApiName + ' WHERE ';
        query += String.isNotBlank(filterConditions) ? filterConditions.trim() + ' AND ' : '';
        // query +=  relationField + ' IN (SELECT ' + parentRelationField + ' FROM ' + parentObjectApiName + ' WHERE Id = \'' + parentId + '\')';
        query += relationField + ' IN :parentRelationIds ORDER BY ID DESC';

        List<sObject> returnList = Database.query(query);
        return returnList;
    }

    /**
     * @description: Returns a set of Strings to be used in getRelatedList
     * @author: Tor Håkon Sigurdsen | 11-18-2020
     * @param parentId [String : Id of the record the LWC is displayed on]
     * @param parentRelationField [String : Field API name relating the parent to the child(s)]
     * @param parentObjectApiName [String : Object API name of the record the LWC is displayed on]
     * @return Set<String>
     */
    private static Set<String> getParentRelation(
        String parentId,
        String parentRelationField,
        String parentObjectApiName
    ) {
        Set<String> parentRelationIds = new Set<String>();
        String query = 'SELECT ' + parentRelationField + ' FROM ' + parentObjectApiName + ' WHERE Id = :parentId';

        String relationId;
        for (SObject sObj : Database.query(query)) {
            relationId = getParentRelationId(sObj, parentRelationField);
            if (relationId != null)
                parentrelationIds.add(relationId);
        }

        return parentRelationIds;
    }

    /**
     * @description: Get the parent relation Id from sObject. Will recursively walk through the field hierarchy
     * @author: Tor Håkon Sigurdsen | 11-18-2020
     * @param obj
     * @param parentRelationField [String : Field API name relating the parent to the child(s)]
     * @return String
     */
    private static String getParentRelationId(Sobject obj, String parentRelationField) {
        List<String> relationHierarchy = parentRelationField.split('\\.');
        String fieldApiName = relationHierarchy.remove(0);

        if (relationHierarchy.isEmpty()) {
            return (String) obj.get(fieldApiName);
        } else {
            return getParentRelationId(obj.getSObject(fieldApiName), String.join(relationHierarchy, '.'));
        }
    }
}

/**
 * Created by Henry on 11/3/2018.
 */

public with sharing class BaseComponentCtrl {
    private static final String URL_ROUTER = 'URL_Router_Setting__mdt';
    private static final List<String> URL_ROUTER_FIELDS = new List<String>{
            'DeveloperName',
            'MasterLabel',
            'Active__c',
            'Aura_Component_Name__c',
            'Community_Page__c',
            'Default_For_Page__c',
            'URL_Extension__c'
    };

    @AuraEnabled
    public static Map<String, Object> getSettings() {
        Map<String, Object> ret = new Map<String, Object>();
        ret.put('url-router', getUrlRoutingSettings());
        return ret;
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 11/3/2018
    *
    * @description Retrieves all ACTIVE Url_Router_Setting__mdt custom metadata entries
    */
    private static List<URL_Router_Setting__mdt> getUrlRoutingSettings() {
        Map<String, Object> filter = new Map<String, Object>();
        filter.put('Active__c', true);
        return (List<URL_Router_Setting__mdt>) CustomMetadataService.getCustomMetadataByFilter(
                URL_ROUTER,
                URL_ROUTER_FIELDS,
                filter
        );
    }
}
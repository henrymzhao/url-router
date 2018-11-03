/** ------------------------------------------------------------------------------------------------
* @Description  
*
* @Author      Henry Zhao
* @Date        06 2018
* ------------------------------------------------------------------------------------------------ */

public class CustomMetadataService {

    public static List<Object> getAllOf(String SobjectAPIName, List<String> fieldString) {
        return CustomMetadataSelector.selectAllOf(SobjectAPIName, fieldString);
    }

//    public static List<Object> getAllOf(String SobjectAPIName, List<String> fieldString, Map<String, Object> filter) {
//        return CustomMetadataSelector.selectAllOf(SobjectAPIName, fieldString, filter);
//    }

    public static List<Object> getAllOfOrderBy(
            String SobjectAPIName,
            List<String> fieldString,
            List<String> orderBy) {
        return CustomMetadataSelector.selectAllOf(SobjectAPIName, fieldString);
    }

    public static List<Object> getCustomMetadataByFilter(
            String SobjectAPIName,
            List<String> fieldString,
            Map<String, Object> filter) {
        return (List<Object>) CustomMetadataSelector.selectCustomMetadataByFilter(SobjectAPIName, fieldString, filter);
    }


    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2018-06-25
    *
    * @description Retrieves custom metadata by string API name, and specific fields provided.
    *
    * @example
    *
    *   List<Title_Ranking_Setting__mdt> rankingSettings = (List<Title_Ranking_Setting__mdt>) CustomMetadataService.getAllOfOrderBy('Title_Ranking_Setting__mdt',
        new List<String>{
                'Title_Ranking_Setting__mdt.Rank__c',
                'Title_Ranking_Setting__mdt.Title__c'
        },
        new List<String>{
                'Title_Ranking_Setting__mdt.Rank__c'
        });
    */
//    public static List<Object> getAllOfOrderBy(
//            String SobjectAPIName,
//            List<String> fieldString,
//            Map<String, Object> filter,
//            List<String> orderBy) {
//        return CustomMetadataSelector.selectAllOf(SobjectAPIName, fieldString, filter);
//    }
}
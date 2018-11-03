/** ------------------------------------------------------------------------------------------------
* @Description  
*
* @Author      Henry Zhao
* @Date        06 2018
* ------------------------------------------------------------------------------------------------ */

public class CustomMetadataSelector extends SObjectSelector {

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
        };
    }

    public static List<Object> selectAllOf(String SobjectAPIName, List<String> fieldString) {
        Map<String, Object> filter = new Map<String, Object>();
        return (List<Object>) selectSObjectsByFilter(SobjectAPIName, fieldString, filter);
    }

    public static List<Object> selectCustomMetadataByFilter(
            String SobjectAPIName,
            List<String> fieldString,
            Map<String, Object> filter) {
        return (List<Object>) selectSObjectsByFilter(SobjectAPIName, fieldString, filter);
    }

//    public static List<Object> selectAllOfOrderBy(String SobjectAPIName,
//            List<String> fieldString,
//            List<String> orderBy) {
//        Map<String, Object> filter = new Map<String, Object>();
//        return (List<Object>) selectSObjectsByFilterOrderBy(SobjectAPIName, fieldString, filter, orderBy);
//    }
//
//    public static List<Object> selectAllOfOrderBy(String SobjectAPIName,
//            List<String> fieldString,
//            Map<String, Object> filter,
//            List<String> orderBy) {
//        return (List<Object>) selectSObjectsByFilterOrderBy(SobjectAPIName, fieldString, filter, orderBy);
//    }
}
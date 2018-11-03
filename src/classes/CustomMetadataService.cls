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

}
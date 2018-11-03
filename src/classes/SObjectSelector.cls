public without sharing abstract class SObjectSelector {
    public StringBuilder.FieldListBuilder m_fieldListBuilder;

    public SObjectSelector() {
        setFieldListBuilder (new StringBuilder.FieldListBuilder(getSObjectFieldList()));
    }

    abstract List<Schema.SObjectField> getSObjectFieldList();

    public StringBuilder.FieldListBuilder getFieldListBuilder() {
        return m_fieldListBuilder;
    }

    public void setFieldListBuilder(StringBuilder.FieldListBuilder fieldListBuilder) {
        m_fieldListBuilder = fieldListBuilder;
    }

    public String getFieldListString() {
        return getFieldListBuilder().getStringValue();
    }

    public List<SObject> selectSObjectsById(String sObjectName, List<Schema.SObjectField> fields,
            Set<Id> idSet) {

        return Database.query(String.format('SELECT {0} FROM {1} WHERE id in :idSet',
                new List<String>{
                        getFieldListString(), sObjectName
                }));
    }

    public static List<SObject> selectSObjectsById(String sObjectName, List<String> fields,
            Set<Id> idSet) {

        return Database.query(String.format('SELECT {0} FROM {1} WHERE id in :idSet',
                new List<String>{
                        String.join(fields, ','), sObjectName
                }));
    }

    public List<SObject> selectSObjectsByFilter(String sObjectName,
            List<Schema.SObjectField> fields, Map<String, Object> filter) {

        QueryBuilder builder = new QueryBuilder(sObjectName, fields, filter);
        return builder.query();
    }

    public static List<SObject> selectSObjectsByFilter(String sObjectName, List<String> fields,
            Map<String, Object> filter) {

        QueryBuilder builder = new QueryBuilder(sObjectName, fields, filter);
        return builder.query();
    }

    public static List<SObject> selectSObjectsByFilterOrderBy(String sObjectName,
            List<Schema.SObjectField> fields, Map<String, Object> filter, List<String> order) {

        QueryBuilder builder = new QueryBuilder(sObjectName, fields, filter, order);
        return builder.query();
    }

    public static List<SObject> selectSObjectsByFilterOrderBy(String sObjectName, List<String> fields,
            Map<String, Object> filter, List<String> order) {

        QueryBuilder builder = new QueryBuilder(sObjectName, fields, filter, order);
        return builder.query();
    }

    public List<Schema.SObjectField> getWriteableFields(String sObjectName) {
        List<Schema.SObjectField> writeableFieldTokens = new List<SObjectField>();

        for (Schema.SObjectField ft : Schema.getGlobalDescribe().get(sObjectName).getDescribe().Fields.getMap().values()) { // loop through all field tokens (ft)
            Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
            if (fd.isCreateable()) { // field is creatable
                writeableFieldTokens.add(ft);
            }
        }

        return writeableFieldTokens;
    }

}
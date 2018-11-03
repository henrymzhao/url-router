public virtual class StringBuilder
{
    protected String stringValue;
    
    private static StringBuilder instance = null;
    private static StringBuilder.CSVBuilder instanceCSV = null;
    private static StringBuilder.FieldListBuilder instanceFieldList = null;

    
    private StringBuilder() {}
    
       
    public static StringBuilder.CSVBuilder getCSVBuilderInstance(List<String> values){
        instanceCSV = new StringBuilder.CSVBuilder(values);
        return instanceCSV;
    }
    
    public static StringBuilder.FieldListBuilder getFieldListBuilderInstance(List<Schema.SObjectField> values){
        instanceFieldList = new StringBuilder.FieldListBuilder(values);
        return instanceFieldList;
    }
    
    public StringBuilder(List<String> values){
        add(values);
    }
    
    public virtual void add(List<String> values){
        for(String value : values)
            add(value);
    }

    public virtual void add(String value){
        if(value != null){
            stringValue = ( stringValue==null ? value : stringValue + value );
        }            
    }

    public virtual String getStringValue(){
        return stringValue;
    }


    /** Subclasses **/

    public virtual with sharing class CSVBuilder extends StringBuilder {
        private CSVBuilder() {}

        private CSVBuilder(List<String> values){
            super(values);
        }
        
        public virtual override void add(String value){
            if(value!=null){
                stringValue = ( stringValue==null ? '{0}' + value : stringValue + ',{0}' + value );
            }    
        }
        
        public override String getStringValue(){
            return getStringValue('');
        }
        
        public String getStringValue(String itemPrefix){
            return stringValue==null ? null : String.format(stringValue,new List<String>{itemPrefix});
        }
    }

    public virtual with sharing class FieldListBuilder extends CSVBuilder {
        public FieldListBuilder(List<Schema.SObjectField> values){
            for(Schema.SObjectField value : values)
                add(value.getDescribe().getName());
        }
    }
 
}
/****************************************************************************************
 * Utility class to programmatically build and execute a SOQL query without writing 
 * dynamic or inline SOQL queries. Primary purpose is handle query construction and
 * security
 *
 * SECURITY
 * ------------
 *  (1) global scope so it can be packaged and installed in other orgs
 *  (2) no explicit sharing settings, will inherit it from class it is instantiated from
 *
 * USAGE
 * ------------
 *  (1) For manual query building, use QueryBuilder(String sObjectName) constructor and
 *      manual query construction methods
 *  (2) For simple, common pattern queries, use a specific constructor defined below
 *
 * RESTRICTIONS
 * ------------
 *  (1) Sets and Maps are not supported for WHERE clause filters. Please convert to a list
 *  (2) Nested queries are not supported
 * 
 * @author Groundswell - Prishan - prishan@gscloudsolutions.com
 * @refactor Groundswell - Alec - alec@gscloudsolutions.com
 * @date Nov 2017
 ****************************************************************************************/

global class QueryBuilder {

    public static final String defaultoperator = 'AND';

    // SOQL QUERY PATTERNS
    public static final String querySelectPattern = 'SELECT {0} FROM {1}';
    public static final String queryRelationshipPattern = ', {0}';
    public static final String queryWherePattern = ' WHERE {0}';
    public static final String queryOrderByPattern = ' ORDER BY {0}';
    public static final String queryGroupByPattern = ' GROUP BY {0}';
    public static final String queryWithPattern = ' WITH DATA CATEGORY {0}';
    public static final String queryLimitPattern = ' LIMIT {0}';
    public static final String queryOffsetPattern = ' OFFSET {0}';

    // EXPRESSION OPERATORS
    public static final String EXPOP_INCLUDES = 'INCLUDES';
    public static final String EXPOP_LIKE = 'LIKE';
    public static final String EXPOP_EQ = '=';
    public static final String EXPOP_NOT_EQ = '<>';
    public static final String EXPOP_IN = 'IN';
    public static final String EXPOP_LESSTHAN = '<';
    public static final String EXPOP_GREATERTHAN = '>';
    public static final String EXPOP_GREATEREQUALTHAN = '>=';
    public static final String EXPOP_LESSEQUALTHAN = '<=';
    public static final Set<String> VALID_EXPOP = new Set<String>{
        EXPOP_LIKE, EXPOP_EQ, EXPOP_NOT_EQ, EXPOP_IN, EXPOP_GREATERTHAN, 
        EXPOP_LESSTHAN, EXPOP_GREATEREQUALTHAN, EXPOP_LESSEQUALTHAN, EXPOP_INCLUDES
    };

    // DATA CATEGORY EXPRESSION OPERATORS
    public static final String DATA_EXPOP_ABOVE = 'ABOVE';
    public static final String DATA_EXPOP_BELOW = 'BELOW';
    public static final String DATA_EXPOP_AT = 'AT';
    public static final String DATA_EXPOP_ABOVE_OR_BELOW = 'ABOVE_OR_BELOW';
    public static final Set<String> VALID_DATA_EXPOP = new Set<String>{
        DATA_EXPOP_ABOVE, DATA_EXPOP_BELOW, DATA_EXPOP_AT, DATA_EXPOP_ABOVE_OR_BELOW
    };

    // RELATIONSHIP QUERIES
    public static final String REL_QUERY_DATACAT = '(SELECT ParentId, DataCategoryGroupName,'
        + ' DataCategoryName FROM DataCategorySelections)';
    public static final String REL_QUERY_FAVOURITE = '(SELECT NetworkId, ParentId, SubscriberId'
        + 'FROM FeedSubscriptionsForEntity)';        
    public static final String REL_QUERY_VOTESTAT = '(SELECT ParentId, NormalizedScore FROM'
        + ' VoteStats WHERE Channel = \'AllChannels\')';
    public static final String REL_QUERY_VIEWSTAT = '(SELECT ParentId, ViewCount FROM'
        + ' ViewStats WHERE Channel = \'AllChannels\')';

    // KNOWLEDGE ARTICLE VIEW STAT
    public static final String VIEWSTAT_INCREMENT = 'UPDATE VIEWSTAT';
    public boolean doUpdateViewStat = false;

    
    // DISTANCE UNITS
    public static final String UNIT_MILES = 'mi';
    public static final String UNIT_KILOMETRE = 'km';
    public static Set<String> VALID_DISTANCE_UNITS = new Set<String> { UNIT_MILES, UNIT_KILOMETRE };

    // SOQL QUERY ELEMENTS
    public String fields;
    public List<String> relationshipQueries;
    public String sObjectName {get;set;}
    public List<String> queryFilter {get;set;}
    public String operator {get;set;}
    public String orderBy;
    public String groupBy;
    public List<String> withFilter {get;set;}
    public Integer queryLimit {get;set;}
    public Integer offset {get;set;}



    ////////////////////////////////////////////////////////////////////////////////////
    // Inner Classes
    ////////////////////////////////////////////////////////////////////////////////////

    global class QueryException extends Exception { }

    /*
     * Represents an expression meant to be used in the WITH clause
     *
     * @author Groundswell - alec - alec@gscloudsolutions.com
     * @date Nov 2017
     */
    global class DataExpression extends BaseExpression {
        public DataExpression(String fieldname, String expressionOperator, Object value) {
            super(fieldname, expressionOperator, value);
        }

        /*
         * Converts the class Expression representation to a SOQL ready string. Supports:
         *  (1) <x> AT List<String>
         *  (2) <x> <operator> <y>
         * 
         * @author Groundswell - alec - alec@gscloudsolutions.com
         * @date Nov 2017
         */
        public override String getExpression() {
            if (expressionOperator.Equals(DATA_EXPOP_AT) && value instanceof List<Object>) {
                return getInDataParamValue(this.fieldname, (List<String>)this.value);
            } else {
                return getDataParamValue(this.fieldname, this.expressionOperator, 
                    String.valueOf(this.value));
            }
        }
    }

    /*
     * Represents an expression meant to be used in the WHERE clause
     *
     * @author Groundswell - alec - alec@gscloudsolutions.com
     * @date Nov 2017
     */
    global class Expression extends BaseExpression {
        public Expression(String fieldname, String expressionOperator, Object value) {
            super(fieldname, expressionOperator, value);
        }

        /*
         * Converts the class Expression representation to a SOQL ready string. Supports:
         *  (1) <x> LIKE <string>
         *  (2) <x> IN <List<obj>>
         *  (3) <x> OPERATOR <y>
         * 
         * @author Groundswell - Prishan - prishan@gscloudsolutions.com
         * @refactor Groundswell - alec - alec@gscloudsolutions.com
         * @date Nov 2017
         */
        public override String getExpression() {
            if (expressionOperator.Equals(EXPOP_LIKE) && value instanceof String) {
                return getLikeParamValue(this.fieldName, String.valueOf(this.value));
            } else if (value instanceof List<Object> && expressionOperator.Equals(EXPOP_IN)) {
                return getInParamValue(fieldname, (List<Object>)value);
            } else {
                return getInequalityParamValue(this.fieldname, this.value,
                    this.expressionOperator);
            }
        }
    }

    /*
     * Virtual class representing a string of form <x> <Operator> <y> 
     * Use extended classes above
     *
     * @author Groundswell - alec - alec@gscloudsolutions.com
     * @date Nov 2017
     */
    global virtual class BaseExpression {
        public String fieldname {get;set;}
        public String expressionOperator {get;set;}
        public Object value {get;set;}

        public BaseExpression(String fieldname, String expressionOperator, Object value) {
            if (!VALID_EXPOP.contains(expressionOperator.toUpperCase()) && 
                !VALID_DATA_EXPOP.contains(expressionoperator.toUpperCase())) {
                throw new QueryException(expressionOperator + 'is not a valid expression operator.'
                    + ' Valid values: ' + VALID_EXPOP); 
            }
            this.fieldname = fieldname;
            this.expressionOperator = expressionOperator;
            this.value = value;
        }

        // OVERRIDE ME
        public virtual String getExpression() { 
            return getDataParamValue(this.fieldname, this.expressionOperator, 
                String.valueOf(this.value));
        }
    }



    
    ////////////////////////////////////////////////////////////////////////////////////
    // Constructors
    ////////////////////////////////////////////////////////////////////////////////////
    
    /*
     * USAGE: Most basic constructor for manual query construction
     */
    public QueryBuilder(String sObjectName) {
        this.sObjectName = sObjectName;
        this.operator = defaultOperator;
        this.queryFilter = new List<String>();
        this.withFilter = new List<String>();
        this.relationshipQueries = new List<String>();
    }
    
    /*
     * FUNCTIONALITY: SELECT/FROM
     */
    public QueryBuilder(String sObjectName, List<String> fields) {
        this(sObjectName, StringBuilder.getCSVBuilderInstance(fields).getStringValue(),
            null, null, null);
    } 
    public QueryBuilder(String sObjectName, List<Schema.SObjectField> fields) {
        this(sObjectName, StringBuilder.getFieldListBuilderInstance(fields).getStringValue(),
            null, null, null);
    }

    /*
     * FUNCTIONALITY: SELECT/FROM/WHERE
     */
    public QueryBuilder(String sObjectName, List<String> fields, Map<String,Object> filter) {
        this(sObjectName, StringBuilder.getCSVBuilderInstance(fields).getStringValue(),
            filter, null, null);
    }
    public QueryBuilder(String sObjectName, List<Schema.SObjectField> fields, 
        Map<String,Object> filter) {
        
        this(sObjectName, StringBuilder.getFieldListBuilderInstance(fields).getStringValue(),
            filter, null, null);
    }
    
    /*
     * FUNCTIONALITY: SELECT/FROM/WHERE/ORDER 
     */
    public QueryBuilder(String sObjectName, List<String> fields, Map<String,Object> filter, 
        List<String> order) {
        
        this(sObjectName, StringBuilder.getCSVBuilderInstance(fields).getStringValue(),
            filter, StringBuilder.getCSVBuilderInstance(order).getStringValue(), null);
    }
    
    public QueryBuilder(String sObjectName, List<Schema.SObjectField> fields, 
        Map<String,Object> filter, List<String> order) {
        
        this(sObjectName,StringBuilder.getFieldListBuilderInstance(fields).getStringValue(),
            filter, StringBuilder.getCSVBuilderInstance(order).getStringValue(), null);
    }
    
    /*
     * INTERNAL USE
     * DOES NOT SUPPORT WITH CLAUSE (yet)
     */
    private QueryBuilder(String sObjectName, String fields, Map<String,Object> filter, 
        String order, String groupBy) {

        this.sObjectName = sObjectName;
        this.fields = fields;
        this.operator = defaultoperator;
        this.orderBy = order;
        this.groupBy = groupBy;
        this.queryFilter = new List<String>();
        this.withFilter = new List<String>();
        this.relationshipQueries = new List<String>();
        initFilter(filter);
    }

    


    ////////////////////////////////////////////////////////////////////////////////////
    // Query Methods
    ////////////////////////////////////////////////////////////////////////////////////

    /**
     * Executes and returns a standard query defined by your querybuilder instance
     * 
     * @throws QueryException if GROUPBY clause is set - cannot handle AggregateQuery[] return
     */
    public List<Sobject> query() {
        if (String.isNotEmpty(this.groupBy)) {
            throw new QueryException('You cannot call query() while having defined a'
                + ' GROUP BY clause. Call getAggregateQuery() instead.');
        }
        return Database.query(getQuery());
    }

    /**
     * Executes and returns an aggregate query defined by your querybuilder instance
     * 
     * @throws QueryException if GROUPBY clause is not set - only handles AggregateQuery[] return
     */
    public AggregateResult[] getAggregateQuery() {
        if (String.isEmpty(this.groupBy)) {
            throw new QueryException('You cannot call getAggregateQuery() without defining'
                + ' a GROUP BY clause');
        }
        return Database.query(getQuery());
    }

    /**
     * Returns back a valid SOQL query string that represents the query built in your 
     * querybuilder instance
     */
    public String getQuery(){
        String query = '';

        if (String.isNotEmpty(this.sObjectName) && String.isNotEmpty(this.fields)) {
            String fieldStr = fields;
            if (!relationshipQueries.isEmpty()) {
                fieldStr += ', ' +  String.join(relationshipQueries, ',');
            }
            query += String.format(querySelectPattern, new List<String>{ fieldStr, sObjectName }); 
        }
        if (!queryFilter.isEmpty()) {
             query += String.format(queryWherePattern, new List<String>{ getFilterString() });
        }
        if (!withFilter.isEmpty()) {
            query += String.format(queryWithPattern , new List<String>{ getWithFilterString() });
        }
        if (String.isNotEmpty(this.groupBy)) {
            query += String.format(queryGroupByPattern, new List<String> { this.groupBy });
        }
        if (String.isNotEmpty(this.orderBy)) {
            query += String.format(queryOrderByPattern, new List<String>{ this.orderBy }); 
        }
        if (queryLimit != null) {
            query += String.format(queryLimitPattern, 
                new List<String> { String.valueOf(queryLimit) });
        }
        if (offset != null) {
            query += String.format(queryoffsetPattern, 
                new List<String>{ String.valueOf(offset) }); 
        }
        if (doUpdateViewStat) {
            query += ' ' + VIEWSTAT_INCREMENT;
        }
        System.debug('query: ' + query);
        return query;
    }




    ////////////////////////////////////////////////////////////////////////////////////
    // Manual Query Building
    ////////////////////////////////////////////////////////////////////////////////////

    // SELECT
    // ----------------------------------------------------------
  
    public void addFields(List<String> fields) {
        if (fields != null && !fields.isEmpty()) {
            this.fields = StringBuilder.getCSVBuilderInstance(fields).getStringValue();
        }
    }

    public void addFields(List<Schema.SObjectField> fields) {
        if (fields != null && !fields.isEmpty()) {
            this.fields = StringBuilder.getFieldListBuilderInstance(fields).getStringValue();
        }   
    }

    
    // RELATIONSHIP QUERIES
    // --------------------------------------------------------

    /**
     * @Precondition: the sObjectType of this query MUST be a concrete representation of a
     * KnowledgeArticleVersion
     */
    public void includeDataCategories() {
        relationshipQueries.add(REL_QUERY_DATACAT);
    }    

   
    // WHERE
    // --------------------------------------------------------

    /**
     * For the number <numDays> provided, starts 00:00:00 of the current day and continues 
     * for the past <numDays>
     */
    public void addLastNDaysFunction(String field, Integer numDays) {
        if (String.isNotEmpty(field)) {
            queryFilter.add(field + '= LAST_N_DAYS:' + numDays);
        }
    }

    /**
     * Adds an expression of the form <field> = <filterCriteria>, or if <filterCriteria>
     * is a list, of the form <field> IN <filterCriteria>
     */
    public void addFilter(String field, Object filterCriteria){
        if (field != null && filterCriteria != null) {
            if (filterCriteria instanceof List<Object>) {
                addINFilter(field, (List<Object>)filterCriteria);
            } else {
                queryFilter.add(getParamValue(field, filterCriteria));  
            }
        }
    }
    
    /**
     * Adds an expression of the form <field> IN <filterCriteria>
     */
    public void addINFilter(String field, List<Object> filterCriteria){
        if (field != null && filterCriteria != null && !filterCriteria.isEmpty()) {
           queryFilter.add(getInParamValue(field,filterCriteria));  
        }
    }

    /**
     * Adds an expression of the form <field> LIKE %<filterCriteria>%
     */
    public void addLIKEFilter(String field, String filerCriteria){
        if (field != null && filerCriteria != null){
           queryFilter.add(getLikeParamValue(field,filerCriteria));  
        }
    }

    /**
     * Adds an expression of the form <field> INCLUDES (<filterCriteria>)
     */ 
    public void addINCLUDEfilter(String field, List<Object> filterCriteria) {
        if (field != null && filterCriteria != null && !filterCriteria.isEmpty()) {
           queryFilter.add(getIncludesParamValue(field, filterCriteria));  
        }
    }

    /**
     * General method to add expressions contained in <expressions>
     * via the inner Expression class
     */
    public void addFilters(List<Expression> expressions){
        for (Expression expression :expressions){
            queryFilter.add(expression.getExpression());
        }
    }

    /**
     * General method to add expressions contained in <filter> of the form <x> = <y>
     */
    public void addFilters(Map<String,Object> filter){
        initFilter(filter);
    } 

    /**
     * Removes any expressions in the WHERE clause
     */
    public void clearFilter(){
        queryFilter.clear();
    }
    
    /**
     * Returns back a formatted string equivalent to the WHERE clause
     */
    public String getFilterString(){
        if (!queryFilter.isEmpty()) {
            return String.join(queryFilter, ' ' + operator + ' ');
        }
        return null;   
    }


    // GROUP BY
    // -------------------------------------------------------------------

    public void setGroupBy(List<Schema.SObjectField> fields) {
        if (fields != null && !fields.isEmpty()) {
            this.groupBy = StringBuilder.getFieldListBuilderInstance(fields).getStringValue();
        }
    }

    public void setGroupBy(List<String> fields){
        if (fields != null && !fields.isEmpty()) {
            this.groupBy = StringBuilder.getCSVBuilderInstance(fields).getStringValue();
        }
    }

    public String getGroupBy() {
        return this.groupBy;
    }

    // ORDER BY
    // --------------------------------------------------------

    public void setOrderBy(List<String> fields){
        this.orderBy = StringBuilder.getCSVBuilderInstance(fields).getStringValue();
    }

    public void setOrderBy(List<Schema.SObjectField> fields){
        this.orderBy =  StringBuilder.getFieldListBuilderInstance(fields).getStringValue();
    }

    public String getOrderBy() {
        return this.orderBy;
    }

    // WITH
    // --------------------------------------------------------

    /**
     * General method to add expressions contained in <expressions>
     * via the inner Expression class to the WITH clause
     */
    public void addWithFilters(List<DataExpression> expressions){
        for (DataExpression expression : expressions){
            withFilter.add(expression.getExpression());
        }
    }

    /**
     * Returns back a formatted string equivalent to the WITH clause
     */
    public String getWithFilterString(){
        if (!withFilter.isEmpty()) {
            return String.join(withFilter, ' ' + operator + ' ');
        }
        return null;   
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Private Methods 
    ////////////////////////////////////////////////////////////////////////////////////

    /**
     * Takes the map <filter> and initializes the WHERE clause of this instance
     * with expressions in the form of <x> = <y>, or <x> IN <y>
     */
    private void initFilter(Map<String,Object> filter) {
        if (filter != null) {
            for (String field : filter.keySet()) {
                if (String.isNotEmpty(field)) {
                    object value  = filter.get(field);
                    if (value instanceof List<Object>) {
                        addINFilter(field,(List<Object>)filter.get(field));
                    } else {
                        addFilter(field,filter.get(field));
                    }
                }
            }
        }
    }

    /**
     * Returns a SOQL ready expression in the form of <fieldname> = <value>
     */
    private static String getParamValue(String fieldName, Object value) {
        if (String.isNotBlank(fieldName)) {
            return value instanceof String
                ?  fieldName + '=\'' + String.escapeSingleQuotes(String.valueOf(value)) + '\''
                :  fieldName + '=' + String.valueOf(value); 
        }
        return '';
    }

    /**
     * Retruns a SOQL ready expression in the form of <fieldname> <expop> <value>, where
     * <expop> is an expression operator corresponding to a constant defined above
     */
    private static String getInequalityParamValue(String fieldname, Object value, String expop) {
        if (String.isNotBlank(fieldName) && String.isNotBlank(expop)) {

            // Number and Boolean: Do not need to encase value in single quotes
            if (value instanceof Integer || value instanceof Decimal || value instanceOf Double
                || value instanceof Long || value instanceof Boolean) {

                return fieldname + ' ' + expop + ' ' + String.valueOf(value);
            }

            // Date: Format using locale of current user and encase in single quotes
            if (value instanceof Date) {
                return fieldname + ' ' + expop + ' \'' + ((Date)value).format() + '\'';
            }

            //  String: escape single quotes and encase in single quotes
            if (value instanceof String) {
                return fieldname + ' ' + expop + ' \'' 
                    + String.escapeSingleQuotes(String.valueOf(value)) + '\'';
            }

        }
        return '';
    }

    /**
     * Returns a SOQL ready expression in the form of <fieldname> LIKE %<value>%
     * Default: wildcard operators at start and end of value
     */
    private static String getLikeParamValue(String fieldName, String value) {
        if (String.isNotBlank(fieldName) && String.isNotBlank(value)) {
            return fieldName + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'';
        } else {
            return '';
        }
    }

    /**
     * Returns a SOQL ready expression of the form <x> IN (<value1>, <value2>, ..., <valueN> )
     */
    private static String getInParamValue(String fieldName, List<Object> values){
        if (values != null && !values.isEmpty() && String.isNotBlank(fieldName)) { 
            List<String> inValueList = new List<String>(); 
            Boolean doEscapeSingleQuotes = values instanceof List<String>;

            for (Object val : values) {
                String stringVal = String.valueOf(val);
                if (doEscapeSingleQuotes) {
                    stringVal = String.escapeSingleQuotes(stringVal);
                }
                inValueList.add('\'' + stringVal + '\''); 
            }
            return fieldName + ' IN (' + String.join(inValueList , ',') + ')';
        } else {
            return '';
        }
    }

    private static String getIncludesParamValue(String fieldName, List<Object> values) {
        if (values != null && !values.isEmpty() && String.isNotBlank(fieldName)) { 
            List<String> includesValueList = new List<String>(); 
            
            for (Object val : values) {
                String stringVal = String.valueOf(val);
                stringVal = String.escapeSingleQuotes(stringVal);
                includesValueList.add('\'' + stringVal.trim() + '\''); 
            }
            return fieldName + ' INCLUDES (' + String.join(includesValueList , ',') + ')';
        } else {
            return '';
        }
    }

    /**
     * Returns a SOQL ready expression of the form <x> <operator> <value>
     */
    private static String getDataParamValue(String fieldName, String operator, String value) {
        if (String.isBlank(fieldName) || String.isBlank(operator) || String.isBlank(value)) {
            return '';
        }
        return fieldName + ' ' + operator + ' ' + value;
    }

    /**
     * Returns a SOQL ready expression of the form <x> AT (<value1>, <value2>, ..., <valueN> )
     */
    private static String getInDataParamValue(String fieldname, List<String> values) {
        if (values == null || values.isEmpty() || String.isBlank(fieldName)) { 
            return '';
        }
        return fieldname + ' AT(' + String.join(values, ',') + ')';    
    }

 }
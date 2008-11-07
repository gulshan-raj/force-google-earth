/*
 * Controller used by dogeocode.page
 */
public class exampleCon {
	
    Integer count = 0;
    public Account acc { get; private set;}         
    public string msg {get; set;}
    public PageReference incrementCounter() {
        count++;
        try {
	        acc = [select id, name from account where geocode_status__c = null limit 1]; 
	        system.debug( acc );
	        GoogleGeocode.go(acc.id);
        } catch (exception e) { 
        	msg = e.getMessage(); 
        }
        return null;
    }   

    public class summary { 
        public integer uncoded { get; private set; } 
        public integer geocode { get; private set; } 
        public integer other { get; private set; } 
    }
    
    // note this may fail in large orgs, the count of records will hit the limit.
    public summary summary { 
        get {
            summary s = new summary();
            s.uncoded = [  select count() from account where geocode_status__c = null limit 500  ];
            s.geocode = [  select count() from account where geocode_status__c = 'G_GEO_SUCCESS' limit 500 ];
            return s;
        } 
    }
    public Integer getCount() {  return count;   }
    
    public static testmethod void t1 () { 
        examplecon e = new examplecon(); 
        system.assert( e.acc == null ); 
        system.assert( e.msg == null);
        system.assert( e.incrementCounter() == null);
        system.assert( e.getCount() > 0 );
        summary summary = e.summary;    

        
    }
}
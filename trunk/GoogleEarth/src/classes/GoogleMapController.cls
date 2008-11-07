/* controller example for google map component */

public class GoogleMapController {
    // or whatever you need to return a valid key to the component
    public string forcekey { get { return geoApiKey.forcekey; }}
    
    Account[] accounts = new Account[]{};
    
    Account[] init() { 
     	if (accounts.size() > 0 ) return accounts;
    	accounts = [select name, description, 
            lat__c, lon__c ,
            website, phone, billingcity, billingstate
                from account 
                where geocode_status__c = 'G_GEO_SUCCESS'
                limit 14];
        return accounts;
    }
    
    public string geoDataTable { get { 
    	init();
        GoogleViz gv = new GoogleViz();
        gv.cols = new list<GoogleViz.col> { 
            new GoogleViz.Col('A','Lat','n'),
            new GoogleViz.Col('B','Lon','n'),
            new GoogleViz.Col('C','Name','t') 
        };
        for (Account a: accounts ) {
        	googleViz.row rr = new googleViz.row();
        	rr.cells.add ( new GoogleViz.cell( a.lat__c ) ); 
            rr.cells.add ( new GoogleViz.cell( a.lon__c ) ); 
            string descript =  a.name +  a.billingCity + ', ' +
            a.billingstate +a.phone ;
            if ( a.website != null ) { descript += a.website ; }
        	rr.cells.add ( new GoogleViz.cell( descript ) ); 
        	gv.addRow( rr ); 
        }
        
        return gv.toJsonString(); 
    } }     
    
	public static testmethod void t1() {
		GoogleMapController c = new GoogleMapController();
		c.init(); 
		system.assert( c.geoDataTable != null );
	}	
}
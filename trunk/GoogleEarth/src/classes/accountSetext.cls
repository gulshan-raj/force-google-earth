/* simple example of a standard set controller, using accounts
 * results are used to feed map and earth components.
 */

public class accountSetext {
	public integer pagesizemax {get; private set;} 	{pagesizemax= 100;}
	
    ApexPages.StandardSetController controller; 

    public accountSetext(ApexPages.StandardSetController c) {
        controller = c; 
        controller.setPageSize(20);
        if ( ApexPages.currentPage().getParameters().get('fcf') != null ) {
        	system.debug('set the controller filter id');
        	controller.setFilterId(
        	 ApexPages.currentPage().getParameters().get('fcf'));        	 
        }
        system.debug( 'getResultSize ' +controller.getResultSize() );
        system.debug( 'getPageNumber  ' + controller.getPageNumber() );
        system.debug( 'filter id '+ controller.getFilterId() );
         
    }
	public static testmethod void t_getAccountSet() { 
		PageReference pageRef = Page.GoogleEarth;
        Test.setCurrentPage(pageRef);
    	//pageRef.getParameters().put('fcf', 'yyyy');
     
		accountSetext a = new accountSetext( new ApexPages.StandardSetController([select id,name from Account limit 3]) );	
		system.assert( a.getAccountSet() != null );
	} 
	
    public list<Account> getAccountSet() { 
    	list<Account> ret = new list<Account>(); // build a new list, with cloned records
       
        controller.first();
        ret.addAll( (list<Account>)controller.getRecords().clone() );
        while ( controller.getHasNext() ) { 
            controller.next();
            system.debug( controller.getHasNext() );
            if ( controller.getPageSize() + ret.size() <= 1000 ) { 
                ret.addAll( (list<Account>)controller.getRecords().clone()  );
            }  else {  
                break; // list is longer than 1000 
            }   
        }
        
        return escapeHTML( ret);
    }
    
    // the ampersand is not HTML escaped by the kml page generation, do that here
    list<Account> escapeHTML( Account[] ret) {
    	for ( account a: ret ) { 
            a.name = a.name.replace('&','&amp;');
            if ( a.description != null) 
                a.description = a.description.replace('&','&amp;'); 
        }
        return ret;
    }
    
    public pagereference generateKML2() { 
        system.debug( 'move to new page');
    	pagereference p = new PageReference( '/apex/GoogleEarthMapGenerate');
    	return p;
    }
    public Decimal selectedCount { 
    	get { return controller.getselected().size(); } }
   
    public PageReference checkforSelected() { 
        if ( controller.getselected().size() > 0 ) return null; // ok
        return new PageReference('/apex/noAccountSelected');	
    } 
    
    
    // TODO fix, this can fault if getRecords() is null, happens if there is a new user
    // with no prior account list viewed
    public Account firstRecord { 
      get{ 
    	if ( controller.getRecords().size() == 0 ) {
    		return [ SELECT name,billingcity,billingstate,billingstreet,
    			lat__c,lon__c,description,website,phone FROM Account
				where  geocode_status__c = 'G_GEO_SUCCESS'  limit 1 ];
    	}
    	return (Account)controller.getRecords()[0]; 	
      } 
   	}
    
    public string kmlstring { get { 
        system.debug( 'kmlstring , pagesize ' + controller.getPageSize() );
      //  controller.setPageSize(pagesizemax);
        string ret;
        xmldom dom  = new xmldom('<kml xmlns="http://www.opengis.net/kml/2.2"></kml>');
        xmldom.element kml = dom.getElementByTagName('kml');
        xmldom.element doc = node('Document'); 
        xmldom.element name = node( 'name', 'foundation.kml') ;
        doc.appendChild( name );
        kml.appendChild( doc );
        
        xmldom.element folder = new xmldom.element('Folder');
        doc.appendChild(folder);
        folder.appendChild ( node ('open','1' ) ) ;
        folder.appendChild ( node ('name','Foundation Grantees' ) ) ;
        
        // repeat placemark
        controller.first(); 
        integer ps = controller.getPageSize() ;
        controller.setPageSize(pagesizemax);
        accs = (list<account>) controller.getRecords(); 
        system.debug( 'list size '+accs.size());
        controller.setPageSize(ps);
        
        integer i = 1;
         for ( account a: accs) { 
    //     	if ( a.geocode_status__c != 'G_GEO_SUCCESS' ) continue;
            
	        xmldom.element p = placemark(a);
	        folder.appendChild(p);
	        i++;
	        //if ( i > pagesizemax)	           break;
        }
        
        ret = dom.getElementByTagName('kml').toXmlString(); 
        ret = ret.replace( '&','&amp;');
        return ret.replace('\n','');
    }}
    list<account> accs;
    xmldom.element node(string name) {  return node( name, null);  }
    xmldom.element node(string name,string val) { 
    	xmldom.element e = new xmldom.element(name);
        if ( val != null ) e.nodeValue = val;
        return e;	
    } 
    xmldom.element placemark(account a ) { 
        xmldom.element e = node('Placemark');
        e.appendChild( node ( 'name',a.name) );
        e.appendChild( node ( 'description','<br />'+a.billingcity + ', ' +a.billingstate) );
        xmldom.element p = node ( 'Point' );
      //  system.debug ( a.lon__c );
        p.appendChild( node ( 'coordinates', a.lon__c + ',' + a.lat__c + ',0'));
        e.appendChild( p );
        return e;	
    }
    
    // generate kml using xmldom rather than a page and getContent.
    public static testmethod void t1() { 
    	
    	List<account> accountList = [SELECT name,billingcity,billingstate,billingstreet,lat__c,lon__c,description,website,phone FROM Account 
    	where  geocode_status__c = 'G_GEO_SUCCESS'  limit 1 ];
    	ApexPages.StandardSetController controller = 
    	new ApexPages.StandardSetController (accountList);
       
       // system.assert( controller.getResultSize()  > 0 );
      //  system.debug( 'getResultSize ' +controller.getResultSize() );

    	controller.first();
    	system.assert( controller.getRecords().size() > 0);
    	
    	accountsetext ext = new accountsetext(controller);
        system.debug( ext.kmlstring );
        system.assert( ext.selectedCount == 0);
        
        system.debug( 'getResultSize ' +controller.getResultSize() );
        system.debug( 'getPageNumber  ' + controller.getPageNumber() );
        system.debug( 'filter id '+ controller.getFilterId() );
         
       	ext.generateKML2();
       	system.assert( ext.checkforSelected() != null ); 
       	
       	system.assert( ext.getGvizDataTable() != null ); 
       	system.assert(
       	ext.getdataTable() 
       	!= null ); 
       	system.assert(
       	ext.forcekey
       	!= null ); 
       	ext.location = '32.0,-121.0';
       	system.assert(
       	ext.selected2() == null );
    }
    
    public string getGvizDataTable() { 
        GoogleViz gv = new GoogleViz();
        gv.cols = new list<GoogleViz.col> { 
            new GoogleViz.Col('A','Id','t'),
            new GoogleViz.Col('B','Name','t')  };
    
        map<id, account> accs = 
        	new map<id,account>((list<Account>)controller.getRecords());
 		
        for( Account  o:[select id,name from Account where id in :accs.keyset()] ) { 
            googleViz.row rr = new googleViz.row();
            rr.cells.add ( new GoogleViz.cell( o.id ) );
            rr.cells.add ( new GoogleViz.cell( o.name ) );  
            gv.addRow( rr );   
        }     
        string ret =  gv.toJsonString();
        return escapeQuote(ret); 
    }
    
    public string getGvizDataTable2() { 
        GoogleViz gv = new GoogleViz();
        gv.cols = new list<GoogleViz.col> { 
            new GoogleViz.Col('A','Id','t'),
            new GoogleViz.Col('B','Name','t'),
            new GoogleViz.Col('C','BillingStreet','t')  };
    
        map<id, account> accs = 
        	new map<id,account>((list<Account>)controller.getRecords());
 		
        for( Account  o:[select id,name,billingstreet from Account where id in :accs.keyset()] ) { 
            googleViz.row rr = new googleViz.row();
            rr.cells.add ( new GoogleViz.cell( o.id ) );
            rr.cells.add ( new GoogleViz.cell( o.name ) );  
            rr.cells.add ( new GoogleViz.cell( o.billingstreet ) );
            gv.addRow( rr );   
        }     
        string ret =  gv.toJsonString();
        return escapeQuote(ret); 
    }
    
    
    public string getdataTable() { 
        GoogleViz gv = new GoogleViz();
        gv.cols = new list<GoogleViz.col> { 
            new GoogleViz.Col('A','Id','t'),
            new GoogleViz.Col('B','Name','t') 
         
             };
    
        list<account> accs = (list<account>) controller.getRecords();
        
        for( Account  o:accs) { 
            googleViz.row rr = new googleViz.row();
            rr.cells.add ( new GoogleViz.cell( o.id ) );
            rr.cells.add ( new GoogleViz.cell( o.name ) );  
       
            gv.addRow( rr );   
        }     
        string ret =  gv.toJsonString();
        return escapeQuote(ret); 
    }
    
    public string escapeQuote(string s ) { return s.replace('\'',  '\\\'');}
    public string forcekey { get { return geoApiKey.forcekey; }}
    Account nearest = null;
    public pagereference selected2() {
    	// set the account detail from the placemark click
    	
        system.assert( location != null );
        system.debug('selected:' + location);
        string[] ll = location.split(',');
        system.debug( accs.size() );
        // the lat , lon we get is not exactly where the 
        // placemark was, but close, so we need to calc 
        // the nearest placemark by looking at the distance x squared + y squared
         
        decimal nearestdistance = 100000;
        for( Account  o:accs) { 
        	//system.debug( ll);
            try { 
            	decimal tmp = math.abs( o.lat__c - double.valueof(ll[0]) );
	            tmp += math.abs( o.lon__c - double.valueof(ll[1]) );
	            if ( tmp < nearestdistance ) { 
	            	nearestdistance = tmp;
	                nearest = o;
	            }
            } catch ( exception e) {
            }
        }
        system.debug( 'nearest  is :' +nearest );
        return null; 	
    }
    
   // public string placeid { get { return [select id from account limit 1].id; }}
    public Account detailAccount { get { return nearest; } }
    public string location { get; set; }
    public string signature { get { return string.valueof( System.now().gettime()); } }   
}
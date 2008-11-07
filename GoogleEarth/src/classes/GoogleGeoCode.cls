/*
Copyright (c) 2008 salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

global class GoogleGeoCode {

    public GoogleGeoCode(ApexPages.StandardController controller) {

    }

    /*
    Geocoding via HTTP

You may also access the Maps API geocoder directly using server-side scripting. 
This method is not recommended over using the client-side geocoder; however, it is useful for debugging purposes 
or for cases where a JavaScript GClientGeocoder object is not available.

To access the Maps API Geocoder, send a request to http://maps.google.com/maps/geo? with the following parameters in the URI:

    * q (required) — The address that you want to geocode.
    * key (required) — Your API key.
    * output (required) — The format in which the output should be generated. The options are xml, kml, csv, or (default) json.
    * ll (optional) — The {latitude,longitude} of the viewport center expressed as a comma-separated string (e.g. "ll=40.479581,-117.773438" ). This parameter only has meaning if the spn parameter is also passed to the geocoder.
    * spn (optional) — The "span" of the viewport expressed as a comma-separated string of {latitude,longitude} (e.g. "spn=11.1873,22.5" ). This parameter only has meaning if the ll parameter is also passed to the geocoder.
    * gl (optional) — The country code, specified as a ccTLD ("top-level domain") two-character value.

Note: The gl and spn,ll viewport parameters will only influence, not fully restrict, results from the geocoder.

In this example, we request the geographic coordinates of Google's headquarters:

http://maps.google.com/maps/geo?q=1600+Amphitheatre+Parkway,+Mountain+View,+CA&output=xml&key=abcdefg

If you specify json as the output, the response is formatted as a JSON object. If you specify xml or kml, the response is returned in KML. The XML and KML outputs are identical except for the MIME types.

    */
    public static integer debug = 1;
    
    private static final map<string,string> config = new map<string, string>();
   
    private static final string serviceUrl = 'http://maps.google.com/maps/geo?key=' + geoApiKey.key;
    
    @future (callout=true)
    public static void geocodeAccount( list<string> accids ) { 
    
        // fetch the address from this account(s) 
        account[] al = [ select id, name, billingstreet,billingcity,
        	billingState,billingpostalcode from account where id in :accids];
         
        // store the resulting lat-lon in the accounts
        for ( Account a: al) { 
            string adr = a.billingstreet + ',' + a.billingcity + ',' + a.billingstate; 
            if ( a.billingpostalcode != null ) 
                adr += ',' + a.billingpostalcode; 
            
            xmldom dom = geocode(adr); 
            processGeocodeDom ( dom , a);
        }
        update al;
    }
    
    /* given a DOM, look at the code and store the values or error found */
    public static void processGeocodeDom( xmldom dom, Account a ) {
    	if (dom != null) {
            if ( dom.root.getValue('code') == '200' )  {
                string[] lat_lon = dom.root.getValue('coordinates' ).split(',');
                a.lat__c = Double.valueOf(lat_lon[1]); 
                a.lon__c = Double.valueOf(lat_lon[0]);  
                a.geocode_status__c = 'G_GEO_SUCCESS';
            } else { 
                a.lat__c = 0.0; a.lon__c = 0.0;
                a.geocode_status__c = geo_response.get( dom.root.getValue('code') )
                 + ' ('+ dom.root.getValue('code') + ')';
            }     
   		}
    }
    
    public static void geocodeOneAccount(string accountid) {
       account a = [ select id, name , 
            billingstreet,billingcity,billingState,billingpostalcode 
            from account where id = :accountid limit 1];    	
    	
        string adr = a.billingstreet + ',' + a.billingcity + ',' + a.billingstate; 
        if ( a.billingpostalcode != null ) 
            adr += ',' + a.billingpostalcode; 
            
        xmldom dom = geocode(adr); 
        processGeocodeDom ( dom , a);
        
        if ( dom != null ) {
	    	update a;	
    	}

    }
    static Map<String, String> geo_response = new Map<String, String>{'200'=>'G_GEO_SUCCESS',
    '400'=>'G_GEO_BAD_REQUEST',
    '500'=>'G_GEO_SERVER_ERROR',
    '601'=>'G_GEO_MISSING_ADDRESS',
    '602'=>'G_GEO_UNKNOWN_ADDRESS',
    '603'=>'G_GEO_UNAVAILABLE_ADDRESS',
    '604'=>'G_GEO_UNKNOWN_DIRECTIONS',
    '610'=>'G_GEO_BAD_KEY',
    '620'=>'G_GEO_TOO_MANY_QUERIES'
    };
        
    /* the call may return one of these  Constants
    Constants   Description
    G_GEO_SUCCESS (200)     No errors occurred; the address was successfully parsed and its geocode has been returned. (Since 2.55)
    G_GEO_BAD_REQUEST (400)     A directions request could not be successfully parsed. (Since 2.81)
    G_GEO_SERVER_ERROR (500)    A geocoding or directions request could not be successfully processed, yet the exact reason for the failure is not known. (Since 2.55)
    G_GEO_MISSING_QUERY (601)   The HTTP q parameter was either missing or had no value. For geocoding requests, this means that an empty address was specified as input. For directions requests, this means that no query was specified in the input. (Since 2.81)
    G_GEO_MISSING_ADDRESS (601)     Synonym for G_GEO_MISSING_QUERY. (Since 2.55)
    G_GEO_UNKNOWN_ADDRESS (602)     No corresponding geographic location could be found for the specified address. This may be due to the fact that the address is relatively new, or it may be incorrect. (Since 2.55)
    G_GEO_UNAVAILABLE_ADDRESS (603)     The geocode for the given address or the route for the given directions query cannot be returned due to legal or contractual reasons. (Since 2.55)
    G_GEO_UNKNOWN_DIRECTIONS (604)  The GDirections object could not compute directions between the points mentioned in the query. This is usually because there is no route available between the two points, or because we do not have data for routing in that region. (Since 2.81)
    G_GEO_BAD_KEY (610)     The given key is either invalid or does not match the domain for which it was given. (Since 2.55)
    G_GEO_TOO_MANY_QUERIES (620)    The given key has gone over the requests limit in the 24 hour period. (Since 2.55)
    */
    public static xmldom geocode( string addr ) { 
        HttpRequest req = new HttpRequest();   
        string url = GoogleGeoCode.serviceUrl + '&output=xml&q=' + EncodingUtil.urlEncode(addr,'UTF-8');
        system.debug ( 'url is ' +url );
        req.setEndpoint( url );
        req.setMethod('GET');
        
        xmldom dom = null;
        try {
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            if (response.getStatusCode() != 200 ) {
                dumpResponse ( response);
            } else {
                dom = new xmldom( response.getBody() );
            } 
        } catch( System.Exception e) {
            System.debug('ERROR: '+ e);
        }  
        
        if ( googleGeoCode.debug > 0 && dom != null ) { 
        	dom.dumpAll(); 
        } 
        return dom;
    }
    
    private static void dumpResponse(HttpResponse response) { 
        system.debug('GEOCODE ERROR: Could not parse or locate address'); 
        System.debug('STATUS:'+response.getStatus());
        System.debug('STATUS_CODE:'+response.getStatusCode());
        System.debug('BODY: '+response.getBody());
        xmldom dom = new xmldom( response.getBody() );
        dom.dumpAll();
    }

    webService static void go( string accid ) {
        geocodeOneAccount( accid );
    } 
    
    /* Test methods below here 
    
     */ 
    public static  testmethod void t1() {
        string test_resp = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Response><name>Elm St. Chico CA null</name><Status><code>602</code><request>geocode</request></Status></Response></kml>';
    
        system.assert( geoApiKey.key != null, 'missing API key config setting ');
        system.debug( geoApiKey.key );
        
        Account a =  new Account(name='foo');
        a.billingstreet = '1600 Amphitheatre Parkway';
        a.billingcity = 'Mountain View';
        a.billingState = 'CA';
        a.billingCountry = 'USA';
        try { insert a; } catch ( system.dmlexception de) {}
        
        googlegeocode.geocodeOneAccount( a.id );
        
      //  googlegeocode.dumpResponse( new HttpResponse() );
    }
    
    public static  testmethod void t2() {   
        Account a = [ select id, name , 
            billingstreet,billingcity,billingState,billingpostalcode 
            from account limit 1];
        a.billingstreet = '1600 Amphitheatre Parkway';
        a.billingcity = 'Mountain View';
        a.billingState = 'CA';
        try { update a; } catch ( system.dmlexception de) {}
    }
    
    
    public static testmethod void testgeocode() { 
        
        xmldom dom = GoogleGeoCode.geocode('1600 Amphitheatre Parkway, Mountain View, CA');     
	
		if ( dom == null ) { 
			// when testing, dom is null here, fill it in with a valid dom.
			return;
		}
        system.debug( dom.toXmlString() );
        system.assert ( dom.root.getValue('code') == '200' , ' bad return code getValue() ');
        
        system.debug(  dom.root.getValue('coordinates' ));
        string[] lat_lon = dom.root.getValue('coordinates' ).split(',');
        system.debug( lat_lon );
        
        // we expect a 602 here
        dom = GoogleGeoCode.geocode('1600 a Parkway,  View, GA');
        system.debug ( 'code is '   +dom.root.getValue('code'));
        system.assert ( dom.root.getValue('code') == '602' , ' unexpected return code');
        
    }
    
    public static testmethod void t3() { 
    	string test_resp = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Response><name>Elm St. Chico CA null</name><Status><code>602</code><request>geocode</request></Status></Response></kml>';
    	string test_resp2 = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0" ><Response ><name >1600 Amphitheatre Parkway, Mountain View, CA</name><Status ><code >200</code><request >geocode</request></Status><Placemark id="p1" ><address >1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA</address><Point ><coordinates >-122.085121,37.423088,0</coordinates></Point></Placemark></Response></kml>';
    	Account a = new Account() ; 
    	GoogleGeoCode.processGeocodeDom( new xmldom( test_resp) ,a);  
    	GoogleGeoCode.processGeocodeDom( new xmldom( test_resp2) ,a);  
    }
}
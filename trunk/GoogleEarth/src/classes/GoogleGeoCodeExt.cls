/* simple example of using a visualforce page to run a geocode on one account */

public class GoogleGeoCodeExt {
    Account a;
    public GoogleGeoCodeExt(ApexPages.StandardController controller) {
        a = (Account)controller.getRecord();
    }
    public PageReference doGeoCode() {
    	system.assert( a.id != null ,'No account id specified, cannot geo code');
    	googleGeocode.go( a.id );
        
        PageReference secondPage = new PageReference( '/' + a.id);
        secondPage.setRedirect(true); 
        return secondPage;
    }
    
    public static testmethod void t1 () { 
    	Account ac = new Account( name='foo');
    	insert ac;
    	GoogleGeoCodeExt ge = new GoogleGeoCodeExt( new ApexPages.StandardController( ac) );
    	ge.doGeoCode();
    }
    
    
}
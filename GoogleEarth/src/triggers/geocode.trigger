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
/* 
 * trigger on a changed or new account address 
 *   if the data is available, add to a list of accounts 
 *   that will be geocoded.
 */
trigger geocode on Account (after insert, after update) {
	string[] todo = new string[]{};

	if (Trigger.isInsert) {
		for ( Account newa: Trigger.new) {
			if ( newa.billingstreet != null &&
				newa.billingCity != null &&
				newa.billingstate != null 	) {
					
				todo.add((string)newa.id);
			}
		}
	}
	
	if (Trigger.isUpdate) {
		for ( Account newa: Trigger.new) {
			Account olda = Trigger.oldMap.get(newa.id);
			if ( newa.billingstreet != olda.billingStreet ||
				newa.billingCity != olda.billingCity || 
				newa.billingstate != olda.billingstate ||
				newa.billingpostalcode != olda.billingpostalCode 
				
				) {
				todo.add((string)newa.id);	
			}
		}	
	}
   
   	if ( todo.size() > 0 && todo.size() <= 10 ) {  // avoid call out limit
   		googleGeoCode.geocodeAccount( todo ); 
   	} 
}
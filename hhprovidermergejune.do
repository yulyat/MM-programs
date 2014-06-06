
* this do file takes household survey data and merges with provider assigment data based on unique provider id


** 1.0 directory set up **
**********************

global y_root `"/Users/truskinovsky/Documents/Manoj/follow up hh survey/data"'
global kd_root `"/Users/truskinovsky/Dropbox/Karnataka/Household Questionnaire/Data"'
global sh_root `"/Users/truskinovsky/Dropbox/Karnataka Providers Incentives Experiment"'

** raw datasets for this do file **
***********************************

* household survey data, 4_29

global hhold1 `"$kd_root/Household Data 04-29-2014 v12.dta"'
global hhold3SC `"$y_root/2456 III MAIN SURVEY DEIDENTIFIED DATA.DTA"'
global hhold3 `"$y_root/2456 III main survey deidentified dataYT.dta"'  /* created lower case version of hh3SC which was sent to us in upper case */

* provider data with treatment assignment

global provider `"$sh_root/Provider Details with Assignments/175 Providers status cluster details.xls"'

** output data created by this merge **
***************************************

global provider4merge  `"$y_root/175 Providers status cluster details.dta"'
global hh_merge  `"$y_root/inproghousehold.dta"'
global hh_merge5_12_14  `"$y_root/inproghousehold5_12_14.dta"'
global hhprov_merge  `"$y_root/inproghouseholdmerge.dta"'

 ** log files **
 ***************

global hhmergelog `"$y_root/logs/hhmergelog `c(current_date).smcl'"'



** start log **
***************
capture log close
log using "$hhmergelog", replace



** 2.0 hh append separate batches of household data and check for data quality issues **
****************************************************************************************

clear 
use "$hhold3SC"

* replace caps with lowercase: *

rename *, l 

save "$hhold3", replace

clear 
use "$hhold1"
append using "$hhold3"    



save "$hh_merge", replace
save "$hh_merge5_12_14", replace
count



**2.5 addressing data issues re Anil email 6-01 "questions from latest IMACHINE data transfer":

/*
 
Wrong ID                               Corrected ID                                       Date of Delivery                                 Date of Interview
  AWW0855001                      AWW0855002                                   11/04/2014                                          15/4/2014
  PM15105202                          PA15105202                                     8/4/2014                                              21/04/2014

*/


replace r_id = "AWW0855002" if r_id == "AWW0855001" & q111add == 11 & q111amm == 4 & q111ayy == 2014
replace r_id = "PA15105202" if r_id == "PM15105202" & q111add == 8 & q111amm == 4 & q111ayy == 2014




	* r_id is unique id?

	isid r_id
    
   

** 3.0 hh and provider data merge: delivery provider**
************************************

set more off
clear
use "$hhold_merge"

tab q113 q09b2 
*  2,361 women identified using patient list. of those, 2 report delivering at home, 
cap drop check 
gen check = 1 if q09b2 == 1 &  q113 == 1

list r_id if check ==1 
list r_id q113e q303e q1304ee if check ==1

tab q09b2 q09c2
* 2 deliveries identified neither by patient or population listing
cap drop check2 
gen check2 = 1 if q09b2  == 2 &  q09c2  == 2
tab q113 if check2 == 1
list r_id q113 q09b2 q09c2 if check2 == 1 
/* based on r_id, looks like a typo */
/*
correction

 
     |        r_id       q113 |       Identified in patient list        Identified in population list
      |------------------------|------------------------------------------------------------------------
4733. | PF240411024   pvt. hos |                1                                 2
5945. |  POP1490320   pvt. hos |                2                                 1   
*/

replace q09b2 = 1 if r_id == "PF240411024"
replace q09c2 = 1 if r_id == "POP1490320"

tab q09b2 q09c2


* ANC care:
***********
* is the ANC provider in the study? q303d 
* ANC proivder code : q303e
*  if identified by patient list and have provider code, same ANC provider?
tab q303e q09b2
count if (q303e == q113e) & txprovdeliver == 1
tab q303e q09b2 if (q303e == q113e) & !mi(q303e)

* follow up care: 
* get follow up care at a study provider: q1304ee

tab q1304ee q09b2
count if (q1304ee == q113e) & txprovdeliver == 1
tab q1304ee q09b2 if (q1304ee == q113e) & !mi(q1304ee)


* all 3: 
count if (q303e == q1304ee == q113e)  
* delivery and ANC :

tab q303e, m
gen ANC = 1 if !mi(q303e) & q303e > 0


tab q113e
gen DEL = 1 if !mi(q113e) & q113e > 0



** 4.0: merging with provider info: **
**************************************

** 4.1 merge on delivery provider: 

* import  provider assignments
clear
import excel "$provider", sheet("175 PROVIDERS") firstrow
sort U_ID
save "$provider4merge", replace

** create unique provider ID using q113e = where delivered

clear 
use "$hh_merge"
cap drop U_ID
gen U_ID = q113e 
sort U_ID
save "$hh_merge", replace 


* merge 
merge m:1 U_ID using "$provider4merge", update replace

* 16 women are not matched to a provider, and 33 providers don't have any women matched to them 
* who are the 16 women who are not matched:
list r_id U_ID q09b2 if _merge == 1, noobs

* number of women per provider: 
cap drop provdeliveries
bysort U_ID: gen provdeliveries= _N if (_merge == 3 & !mi(U_ID))

** 4.2 merge on ANC provider
clear 
use "$hh_merge"
cap drop U_ID
gen U_ID = q303e
sort U_ID

merge m:1 U_ID using "$provider4merge", update replace

* 50 women are not matched to a provider [but have a value for 303e], 34 providers have no ANCE women
list r_id U_ID q09b2 if _merge == 1

** 4.3 Merge on postnatal care provider code:

clear 
use "$hh_merge"
cap drop U_ID
gen U_ID = q1304ee 
sort U_ID
merge m:1 U_ID using "$provider4merge", update replace
list r_id U_ID q09b2  if _merge == 1, noobs

* 77 providers have no post natal care women, and 7 women have a provider number that doesn't match to a provider. 
* of the 7, 6 were identified using the patient list



save "$hhprov_merge", replace


clear 
use "$hhprov_merge"

* generate treatment type variable to identify control area respondents. 

	codebook  TypeofAgreement

	gen txtype = TypeofAgreement
	label define TXTYPE_LABEL 1 "input" 2 "output" 3 "control"
	label values txtype TXTYPE_LABEL
	tab txtype, m


	gen txtype_input = (txtype==1) if !mi(txtype)
	tab  txtype_input

	gen txtype_output = (txtype==2) if !mi(txtype)
	tab  txtype_output


	gen txtype_control = (txtype==3) if !mi(txtype)
	tab  txtype_control
		
* generate how identified variable 

gen pat_id= q09b2 == 1 if !mi(q09b2)
gen pop_id= q09c2 == 1 if !mi(q09c2)




save "$hh_merge", replace 


* institutional, vaginal
tab q113 q114 if q113 > 2 & !mi(q113) & q114 != 3 
count if q113 > 2 & !mi(q113) & q114 != 3
di r(N)/9590 



* home, assisted 
tab q113 q114 if q113 < 3 & !mi(q113) & q114 == 1
count if q113 < 3 & !mi(q113) & q114 == 1
di r(N)/9590 




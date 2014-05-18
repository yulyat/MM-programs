
* this do file takes household survey data and merges with provider assigment data based on unique provider id


** 1.0 directory set up **
**********************

global y_root `"/Users/truskinovsky/Documents/Manoj/follow up hh survey/data"'
global kd_root `"/Users/truskinovsky/Dropbox/Karnataka/Household Questionnaire/Data"'
global sh_root `"/Users/truskinovsky/Dropbox/Karnataka Providers Incentives Experiment"'

** raw datasets for this do file **
***********************************

* household survey data, 4_29

global hhold `"$kd_root/Household Data 04-29-2014 v12.dta"'

* provider data with treatment assignment

global provider `"$sh_root/Provider Details with Assignments/175 Providers status cluster details.xls"'

** output data created by this merge **
***************************************

global provider4merge  `"$y_root/175 Providers status cluster details.dta"'
global hh_merge  `"$y_root/Household Data 04-29-2014 v12.dta"'


** 2.0 hh and provider data merge: delivery provider**
************************************

set more off
clear
use "$hhold"

tab q113 q09b2 
*  1,763 women identified using patient list. of those, 2 report delivering at home, 
* and on reports delivering in a governemnt hospital 

tab q09b2 q09c2

* 2 deliveries identified neither by patient or population listing
gen check = 1 if q09b2 == 2 &  q09c2 == 2
tab q113 if check == 1
list r_id if check == 1 /* based on r_id, looks like a typo */




* generate variable who delivered at one of out providers and were identified via patient list (1) or population list (2)
cap drop txprovdeliver
gen txprovdeliver = 1 if q113e > 100 & !mi(q113e) & q09b2 == 1
replace txprovdeliver = 2 if q113e > 100 & !mi(q113e) & q09c2 == 1

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


** create unique provider ID using q113e = where delivered
gen U_ID = q113e 
sort U_ID
save "$hh_merge", replace 

* import  provider assignments
clear
import excel "$provider", sheet("175 PROVIDERS") firstrow
sort U_ID
save "$provider4merge", replace

* merge 
clear 
use "$hh_merge"
merge m:1 U_ID using "$provider4merge", update replace
save "$hh_merge", replace


clear 
use "$hh_merge"

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










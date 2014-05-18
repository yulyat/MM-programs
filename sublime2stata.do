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
global hhold3 `"$y_root/2456 III main survey deidentified dataYT.dta"'

* provider data with treatment assignment

global provider `"$sh_root/Provider Details with Assignments/175 Providers status cluster details.xls"'

** output data created by this merge **
***************************************

global provider4merge  `"$y_root/175 Providers status cluster details.dta"'
global hh_merge  `"$y_root/inproghousehold.dta"'
global hhprov_merge  `"$y_root/inproghouseholdmerge.dta"'

 ** log files **
 ***************

global hhmergelog `"$y_root/logs/hhmergelog`c(current_date).smcl'"'



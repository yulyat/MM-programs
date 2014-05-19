

* this do file takes household survey data and merges with provider assigment data based on unique provider id


** 1.0 directory set up **
**********************

global y_root `"/Users/truskinovsky/Documents/manoj/follow up hh survey/data"'
global kd_root `"/Users/truskinovsky/Dropbox/Karnataka/Household questionnaire/Data"'
global sh_root `"/Users/truskinovsky/Dropbox/Karnataka Providers Incentives Experiment"'

** raw datasets for this do file **
***********************************

* household survey data, 4_29

global hhold `"$kd_root/Household Data 04-29-2014 v12.dta"'

* provider data with treatment assignment

global provider `"$sh_root/Provider Details with assignments/175 Providers status cluster details.xls"'

** output data created by this merge **
***************************************

global provider4merge  `"$y_root/175 Providers status cluster details.dta"'
global hh_merge  `"$y_root/Household Data 04-29-2014 v12.dta"'


set more off
clear 
use "$hh_merge"
keep if txtype_control == 1



************************************
***Section A: Pregnancy care (ANC)
***********************************

	*** A.1 monitoring progress and assessment of maternal and fetal wellbeing ***
	
    ** q301 - see any healthcare worker for checkup?
    ** q304 - months pregnant when recieved first checkup - < 5 == 1, > 5 == 0
    ** q305 - how many times checked during pregnancy? > 3 == 1, < 3 == 0

		
		gen q301input = q301 == 1 if !missing(q301)
		replace q301input = . if q301 == 88 /* 2 observations are missing a value here */

		gen q304input = q304 < 5 if !missing(q304) /* 1 if less than 5 months, 0 otherwise*/
		replace q304input = . if q304 == 88
		
		gen q305input = q305 > 3 if !missing(q305)
		replace q305input = . if q305 == 88
		
    **a.1 subsection score:
		
		egen a1 = rowmean(q301input q304input q305input)


	*** a.2 detection of problems ***

    **q306  - detection of problems during pregnancy: > 3/6 == 1 otherwise 0
    **q306b - weight
    **q306c - bloodpressure
    **q306d - urine test
    **q306e - blood test
    **q306f - abdominal internal vaginal
    **q306h - ultrasound sonogram

		local test q306b q306c q306d q306e q306f q306h q306i

		foreach var of local test {
			gen `var'test = `var' == 1 if !missing(`var')
			replace `var'test = . if `var' == 88
		}

    **a.2 subsection score:		

    	cap drop a2
		egen a2 = rowmean(*test)
		

	*** a.3 tetanus immunizations, anemia etc:  ***

** q313 - give injection to prevent tetnus 1 - yes 0 - no
** q314 - consume iron tablets or syrup  1 - yes 0 - no
** q315 - information and counseling on self care at home

		local a3 q313 q314 q315 
		foreach var of local a3 {
			gen `var'input = `var' == 1 if !missing(`var')
			replace `var'input = . if `var' == 88
		}

*** score for a.3
		cap drop a3
		egen a3 = rowmean(q313input q314input q315input)

	
		*** a.4 info and counseling on self care at home, nutrition, safer sex, breastfeeding, etc
** q307 - told about mental problems one may face during pregnancy - DROPPED 5/12
** q308 - guidance about food
** q309 - guidance about breastfeeding
** q310 - guidance about family planning


		local advice q308 q309 q310 
		foreach var of local advice {
					gen `var'input = `var' == 1 if !missing(`var')
					replace `var'input = . if `var' == 88
				}

		cap drop a4
		egen a4 = rowmean(q308input q309input q310input)

		tab q308input, m
		tab q309input, m
		tab q310input, m

		*** a.5  birth planning, advice on danger signs and emergency preparedness 

** q311 guidance about birth planning
** q312 advice on danger signs and prepardness

		local advice q311 q312
		foreach var of local advice {
					gen `var'input = `var' == 1 if !missing(`var')
					replace `var'input = . if `var' == 88
				}

** score for a.5:
		cap drop a5 
		egen a5 = rowmean( q311input q312input)

		sum a*
/*

  Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
          a1 |      3442    .7981309    .3763686          0          1
          a2 |      2877    .9335452     .120258          0          1
          a3 |      3438    .9003297    .2320125          0          1
          a4 |      2876    .5281351    .3177562          0          1
          a5 |      2874    .4556367    .4303544          0          1
*/		

****calculate average score for section a: pregnancy care for each observation - ///
****if missing, the observation is not included in the average
***the resulting 0 entries are the ones who had no aNc care
		
		cap drop scoreA
		egen scoreA = rowmean(a1 a2 a3 a4 a5)
		replace scoreA = round(scoreA, .1)
		sum scoreA
/*
   Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
     scorea |      3442    .6983149    .2132696          0          1
*/

******************************
***Section B: childbirth care
******************************

	***care during labor and delivery
	
	*** B.1 diagnosis of labor *** 

** q402 - Type of respondent - for reference here 
** q404 - upon arrival, asked about details of pain, etc

		local care q404  

		foreach var of local care {
		egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
		gen `var'input = `var'merge == 1 if !missing(`var'merge) & q402 != 4
		replace `var'input = . if `var'merge == 88
		}

** score for b.1: 
		cap drop b1
		gen b1 = q404input

	*** b.2 monitoring profress of labor, maternal and fetal well being  *** 

** q405 - asked about baby movement at time of arrival
** q413 - check baby heartrate 
** q416 - PV done at time of arrival?
** q419 - encouraged to bear down?

/* note: some question have both mother and accompagning person response, 
	and some only have mother response */

		local care  q405 q413 q416 

		foreach var of local care {
		egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
		gen `var'input = `var'merge == 1 if !missing(`var'merge) & q402 != 4
		replace `var'input = . if `var'merge == 88
		}

** score for b.2: 
		cap drop b2
		egen b2 = rowmean(q405input q413input q416input)
		tab b2, m 

    *** b.3 providing supportive care and pain relief ***

** q419 encouraged to bear down? - has both respondent and attendent person response:

		local care q419

		foreach var of local care {
		egen `var'mmerge = rowtotal(`var'a_m `var'b_m `var'c_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'b_a `var'c_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

** score for b.3: 
		cap drop b3
		egen b3 = rowmean(q419input)
		tab b3, m 


	** b.4 detection of problems and complications **

***q407 asked about previous deliveries?
***q408 asked if you have hypertension
***q409 asked if you are diabetic
***q410 asked if you have hypothyroidism
***q411 aksed if you have asthma
***q412 bP checked at time of arrival?
***q414 anemia test done at time of arrival
***q415 per abdomen test at time of arrival


		local problems q407 q408 q409 q410 q411 q412 q414 q415

		foreach var of local problems {
				egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) & q402 != 4
				replace `var'input = . if `var'merge == 88
				}

		cap drop b4
		egen b4 = rowmean(q407input q408input q409input q410input q411input q412input q414input q415input)
		tab b4, m


***b.5 delivery and immediate care of the newborn baby, initiation of breastfeeding

	** q502 was the baby dried immediately after birth?
	** q503 was the baby wrapped in new clothes?
	** q504 baby's head covered?
	** q505 baby given for skin to skin contact?
	** q506 baby heartrate checked

	** q507 counseled to start breastfeeding immediately
	** q508 how long after birth started breastfeeding?
	** q510 baby weighted at birth
	** q511 baby naked when it was weighted



		local b3 q502 q503 q504 q505 q506 q507  q510 q511

		foreach var of local b3 {
		egen `var'mmerge = rowtotal(`var'a_m `var'b_m `var'c_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'b_a `var'c_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

		local hours q508

		foreach var of local hours {
		egen `var'mmerge = rowtotal(`var'a_m1 `var'b_m1 `var'c_m1) , m
		egen `var'amerge = rowtotal(`var'a_a1 `var'b_a1 `var'c_a1) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

		local day q508

		foreach var of local day {
		gen `var'2input = `var'mmerge <3 if !missing(`var'mmerge) & q402 != 4
		replace `var'2input = . if `var'mmerge == 88
		replace `var'2input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

		cap drop b5
		egen b5 = rowmean(q502input q503input q504input q505input q506input q507input q508input q510input q511input)
		



*** b.6 active management of third stage of labor

***q423 Press on abdomen after delivery
***q424 Placenta delivered on its own
***q605 medicine after delivery to stop bleeding?

		local q423 q423  

		foreach var of local q423 {
		egen `var'mmerge = rowtotal(`var'a_m `var'c_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'c_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4 & q402 != 2
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

		local q424 q424

		foreach var of local q424 {
		egen `var'mmerge = rowtotal(`var'a_m `var'c_m `var'd_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'c_a `var'd_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) &  q402 != 2
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

		local q605 q605

		foreach var of local q605 {
		egen `var'mmerge = rowtotal(`var'a_m `var'b_m `var'c_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'b_a `var'c_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}


		cap drop b6
		egen b6 = rowmean(q423input q424input q605input)
		tab b6, m

	***immediate postnatal care of mother

***b.7 monitoring and assememnt of maternal wellbeing, etc


*** q601 mothers bP checked after delivery
*** q602 Vaginal exam done after delivery
*** q603 episiotomy checked
*** q417 gloves worn during pv exam?


		local q601 q601

		foreach var of local q601 {
		egen `var'mmerge = rowtotal(`var'a_m `var'b_m `var'c_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'b_a `var'c_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}


		local b5 q602 q603


		foreach var of local b5 {
		egen `var'mmerge = rowtotal(`var'a_m `var'c_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'c_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4 & q402 != 2
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

		local b5 q420


		foreach var of local b5 {
		egen `var'mmerge = rowtotal(`var'a_m `var'b_m `var'c_m) , m
		egen `var'amerge = rowtotal(`var'a_a `var'b_a `var'c_a) , m
		gen `var'input = `var'mmerge == 1 if !missing(`var'mmerge) & q402 != 4 & q402 != 2
		replace `var'input = . if `var'mmerge == 88
		replace `var'input = `var'amerge == 1 if `var'mmerge > 2 & `var'amerge < 88
		
		}

		local q417 q417

		foreach var of local q417 {
				egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) & q402 != 4
				replace `var'input = . if `var'merge == 88
				}


		cap drop b7
		egen b7 = rowmean(q601input q602input q603input q417input)
		


***b.8 monitoring and assememnt of maternal wellbeing, etc -DROPPED 5/12
/*
*** q621 dr do anything to stop the bleeding?




		local b6 q621

		foreach var of local b6 {
		egen `var'merge = rowtotal(`var'a1 `var'b1 `var'c1) , m
		gen `var'input = `var'merge == 1 if !missing(`var'merge) & q402 != 4
		replace `var'input = . if `var'merge == 88
		}

		cap drop b8
		gen b8 = q621input
		
*/
****calculate average score for section b: childbirth care for each observation - ///
****if missing, the observation is not included in the average
		sum b* 
/*
		Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
          b1 |      3326    .7814191    .4133457          0          1
          b2 |      3334    .8473805    .2530165          0          1
          b3 |      3332    .6272509    .4836087          0          1
          b4 |      3336    .5455065    .2904358          0          1
          b5 |      3283    .8304454    .1580192          0          1
-------------+--------------------------------------------------------
          b6 |      3399    .5492302    .3671693          0          1
          b7 |      3334    .7327784    .3258505          0          1
          b8 |      3251    .4198708    .4936135          0          1
*/

		cap drop scoreB
		egen scoreB = rowmean(b1 b2 b3 b4 b5 b6 b7)
		replace scoreB = round(scoreB,.1)
		sum scoreB
/*
                sum scoreb

    Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
      scoreb |      3439    .6993603    .1931179          0          1

*/

						*******************************************
						***Section C: postnatal maternal care: ****
						*******************************************

**c1. assessment of maternal wellbeing :

***q1302 medical provider 1 week follow up?


		local q1302 q1302

		foreach var of local q1302 {
				egen `var'merge = rowtotal(`var'a `var'b `var'c `var'd) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		gen c1 = q1302input

**c3. anemia prevention and control 
**c4. information and souseling on nutrition safe sex, fam planning etc

***q802-2,3,4 counseling on diet,  iron and calcium, family planning

		forvalues i= 1/6 {
		
			egen q802merge`i' = rowtotal(q802a_`i' q802b_`i' q802c_`i'), m

		}
/* note that q802 has 55 as response? */ 
/* possible outcomes are 77- other, 88 - dk, 99 - no counseling given */


		forvalues i = 2/4 {
				gen q802input`i' = (q802merge1 == `i'|q802merge2 == `i'|q802merge3 == `i'|q802merge4 == `i'|q802merge5 == `i'|q802merge6 == `i') if !mi(q802merge1) 
				replace q802input`i' = . if q802merge1 == 88
		} 

	gen c3 = q802input3
	egen c4 = rowmean(q802input2 q802input4)

***q807 advised to report immediatelyif you have any of the following: high grade fever, discharge, excessive bleeding, wound gaping, convulsions

		
		forvalues i= 1/5 {
		
			egen q807merge`i' = rowtotal(q807a_`i' q807b_`i' q807c_`i'), m

		}

		forvalues i = 1/5 {
				gen q807input`i' = (q807merge1 == `i'|q807merge2 == `i'|q807merge3 == `i'|q807merge4 == `i'|q807merge5 == `i') if !mi(q807merge1) 
				replace q807input`i' = . if q807merge1 == 99
		} 

	egen c5 = rowmean(q807input*)

/* note, what is 99 coded as here? this question doesn't have and idK option in the survey */

	sum c*
		
*** score for section c:		
/*
Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
          c1 |      3422    .4436002    .4968815          0          1
          c3 |      3312    .5591787    .4965605          0          1
          c4 |      3312     .459692    .3613663          0          1
          c5 |      2099    .5034779    .2353877          0          1
*/

egen scoreC = rowmean(c1 c3 c4 c5)
replace scoreC = round(scoreC, .1)
sum scoreC

/*

    Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
      scorec |      3434    .4777228    .2766923          0          1

*/

						*******************************
						*** Section d Newborn care: ***
						*******************************

** 704 - ask if baby  fed?/
** 803 -  advice on breast feeding/
** 701 baby hR checked during first 12 hours after birth?/
** 702 baby's temp checked?/
** 703 ask about or check urine?/
** 708 baby bathed within 6 hours? - reverse code /
** 701a baby given eyerops/
** 802-1 exclusive breasfeeding/
** 804 advised on breastfeeding vs formula/
*** 802 -5 hygene/
** 802-8 warning signs to take baby to hospital /
** 705 - baby receive any immunizations?/
** 706 which immunizations - follow up --> how to code?

** 806-1 skin to skin of kangaroo care - there are multiple questions  for this/

	
	** d.1 promotion, protections and support for breastfeeding **

		local d1 q704 q803 

		foreach var of local d1 {
			egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}
		
		egen d1 = rowmean(q704input q803input)	

	** d.2 monitoring and assessnebt if wekkbeubgm detection of complications etc ** 

		local d2 q701 q702 q703 

		foreach var of local d2 {
			egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		egen d2 = rowmean(q701input q702input q703input)

	** d.3 infection prevention and controling, rooming in ** 
		
		local d2 q708 

		foreach var of local d2 {
			egen `var'merge = rowtotal(`var'a `var'b `var'c `var'd) , m
			gen `var'input = `var'merge == 2 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		gen d3 = q708input

	** d.4 eye care ** 
		
		local d4  q701a

		foreach var of local d4 {
			egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		gen d4 = q701ainput
	
	** d.5 information with counseling on homecare, breasfeeding, hygiene **
			
		foreach  i in 1 5 8 9 {
			gen q802input`i' = (q802merge1 == `i'|q802merge2 == `i'|q802merge3 == `i'|q802merge4 == `i'|q802merge5 == `i'|q802merge6 == `i') if !mi(q802merge1)
			replace q802input`i' = . if q802merge1 == 88
			} 


		local d5 q804

		foreach var of local d5 {
			egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		egen d5 = rowmean(q802input1 q804input q802input5)

	** d.6 postnatal care planning, advice on danger signs, and emergency prepardness **
		
		gen d6 = q802input8

	** d.7  immunizations according to national guidelines	
	
	** q705 - Did the baby receive any immunizations after birth? 

		local d7 q705
		foreach var of local d7 {
			egen `var'merge = rowtotal(`var'a `var'b `var'c `var'd) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

	** q706 - What immunizations did the baby receive? 	

		forvalues i= 1/4 {
		
			egen q706merge`i' = rowtotal(q706a_`i' q706b_`i' q706c_`i' q706d_`i'), m

		}

		local d7 1 2 3 4 77
		foreach var of local d7 {
			gen q706input`var'= (q706merge1 == `var'|q706merge2 == `var'|q706merge3 == `var'|q706merge4 == `var') if !mi(q705input)
			}
		
		sum q705input q706input* 
		sum q705input q706input* if q706input4 == 0


		gen d7 = (q706input1 == 1 | q706input2 == 1 | q706input3 == 1) if !mi(q705input)

	** d.8 Kangarpp mother care follow-up

		forvalues i= 1/5 {
		
			egen q806merge`i' = rowtotal(q806a_`i' q806b_`i' q806c_`i'), m
		}

		gen q806input = (q806merge1 == 1|q806merge2 == 1|q806merge3 == 1|q806merge4 == 1|q806merge5 == 1) if !mi(q806merge1)
		replace q806input = . if q806merge1 == 88

		egen d8 = rowmean(q806input q802input9)

	** score for section d
		sum d* 

		cap drop scoreD
		egen scoreD = rowmean(d1 d2 d3 d4 d5 d6 d7 d8)
		replace scoreD = round(scoreD, .1)
		sum scoreD 

/*
   Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
          d1 |      3279    .7981092    .3109003          0          1
          d2 |      3244    .7132655    .3370566          0          1
          d3 |      3311    .7725763    .4192318          0          1
-------------+--------------------------------------------------------
          d5 |      3330    .7041542    .2924876          0          1
          d6 |      3312    .1044686    .3059137          0          1
          d7 |      3298    .7744087    .4180345          0          1
          d8 |      3315     .241629     .289087          0          1
          d4 |      2858    .0972708     .296378          0          1



    Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
      scored |      3431    .5239289    .1754839          0          1


      */
				*****************************************
				*** Section e: postnatal Newborn care ***
				*****************************************


** e.1: assessment of infant's wellbeing and breastfeeding **

* 1301 - dr told you cto cbring the child back within 1 week of delivery
* 1302 medical provider check on you and baby after discharge ( aLSO USed iN c!!)

		local e1 q1301 
		foreach var of local e1 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		local e1  q1302
		foreach var of local e1 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'a `var'b `var'c `var'd) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		egen e1 = rowmean(q1301input q1302input)

** e.2 detection of complications and responding to meternal concerns
	* 808 - given a contact number to call in case of emergency/need?
		local e2 q808
		foreach var of local e2 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		gen e2 = q808input
** e.3 information and counseling on home care
	* 805 - dr advise you to keep the baby warm?
		local e3 q805
		foreach var of local e3 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'a `var'b `var'c) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		gen e3 = q805input



		sum e*	


** calcualte total score for section e:
		cap drop scoreE
		egen scoreE = rowmean(e1 e2 e3)
		replace scoreE = round(scoreE, .1)
		sum scoreE


/*
    Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
          e1 |      3429    .4144065    .3827251          0          1
          e2 |      3287    .3821113    .4859775          0          1
          e3 |      3245    .6912173    .4620625          0          1

   Variable |       Obs        mean    Std. dev.       min        max
-------------+--------------------------------------------------------
      scoree |      3433    .4893679    .3147417          0          1

*/

*****generate averages by cluster:

egen pregnancycareA = mean(scoreA) 
egen childbirthcareB = mean(scoreB)
egen PNmaternalcareC = mean(scoreC)
egen newborncareD = mean(scoreD)
egen postnatalcareE = mean(scoreE)

eststo clear
estpost tabstat pregnancycareA childbirthcareB PNmaternalcareC newborncareD postnatalcareE, ///
statistics(mean sd) columns(statistics)
esttab, main(mean) nonote label nogaps compress wide



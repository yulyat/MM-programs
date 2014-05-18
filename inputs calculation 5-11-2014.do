

global y_root `"/Users/truskinovsky/Documents/Manoj/follow up hh survey/data"'
global kd_root `"/Users/truskinovsky/Dropbox/Karnataka/Household Questionnaire/Data/"'
global sh_root 
clear
use "/Users/truskinovsky/Dropbox/Karnataka/Household Questionnaire/Data/Household Data 04-29-2014 v12.dta"
set more off


cd "/Users/truskinovsky/Documents/Manoj/follow up hh survey/data"
save "Household Data 04-29-2014 v12.dta", replace

** create unique provider ID using q09a

clear 
cd "/Users/truskinovsky/Documents/Manoj/follow up hh survey/data"
use "Household Data 04-29-2014 v12.dta"
gen U_ID = q09a 
cd "/Users/truskinovsky/Documents/Manoj/follow up hh survey/data"
save "Household Data 04-29-2014 v12.dta", replace



* import and merge provider assignments
clear
import excel "/Users/truskinovsky/Dropbox/Karnataka Providers Incentives Experiment/Provider Details with Assignments/175 Providers status cluster details.xls", sheet("175 PROVIDERS") firstrow

merge 1:1 U_ID using "/Users/truskinovsky/Documents/Manoj/follow up hh survey/data/Household Data 04-29-2014 v12.dta"


************************************
***Section A: Pregnancy Care (ANC)
***********************************

	*** A.1 Monitoring progress and assessment of maternal and fetal wellbeing ***
	
    **Q301 - see any healthcare worker for checkup?
    **Q304 - Months pregnant when recieved first checkup - < 5 == 1, > 5 == 0
    **Q305 - how many times checked during pregnancy? > 3 == 1, < 3 == 0

		
		gen Q301input = Q301 == 1 if !missing(Q301)
		replace Q301input = . if Q301 == 88 /* 2 observations are missing a value here */

		gen Q304input = Q304 < 5 if !missing(Q304) /* 1 if less than 5 months, 0 otherwise*/
		replace Q304input = . if Q304 == 88
		
		gen Q305input = Q305 > 3 if !missing(Q305)
		replace Q305input = . if Q305 == 88
		
    **A.1 subsection score:
		
		egen a1 = rowmean(Q301input Q304input Q305input)


	*** A.2 detection of problems ***

    **Q306  - detection of problems during pregnancy: > 3/6 == 1 otherwise 0
    **Q306B - weight
    **Q306C - bloodpressure
    **Q306D - urine test
    **Q306E - blood test
    **Q306F - abdominal internal vaginal
    **Q306H - ultrasound sonogram

		local test Q306B Q306C Q306D Q306E Q306F Q306H Q306I

		foreach var of local test {
			gen `var'test = `var' == 1 if !missing(`var')
			replace `var'test = . if `var' == 88
		}

    **A.2 subsection score:		

    	cap drop a2
		egen a2 = rowmean(*test)
		

	*** A.3 tetanus immunizations, anemia etc:  ***

** Q313 - give injection to prevent tetnus 1 - yes 0 - no
** Q314 - consume iron tablets or syrup  1 - yes 0 - no
** Q315 - information and counseling on self care at home

		local a3 Q313 Q314 Q315 
		foreach var of local a3 {
			gen `var'input = `var' == 1 if !missing(`var')
			replace `var'input = . if `var' == 88
		}

*** score for A.3
		cap drop a3
		egen a3 = rowmean(Q313input Q314input Q315input)

	
		*** A.4 info and counseling on self care at home, nutrition, safer sex, breastfeeding, etc
** Q307 - told about mental problems one may face during pregnancy
** Q308 - guidance about food
** Q309 - guidance about breastfeeding
** Q310 - guidance about family planning


		local advice Q307 Q308 Q309 Q310 
		foreach var of local advice {
					gen `var'input = `var' == 1 if !missing(`var')
					replace `var'input = . if `var' == 88
				}

		cap drop a4
		egen a4 = rowmean(Q307input Q308input Q309input Q310input)

		tab Q307input, m 
		tab Q308input, m
		tab Q309input, m
		tab Q310input, m

		*** A.5  Birth planning, advice on danger signs and emergency preparedness 

** Q311 guidance about birth planning
** Q312 advice on danger signs and prepardness

		local advice Q311 Q312
		foreach var of local advice {
					gen `var'input = `var' == 1 if !missing(`var')
					replace `var'input = . if `var' == 88
				}

** score for A.5:
		cap drop a5 
		egen a5 = rowmean( Q311input Q312input)
/*

  Variable |       Obs        Mean    Std. Dev.       Min        Max
-------------+--------------------------------------------------------
          a1 |      3442    .7981309    .3763686          0          1
          a2 |      2877    .9335452     .120258          0          1
          a3 |      3438    .9003297    .2320125          0          1
          a4 |      2876    .5281351    .3177562          0          1
          a5 |      2874    .4556367    .4303544          0          1
*/		

****calculate average score for section A: pregnancy care for each observation - ///
****if missing, the observation is not included in the average
***the resulting 0 entries are the ones who had no ANC care
		
		cap drop scoreA
		egen scoreA = rowmean(a1 a2 a3 a4 a5)
		replace scoreA = round(scoreA, .1)
		
/*
   Variable |       Obs        Mean    Std. Dev.       Min        Max
-------------+--------------------------------------------------------
     scoreA |      3442    .6983149    .2132696          0          1
*/

******************************
***Section B: Childbirth Care
******************************

	***Care during labor and delivery
	
	*** B.1 Diagnosis of labor *** 

** Q402 - Type of respondent - for reference here 
** Q404 - upon arrival, asked about details of pain, etc

		local care Q404  

		foreach var of local care {
		egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
		gen `var'input = `var'merge == 1 if !missing(`var'merge) & Q402 != 4
		replace `var'input = . if `var'merge == 88
		}

** score for B.1: 
		cap drop b1
		gen b1 = Q404input

	*** B.2 Monitoring profress of labor, maternal and fetal well being  *** 

** Q405 - asked about baby movement at time of arrival
** Q413 - check baby heartrate 
** Q416 - PV done at time of arrival?
** Q419 - Encouraged to bear down?

/* note: some question have both mother and accompagning person response, 
	and some only have mother response */

		local care  Q405 Q413 Q416 

		foreach var of local care {
		egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
		gen `var'input = `var'merge == 1 if !missing(`var'merge) & Q402 != 4
		replace `var'input = . if `var'merge == 88
		}

** score for B.2: 
		cap drop b2
		egen b2 = rowmean(Q405input Q413input Q416input)
		tab b2, m 

    *** B.3 providing supportive care and pain relief ***

** Q419 Encouraged to bear down? - has both respondent and attendent person response:

		local care Q419

		foreach var of local care {
		egen `var'Mmerge = rowtotal(`var'A_M `var'B_M `var'C_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'B_A `var'C_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

** score for B.3: 
		cap drop b3
		egen b3 = rowmean(Q419input)
		tab b3, m 


	** B.4 Detection of problems and complications **

***Q407 asked about previous deliveries?
***Q408 Asked if you have hypertension
***Q409 asked if you are diabetic
***Q410 asked if you have hypothyroidism
***Q411 aksed if you have asthma
***Q412 BP checked at time of arrival?
***Q414 Anemia test done at time of arrival
***Q415 per abdomen test at time of arrival


		local problems Q407 Q408 Q409 Q410 Q411 Q412 Q414 Q415

		foreach var of local problems {
				egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) & Q402 != 4
				replace `var'input = . if `var'merge == 88
				}

		cap drop b4
		egen b4 = rowmean(Q407input Q408input Q409input Q410input Q411input Q412input Q414input Q415input)
		tab b4, m


***B.5 Delivery and immediate care of the newborn baby, initiation of breastfeeding

	** Q502 was the baby dried immediately after birth?
	** Q503 was the baby wrapped in new clothes?
	** Q504 Baby's head covered?
	** Q505 Baby given for skin to skin contact?
	** Q506 Baby heartrate checked

	** Q507 counseled to start breastfeeding immediately
	** Q508 how long after birth started breastfeeding?
	** Q510 Baby weighted at birth
	** Q511 Baby naked when it was weighted



		local b3 Q502 Q503 Q504 Q505 Q506 Q507  Q510 Q511

		foreach var of local b3 {
		egen `var'Mmerge = rowtotal(`var'A_M `var'B_M `var'C_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'B_A `var'C_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

		local hours Q508

		foreach var of local hours {
		egen `var'Mmerge = rowtotal(`var'A_M1 `var'B_M1 `var'C_M1) , m
		egen `var'Amerge = rowtotal(`var'A_A1 `var'B_A1 `var'C_A1) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

		local day Q508

		foreach var of local day {
		gen `var'2input = `var'Mmerge <3 if !missing(`var'Mmerge) & Q402 != 4
		replace `var'2input = . if `var'Mmerge == 88
		replace `var'2input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

		cap drop b5
		egen b5 = rowmean(Q502input Q503input Q504input Q505input Q506input Q507input Q508input Q510input Q511input)
		



*** B.6 active management of third stage of labor

***Q423 Press on abdomen after delivery
***Q424 Placenta delivered on its own
***Q605 medicine after delivery to stop bleeding?

		local Q423 Q423  

		foreach var of local Q423 {
		egen `var'Mmerge = rowtotal(`var'A_M `var'C_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'C_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4 & Q402 != 2
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

		local Q424 Q424

		foreach var of local Q424 {
		egen `var'Mmerge = rowtotal(`var'A_M `var'C_M `var'D_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'C_A `var'D_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) &  Q402 != 2
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

		local Q605 Q605

		foreach var of local Q605 {
		egen `var'Mmerge = rowtotal(`var'A_M `var'B_M `var'C_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'B_A `var'C_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}


		cap drop b6
		egen b6 = rowmean(Q423input Q424input Q605input)
		tab b6, m

	***Immediate postnatal care of mother

***B.7 monitoring and assememnt of maternal wellbeing, etc


*** Q601 Mothers BP checked after delivery
*** Q602 Vaginal exam done after delivery
*** Q603 Episiotomy checked
*** Q417 Gloves worn during pv exam?


		local Q601 Q601

		foreach var of local Q601 {
		egen `var'Mmerge = rowtotal(`var'A_M `var'B_M `var'C_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'B_A `var'C_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}


		local b5 Q602 Q603


		foreach var of local b5 {
		egen `var'Mmerge = rowtotal(`var'A_M `var'C_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'C_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4 & Q402 != 2
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

		local b5 Q420


		foreach var of local b5 {
		egen `var'Mmerge = rowtotal(`var'A_M `var'B_M `var'C_M) , m
		egen `var'Amerge = rowtotal(`var'A_A `var'B_A `var'C_A) , m
		gen `var'input = `var'Mmerge == 1 if !missing(`var'Mmerge) & Q402 != 4 & Q402 != 2
		replace `var'input = . if `var'Mmerge == 88
		replace `var'input = `var'Amerge == 1 if `var'Mmerge > 2 & `var'Amerge < 88
		
		}

		local Q417 Q417

		foreach var of local Q417 {
				egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) & Q402 != 4
				replace `var'input = . if `var'merge == 88
				}


		cap drop b7
		egen b7 = rowmean(Q601input Q602input Q603input Q417input)
		


***B.8 monitoring and assememnt of maternal wellbeing, etc

*** Q621 Dr do anything to stop the bleeding?




		local b6 Q621

		foreach var of local b6 {
		egen `var'merge = rowtotal(`var'A1 `var'B1 `var'C1) , m
		gen `var'input = `var'merge == 1 if !missing(`var'merge) & Q402 != 4
		replace `var'input = . if `var'merge == 88
		}

		cap drop b8
		gen b8 = Q621input
		

****calculate average score for section B: Childbirth care for each observation - ///
****if missing, the observation is not included in the average
		sum b* 
/*
		Variable |       Obs        Mean    Std. Dev.       Min        Max
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
		egen scoreB = rowmean(b1 b2 b3 b4 b5 b6)
		replace scoreB = round(scoreB,.1)
		sum scoreB
/*
                sum scoreB

    Variable |       Obs        Mean    Std. Dev.       Min        Max
-------------+--------------------------------------------------------
      scoreB |      3439    .6993603    .1931179          0          1

*/

						*******************************************
						***Section C: postnatal maternal care: ****
						*******************************************

**C1. Assessment of maternal wellbeing :

***Q1302 medical provider 1 week follow up?


		local Q1302 Q1302

		foreach var of local Q1302 {
				egen `var'merge = rowtotal(`var'A `var'B `var'C `var'D) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		gen c1 = Q1302input

**C3. anemia prevention and control 
**C4. information and souseling on nutrition safe sex, fam planning etc

***Q802-2,3,4 counseling on diet,  iron and calcium, family planning

		forvalues i= 1/6 {
		
			egen Q802merge`i' = rowtotal(Q802A_`i' Q802B_`i' Q802C_`i'), m

		}
/* note that Q802 has 55 as response? */ 
/* possible outcomes are 77- other, 88 - dk, 99 - no counseling given */


		forvalues i = 2/4 {
				gen Q802input`i' = (Q802merge1 == `i'|Q802merge2 == `i'|Q802merge3 == `i'|Q802merge4 == `i'|Q802merge5 == `i'|Q802merge6 == `i') if !mi(Q802merge1) 
				replace Q802input`i' = . if Q802merge1 == 88
		} 

	gen c3 = Q802input3
	egen c4 = rowmean(Q802input2 Q802input4)

***Q807 advised to report immediatelyif you have any of the following: high grade fever, discharge, excessive bleeding, wound gaping, convulsions

		
		forvalues i= 1/5 {
		
			egen Q807merge`i' = rowtotal(Q807A_`i' Q807B_`i' Q807C_`i'), m

		}

		forvalues i = 1/5 {
				gen Q807input`i' = (Q807merge1 == `i'|Q807merge2 == `i'|Q807merge3 == `i'|Q807merge4 == `i'|Q807merge5 == `i') if !mi(Q807merge1) 
				replace Q807input`i' = . if Q807merge1 == 99
		} 

	egen c5 = rowmean(Q807input*)

/* note, what is 99 coded as here? this question doesn't have and IDK option in the survey */

	sum c*
		
*** score for section C:		
/*
Variable |       Obs        Mean    Std. Dev.       Min        Max
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

    Variable |       Obs        Mean    Std. Dev.       Min        Max
-------------+--------------------------------------------------------
      scoreC |      3434    .4777228    .2766923          0          1

*/

						*******************************
						*** Section D Newborn care: ***
						*******************************

** 704 - ask if baby  fed?/
** 803 -  advice on breast feeding/
** 701 baby HR checked during first 12 hours after birth?/
** 702 Baby's temp checked?/
** 703 Ask about or check urine?/
** 708 Baby bathed within 6 hours? - reverse code /
** 701a Baby given eyerops/
** 802-1 Exclusive breasfeeding/
** 804 Advised on breastfeeding vs formula/
*** 802 -5 hygene/
** 802-8 warning signs to take baby to hospital /
** 705 - Baby receive any immunizations?/
** 706 which immunizations - follow up --> how to code?

** 806-1 skin to skin of kangaroo care - there are multiple questions  for this/

	
	** D.1 promotion, protections and support for breastfeeding **

		local d1 Q704 Q803 

		foreach var of local d1 {
			egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}
		
		egen d1 = rowmean(Q704input Q803input)	

	** D.2 Monitoring and assessnebt if wekkbeubgm detection of complications etc ** 

		local d2 Q701 Q702 Q703 

		foreach var of local d2 {
			egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		egen d2 = rowmean(Q701input Q702input Q703input)

	** D.3 Infection prevention and controling, rooming in ** 
		
		local d2 Q708 

		foreach var of local d2 {
			egen `var'merge = rowtotal(`var'A `var'B `var'C `var'D) , m
			gen `var'input = `var'merge == 2 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		gen d3 = Q708input

	** D.4 Eye Care ** 
		
		local d4  Q701A

		foreach var of local d4 {
			egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		gen d4 = Q701Ainput
	
	** D.5 Information with counseling on homecare, breasfeeding, hygiene **
			
		foreach  i in 1 5 8 9 {
			gen Q802input`i' = (Q802merge1 == `i'|Q802merge2 == `i'|Q802merge3 == `i'|Q802merge4 == `i'|Q802merge5 == `i'|Q802merge6 == `i') if !mi(Q802merge1)
			replace Q802input`i' = . if Q802merge1 == 88
			} 


		local d5 Q804

		foreach var of local d5 {
			egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		egen d5 = rowmean(Q802input1 Q804input Q802input5)

	** D.6 postnatal care planning, advice on danger signs, and emergency prepardness **
		
		gen d6 = Q802input8

	** D.7  immunizations according to national guidelines	

		local d3 Q705
		foreach var of local d3 {
			egen `var'merge = rowtotal(`var'A `var'B `var'C `var'D) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		forvalues i= 1/4 {
		
			egen Q706merge`i' = rowtotal(Q706A_`i' Q706B_`i' Q706C_`i' Q706D_`i'), m

		}

		local d3 1 2 3 4 oth
		foreach var of local d3 {
			egen 706merge = rowtotal(706A `var'B `var'C `var'D) , m
			gen `var'input = `var'merge == 1 if !missing(`var'merge) 
			replace `var'input = . if `var'merge == 88
			}

		forvalues i= 1/4 {
		
			egen Q706merge`i' = rowtotal(Q706A_`i' Q706B_`i' Q706C_`i' Q706D_`i'), m

		}

		gen d7 = Q705input

	** D.8 Kangarpp mother care follow-up

		forvalues i= 1/5 {
		
			egen Q806merge`i' = rowtotal(Q806A_`i' Q806B_`i' Q806C_`i'), m
		}

		gen Q806input = (Q806merge1 == 1|Q806merge2 == 1|Q806merge3 == 1|Q806merge4 == 1|Q806merge5 == 1) if !mi(Q806merge1)
		replace Q806input = . if Q806merge1 == 88

		egen d8 = rowmean(Q806input Q802input9)

	** score for section D
		sum d* 

		cap drop scoreD
		egen scoreD = rowmean(d1 d2 d3 d4 d5 d6 d7 d8)
		replace scoreD = round(scoreD, .1)
		sum scoreD 

/*
   Variable |       Obs        Mean    Std. Dev.       Min        Max
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



    Variable |       Obs        Mean    Std. Dev.       Min        Max
-------------+--------------------------------------------------------
      scoreD |      3431    .5239289    .1754839          0          1


      */
				*****************************************
				*** Section E: postnatal Newborn Care ***
				*****************************************


** E.1: Assessment of infant's wellbeing and breastfeeding **

* 1301 - Dr told you cto cbring the child back within 1 week of delivery
* 1302 medical provider check on you and baby after discharge ( ALSO USED IN C!!)

		local e1 Q1301 
		foreach var of local e1 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		local e1  Q1302
		foreach var of local e1 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'A `var'B `var'C `var'D) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		egen e1 = rowmean(Q1301input Q1302input)

** E.2 Detection of complications and responding to meternal concerns
	* 808 - given a contact number to call in case of emergency/need?
		local e2 Q808
		foreach var of local e2 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		gen e2 = Q808input
** E.3 information and counseling on home care
	* 805 - Dr advise you to keep the baby warm?
		local e3 Q805
		foreach var of local e3 {
				cap drop `var'merge `var'input
				egen `var'merge = rowtotal(`var'A `var'B `var'C) , m
				gen `var'input = `var'merge == 1 if !missing(`var'merge) 
				replace `var'input = . if `var'merge == 88
				}
		gen e3 = Q805input



		sum e*	


** calcualte total score for section E:
		cap drop scoreE
		egen scoreE = rowmean(e1 e2 e3)
		replace scoreE = round(scoreE, .1)
		sum scoreE


/*
    Variable |       Obs        Mean    Std. Dev.       Min        Max
-------------+--------------------------------------------------------
          e1 |      3429    .4144065    .3827251          0          1
          e2 |      3287    .3821113    .4859775          0          1
          e3 |      3245    .6912173    .4620625          0          1

   Variable |       Obs        Mean    Std. Dev.       Min        Max
-------------+--------------------------------------------------------
      scoreE |      3433    .4893679    .3147417          0          1

*/

*****generate averages by cluster:

egen pregnancycareA = mean(scoreA) 
egen childbirthcareB = mean(scoreB)
egen PNmaternalcareC = mean(scoreC)
egen newborncareD = mean(scoreD)
egen postnatalcareE = mean(scoreE)


estpost tabstat pregnancycareA childbirthcareB PNmaternalcareC newborncareD postnatalcareE, ///
statistics(mean sd) columns(statistics)
esttab, main(mean) nonote label nogaps compress wide



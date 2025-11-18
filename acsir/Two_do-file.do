***************************************
** ACS-IR Phase 2a: Data compilation **
***************************************

*  Stata version:  SE 15.1 (Data saved as Stata 13 version to allow use in Stata 13 - replace 'saveold...version(13)' with 'save' if wanted)
*   Code version:  2025-09-11 (Combine P2A and P2B)

* Note: This code is based on combining all countries. 
*       To run only only one country, either:
*       1) modify line xx to only have your country's initials, eg. foreach folder in BD {
*    or 2) remove lines xx [foreach folder in BD NG PK ET {] and xx [}]
*       and remove lines xx-xx and edit line xx to point to your folder.

*
* *
* * *
* * * * IMPORT DATA BY COUNTRY * * * * * * * * * * * * * * * * * 
 
clear

*
* *
* * * P2A

*** set the working directory folder: 
cd "/Users/juha/X/WHO/WHO24/Monitoring/Data2/P2A/"

* The above folder contains following folders representing each country, named:
** BD
** ET
** NG
** PK
* Which each contain only one "Outcome_data_XX_YYYYMMDD.xlsx" downloaded from respective country's ACS-IR SAS dashboard. Another folder needed is:
** Facilities - containing the facility listing

* LOOP COUNTRY EXCEL FILES TO CREATE ONE STATA FILE:
foreach folder in BD ET NG PK { 

* DATA IMPORT
clear
cd "`folder'"

** Find the only one excel file in the country folder:
local excelfileinfolder : dir . files "Outcome*"
di `excelfileinfolder'

**** Importing BDF form
preserve
	import excel using `excelfileinfolder', firstrow sheet("BDF") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	keep if BDF_CONSENT == 1
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID BDF_DATE
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_BDF = cond(_N==1,1,_n)
	 log using dup_BDF.log, replace
	 tab FORM_NUM_BDF
	 list PID if FORM_NUM_BDF > 1
     log close
	keep if FORM_NUM_BDF==1
	drop FORM_NUM_BDF
** RECODE BIRTWEIGHT **
  * recode BDF_BIRTH_WEIGHT1 BDF_BIRTH_WEIGHT2 BDF_BIRTH_WEIGHT3 BDF_BIRTH_WEIGHT4 BDF_BIRTH_WEIGHT5 BDF_BIRTH_WEIGHT6 (7777=.) (8888=.) (9999=.)
** FORM DETAILS **
	gen FORM_BDF = 1
	gen APP = "P2A"
	rename HOSPNUM HOSPNUM_BDF
	rename TAB_CODE TAB_CODE_BDF
	rename DT_SUBMIT Submit_BDF
	rename DT_TRANSFER Transfer_BDF
	rename App_Version App_Version_BDF
	format  Submit_BDF %tC
	format  Transfer_BDF %tC
	format BDF_DATE BDF_DT_ADM BDF_DT_EARLY_USG BDF_DT_LMP BDF_DT_DELIVERY %td
	order COUNTRY_NUM CLUST_NUM CLUST_NUM
	saveold "BDF.dta", replace version(13)
restore

**** Importing NFU-Hospitalization form 
preserve
	import excel using `excelfileinfolder', firstrow sheet("NFU-Hospitalization") clear
	destring *, ignore("NULL") replace
	drop App_Version USER_CODE STATUS DT_SUBMIT
** RESHAPE
	gen BABY_NO = substr(BABY_ID, 13,13)
	destring BABY_NO, replace
	* Paste facility name
	gen COUNTRY_NUM = substr(PID, 1, 1)
	gen CLUST_NUM = substr(PID, 2, 2)
	destring COUNTRY_NUM, replace
	destring CLUST_NUM, replace
	gen FAC_ID = COUNTRY_NUM * 10000 + CLUST_NUM * 100 + NFU_B1_SNCU_HOSP
	merge m:1 FAC_ID using "../../Facilities/FACILITY_LIST_P2.dta", nogen keepusing(HOSPITAL_NAME_BDF)
	drop if ADMIT_NO == .
	* Gen only one variable of hospital name
	gen     NFU_SNCU_HOSP_ADM = HOSPITAL_NAME_BDF
	tostring NFU_B1_SNCU_OTHER_NAME, replace
	replace NFU_SNCU_HOSP_ADM = NFU_B1_SNCU_OTHER_NAME if NFU_B1_SNCU_HOSP == 0
	drop NFU_B1_SNCU_HOSP NFU_B1_SNCU_OTHER_NAME HOSPITAL_NAME_BDF COUNTRY_NUM CLUST_NUM 
	rename FAC_ID NFU_SNCU_ID_ADM
	* 1st sort by admit
	sort       PID BABY_ID ADMIT_NO
	reshape wide NFU_SNCU_ID_ADM NFU_SNCU_HOSP_ADM, i(BABY_ID PID) j(ADMIT_NO)
	drop BABY_ID
    * 2nd sort by baby
	sort       PID BABY_NO
	* gen variables for max 5 admissions if not there
	capture generate NFU_SNCU_ID_ADM2 = .
	capture generate NFU_SNCU_HOSP_ADM2 = ""
	capture generate NFU_SNCU_ID_ADM3 = .
	capture generate NFU_SNCU_HOSP_ADM3 = ""
	capture generate NFU_SNCU_ID_ADM4 = .
	capture generate NFU_SNCU_HOSP_ADM4 = ""
	capture generate NFU_SNCU_ID_ADM5 = .
	capture generate NFU_SNCU_HOSP_ADM5 = ""
	rename NFU_SNCU_HOSP_ADM1 NFU_SNCU_HOSP_ADM1_B
	rename NFU_SNCU_HOSP_ADM2 NFU_SNCU_HOSP_ADM2_B
	rename NFU_SNCU_HOSP_ADM3 NFU_SNCU_HOSP_ADM3_B
	rename NFU_SNCU_HOSP_ADM4 NFU_SNCU_HOSP_ADM4_B
	rename NFU_SNCU_HOSP_ADM5 NFU_SNCU_HOSP_ADM5_B
	rename NFU_SNCU_ID_ADM1 NFU_SNCU_ID_ADM1_B
	rename NFU_SNCU_ID_ADM2 NFU_SNCU_ID_ADM2_B
	rename NFU_SNCU_ID_ADM3 NFU_SNCU_ID_ADM3_B
	rename NFU_SNCU_ID_ADM4 NFU_SNCU_ID_ADM4_B
	rename NFU_SNCU_ID_ADM5 NFU_SNCU_ID_ADM5_B
	order PID BABY_NO
	reshape wide NFU_SNCU_ID_ADM1_B-NFU_SNCU_HOSP_ADM5_B, i(PID) j(BABY_NO)
** FORM DETAILS **
    gen FORM_NFU_HOSP = 1
	saveold "NFU_HOSP.dta", replace version(13)
restore

**** Importing NFU form 
preserve
	import excel using `excelfileinfolder', firstrow sheet("NFU") clear
	destring *, ignore("NULL") replace
	* LTFU with STATUS=0 before (glitch before August '25. Now corrected)
	drop if NFU_DT_FILL < date("01jan2020","DMY")
	drop if STATUS == 0 & NFU_INTERVIEW_DONE == 1
	drop if STATUS == 0 & NFU_INTERVIEW_DONE == .
	*keep if STATUS == 1
	rename FW_NUM FW_NUM_NFU
	rename TAB_CODE TAB_CODE_NFU
	rename USER_CODE USER_CODE_NFU  
	rename App_Version App_Version_NFU 
	drop STATUS
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID NFU_DT_FILL
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_NFU = cond(_N==1,1,_n)
	 log using dup_NFU.log, replace
	 tab FORM_NUM_NFU
	 list PID if FORM_NUM_NFU > 1
     log close
	keep if FORM_NUM_NFU == 1
	drop FORM_NUM_NFU
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_NFU
	gen FORM_NFU = 1
	rename DT_SUBMIT Submit_NFU
	rename DT_TRANSFER Transfer_NFU
	format  Submit_NFU %tC
	format  Transfer_NFU %tC
	format  NFU_DT_FILL NFU_MOTHER_READMIT_DT NFU_B1_DEATH_DATE NFU_B2_DEATH_DATE NFU_B3_DEATH_DATE NFU_B4_DEATH_DATE NFU_B5_DEATH_DATE NFU_B6_DEATH_DATE %td
** MERGE HSOP
	merge 1:1 PID using "NFU_HOSP.dta"
	drop _merge
	order COUNTRY_NUM CLUST_NUM CLUST_NUM
	gen APP = "P2A"
	saveold "NFU.dta", replace version(13)
restore

* COMBINED DATABASE
use "BDF.dta", clear
merge 1:1 PID using "NFU.dta",      gen(match_DAN)

* Convert string variables to numeric variables
destring *, ignore("NULL") replace 
		
* Save raw data:
saveold "Full_database_complete_A.dta", replace version(13)
cd ..  // take back to the main folder
}


*
* *
* * * P2B
clear
*** set the working directory folder: 
cd "/Users/juha/X/WHO/WHO24/Monitoring/Data2/P2B/"

* The above folder contains following folders representing each country, named:
** BD
** ET
** NG
** PK
* Which each contain only one "Outcome_data_XX_YYYYMMDD.xlsx" downloaded from respective country's ACS-IR SAS dashboard. Another folder needed is:
** Facilities - containing the facility listing

* LOOP COUNTRY EXCEL FILES TO CREATE ONE STATA FILE:
foreach folder in BD ET NG PK { 

* DATA IMPORT
clear
cd "`folder'"

** Find the only one excel file in the country folder:
local excelfileinfolder : dir . files "Outcome*"
di `excelfileinfolder'

**** Importing BDF form
preserve
	import excel using `excelfileinfolder', firstrow sheet("BDF") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	keep if BDF_CONSENT == 1
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID BDF_DATE
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_BDF = cond(_N==1,1,_n)
	 log using dup_BDF.log, replace
	 tab FORM_NUM_BDF
	 list PID if FORM_NUM_BDF > 1
     log close
	keep if FORM_NUM_BDF==1
	drop FORM_NUM_BDF
** RECODE BIRTWEIGHT **
  * recode BDF_BIRTH_WEIGHT1 BDF_BIRTH_WEIGHT2 BDF_BIRTH_WEIGHT3 BDF_BIRTH_WEIGHT4 BDF_BIRTH_WEIGHT5 BDF_BIRTH_WEIGHT6 (7777=.) (8888=.) (9999=.)
** FORM DETAILS **
	gen FORM_BDF = 1
	gen APP = "P2B"
	rename HOSPNUM HOSPNUM_BDF
	rename TAB_CODE TAB_CODE_BDF
	rename DT_SUBMIT Submit_BDF
	rename DT_TRANSFER Transfer_BDF
	rename App_Version App_Version_BDF
	format  Submit_BDF %tC
	format  Transfer_BDF %tC
	format BDF_DATE BDF_DT_ADM BDF_DT_EARLY_USG BDF_DT_LMP BDF_DT_DELIVERY %td
	order COUNTRY_NUM CLUST_NUM CLUST_NUM
	saveold "BDF.dta", replace version(13)
restore

**** Importing ACS form 
preserve
	import excel using `excelfileinfolder', firstrow sheet("ACS") clear
	destring *, ignore("NULL") replace
	keep if STATUS == 1
	drop USER_CODE TAB_CODE FW_NUM STATUS
** REMOVE IF NO CONSENT **
	drop if ACS_CONSENT == 2
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_ACS
	gen FORM_ACS = 1
	rename DT_SUBMIT Submit_ACS
	rename DT_TRANSFER Transfer_ACS
	rename App_Version App_Version_ACS
	format  Submit_ACS %tC
	format  Transfer_ACS %tC
	format  ACS_DATE ACS_DT_EARLY_USG ACS_DT_LMP ACS_DOSE1_DATE ACS_OUTCOME_DT %td
**RESHAPE TO WIDE**
	saveold "ACS.dta", replace version(13)
	sort       COUNTRY_NUM CLUST_NUM PID ACS_DOSE1_DATE // Sort by 1st dose order if two or more courses
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_ACS = cond(_N==1,1,_n)
	reshape wide ACS* HOSPNUM_ACS FORM_ACS Submit_ACS, i(COUNTRY_NUM CLUST_NUM PID) j(FORM_NUM_ACS)
	* First ACS as main hospital
	gen HOSPNUM_ACS = HOSPNUM_ACS1
	gen APP = "P2B"
	saveold "ACS_WIDE.dta", replace version(13)
restore

/**** Importing NFU form 
preserve
	import excel using `excelfileinfolder', firstrow sheet("NFU") clear
	destring *, ignore("NULL") replace
	* LTFU with STATUS=0 before (glitch before August '25. Now corrected)
	drop if NFU_DT_FILL < date("01jan2020","DMY")
	drop if STATUS == 0 & NFU_INTERVIEW_DONE == 1
	drop if STATUS == 0 & NFU_INTERVIEW_DONE == .
	*keep if STATUS == 1
	rename App_Version App_Version_NFU
	rename FW_NUM FW_NUM_NFU
	rename TAB_CODE TAB_CODE_NFU
	rename USER_CODE USER_CODE_NFU   
	drop STATUS
** CHECK IF DUPLICATE **
	sort       COUNTRY_NUM CLUST_NUM PID NFU_DT_FILL
	quietly by COUNTRY_NUM CLUST_NUM PID: gen FORM_NUM_NFU = cond(_N==1,1,_n)
	 log using dup_NFU.log, replace
	 tab FORM_NUM_NFU
	 list PID if FORM_NUM_NFU > 1
     log close
	keep if FORM_NUM_NFU == 1
	drop FORM_NUM_NFU
** FORM DETAILS **
	rename HOSPNUM HOSPNUM_NFU
	gen FORM_NFU = 1
	rename DT_SUBMIT Submit_NFU
	rename DT_TRANSFER Transfer_NFU
	format  Submit_NFU %tC
	format  Transfer_NFU %tC
	format  NFU_DT_FILL NFU_MOTHER_READMIT_DT NFU_B1_DEATH_DATE NFU_B2_DEATH_DATE NFU_B3_DEATH_DATE NFU_B4_DEATH_DATE NFU_B5_DEATH_DATE NFU_B6_DEATH_DATE %td
** MERGE HSOP
	merge 1:1 PID using "NFU_HOSP.dta"
	gen APP = "P2B"
	drop _merge
	order COUNTRY_NUM CLUST_NUM CLUST_NUM
	saveold "NFU.dta", replace version(13)
restore
*/

* COMBINED DATABASE
use "BDF.dta", clear
merge 1:1 PID using "ACS_WIDE.dta", gen(match_DA)
*merge 1:1 PID using "NFU.dta",      gen(match_DAN)

* Convert string variables to numeric variables
destring *, ignore("NULL") replace 
		
* Save raw data:
saveold "Full_database_complete_B.dta", replace version(13)
cd ..  // take back to the main folder
}

*
* * 
* * * 
* * * * 
* * * * *
* * * * * * COMBINE COUNTRIES * * * * * * * * * * * * * * * * * * * 

clear
cd "/Users/juha/X/WHO/WHO24/Monitoring/Data2/

use          "P2A/BD/Full_database_complete_A.dta"
append using "P2A/PK/Full_database_complete_A.dta", force
append using "P2A/ET/Full_database_complete_A.dta", force
append using "P2A/NG/Full_database_complete_A.dta", force
append using "P2B/BD/Full_database_complete_B.dta", force
append using "P2B/PK/Full_database_complete_B.dta", force
append using "P2B/ET/Full_database_complete_B.dta", force
append using "P2B/NG/Full_database_complete_B.dta", force

order APP
tab APP

* Resolve missing CLUST_NUM due to DIST_NUM to CLUST_NUM change (solved)
tab COUNTRY_NUM CLUST_NUM, m
*gen CLUSTER_PID = substr(PID,2,2)
*destring CLUSTER_PID, replace
*replace CLUST_NUM = CLUSTER_PID if CLUST_NUM == .



* NG P2a: Change Hosp num on combined clusters
* Cross River & Akwa Ibom
replace HOSPNUM_BDF = HOSPNUM_BDF + 10 if COUNTRY_NUM == 1 & CLUST_NUM == 8  & TAB_CODE_BDF == "NHE" & HOSPNUM_BDF <=6
replace HOSPNUM_BDF = HOSPNUM_BDF + 10 if COUNTRY_NUM == 1 & CLUST_NUM == 8  & TAB_CODE_BDF == "NHF" & HOSPNUM_BDF <=6
replace HOSPNUM_BDF = HOSPNUM_BDF + 10 if COUNTRY_NUM == 1 & CLUST_NUM == 8  & TAB_CODE_BDF == "NHG" & HOSPNUM_BDF <=6
replace HOSPNUM_BDF = HOSPNUM_BDF + 10 if COUNTRY_NUM == 1 & CLUST_NUM == 8  & TAB_CODE_BDF == "NHH" & HOSPNUM_BDF <=6 
* Ogun & Ondo
replace HOSPNUM_BDF = HOSPNUM_BDF + 10 if COUNTRY_NUM == 1 & CLUST_NUM == 10 & TAB_CODE_BDF == "NJF" & HOSPNUM_BDF <=4
replace HOSPNUM_BDF = HOSPNUM_BDF + 10 if COUNTRY_NUM == 1 & CLUST_NUM == 10 & TAB_CODE_BDF == "NJG" & HOSPNUM_BDF <=4


* Merge facility list (Facility type and name)
merge n:1 COUNTRY_NUM CLUST_NUM HOSPNUM_BDF  using "Facilities/FACILITY_LIST_P2.dta", nogen keepusing(FAC_BDF  CLUST_NAME HOSPITAL_NAME_BDF)

*
* *
* * * Clean

* Drop no PID
drop if PID == ""
drop if COUNTRY_NUM == .

* Change NK/NA/missing dates (9.9.1909 etc.) to missing value (.)
foreach var of varlist *_DT_* *_DT *_DATE {
	replace `var'=. if `var' < mdy(1, 1, 2022)
}

*
* *
* * *
* * * *
* * * * * Download/today date

gen    TODAY = (date("${S_DATE}", "DMY"), "DMY")
format TODAY %td
label variable TODAY "Date of data download/code run"

*
* *
* * * Country name

gen     COUNTRY = ""
replace COUNTRY = "NG" if COUNTRY_NUM == 1
replace COUNTRY = "ET" if COUNTRY_NUM == 2
replace COUNTRY = "PK" if COUNTRY_NUM == 3
replace COUNTRY = "BD" if COUNTRY_NUM == 4

*
* *
* * * Hospital unique

gen HOSPITAL = 1000 * COUNTRY_NUM + 100 * CLUST_NUM + HOSPNUM_BDF

*
* *
* * * ANALYSIS VARIABLE CREATION

*
* *
* * *
* * * * Basic details:

gen HOSPNUM = HOSPNUM_BDF
	
* FACILITY CATEGORIZATION:	

gen            ACS_IF = .
replace        ACS_IF = 1 if FAC_BDF == "Core facility"
replace        ACS_IF = 2 if FAC_BDF == "NOC facility"
label define   ACS_IF  1 "Core Facility" 2 "NOC Facility"
label values   ACS_IF ACS_IF
label variable ACS_IF "Facility type BDF"

gen FAC = FAC_BDF

*
* *
* * * TIMELINE

* PERIOD DELIVERY: creating the month/year date
gen       YYYY =    year(BDF_DT_DELIVERY) 
gen         MM =   month(BDF_DT_DELIVERY)
gen     YYYYMM = ym(year(BDF_DT_DELIVERY), month(BDF_DT_DELIVERY))
format  YYYYMM %tm

* PERIOD DELIVERY: creating the month/year date
gen       YYYY_MNFU =    year(NFU_DT_FILL) 
gen         MM_MNFU =   month(NFU_DT_FILL)
gen     YYYYMM_MNFU = ym(year(NFU_DT_FILL), month(NFU_DT_FILL))
format  YYYYMM_MNFU %tm

* QUARTER BDF
gen     QUARTER = .
replace QUARTER = 1  if YYYY == 2025 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 2  if YYYY == 2025 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 3  if YYYY == 2025 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 4  if YYYY == 2025 & (MM == 10 | MM == 11 | MM == 12)
replace QUARTER = 5  if YYYY == 2026 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 6  if YYYY == 2026 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 7  if YYYY == 2026 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 8  if YYYY == 2026 & (MM == 10 | MM == 11 | MM == 12)
replace QUARTER = 9  if YYYY == 2027 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 10 if YYYY == 2027 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 11 if YYYY == 2027 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 12 if YYYY == 2027 & (MM == 10 | MM == 11 | MM == 12)
replace QUARTER = 13 if YYYY == 2028 & (MM ==  1 | MM ==  2 | MM ==  3)
replace QUARTER = 14 if YYYY == 2028 & (MM ==  4 | MM ==  5 | MM ==  6)
replace QUARTER = 15 if YYYY == 2028 & (MM ==  7 | MM ==  8 | MM ==  9)
replace QUARTER = 16 if YYYY == 2028 & (MM == 10 | MM == 11 | MM == 12)

*
* *
* * * TIMES

* Error handling, missing time, save original for reference:
gen BDF_TM_DELIVERY_HH_original = BDF_TM_DELIVERY_HH
gen BDF_TM_DELIVERY_MM_original = BDF_TM_DELIVERY_MM

gen BDF_TM_ADM_HH_original = BDF_TM_ADM_HH
gen BDF_TM_ADM_MM_original = BDF_TM_ADM_MM

gen ACS_DOSE1_HH1_original = ACS_DOSE1_HH1
gen ACS_DOSE1_MM1_original = ACS_DOSE1_MM1

** RECODE MISSING HH:MM: delivery to end of day
replace BDF_TM_DELIVERY_HH = 23 if BDF_DT_DELIVERY != . & (BDF_TM_DELIVERY_HH > 23 | BDF_TM_DELIVERY_HH == .)
replace BDF_TM_DELIVERY_MM = 59 if BDF_DT_DELIVERY != . & (BDF_TM_DELIVERY_MM > 59 | BDF_TM_DELIVERY_MM == .)

** RECODE MISSING HH:MM: admission to start of day
replace BDF_TM_ADM_HH = 0 if BDF_DT_DELIVERY != . & (BDF_TM_ADM_HH > 23 | BDF_TM_ADM_HH == .)
replace BDF_TM_ADM_MM = 0 if BDF_DT_DELIVERY != . & (BDF_TM_ADM_MM > 59 | BDF_TM_ADM_MM == .)

** RECODE MISSING HH:MM: administration to start of day
replace ACS_DOSE1_HH1 = 0 if ACS_DOSE1_DATE1 != . & (ACS_DOSE1_HH1 > 23 | ACS_DOSE1_MM1 == .)
replace ACS_DOSE1_MM1 = 0 if ACS_DOSE1_DATE1 != . & (ACS_DOSE1_MM1 > 59 | ACS_DOSE1_MM1 == .)

* Date + time:

** Delivery clock
gen double      DEL_TIME = hms(BDF_TM_DELIVERY_HH,BDF_TM_DELIVERY_MM,0)
format %tcHH:MM DEL_TIME
label variable  DEL_TIME "Delivery time"

** Delivery date+time	
gen double     DEL_DT = cofd(BDF_DT_DELIVERY) + DEL_TIME
format         DEL_DT %tcNN/DD/CCYY_HH:MM
label variable DEL_DT "Delivery date and time"

** Admission clock
gen double      ADM_TIME = hms(BDF_TM_ADM_HH,BDF_TM_ADM_MM,0)
format %tcHH:MM ADM_TIME
label variable  ADM_TIME "Delivery admission time"

** Admission date+time
gen double     ADM_DT = cofd(BDF_DT_ADM) + ADM_TIME
format         ADM_DT %tcNN/DD/CCYY_HH:MM
label variable ADM_DT "Delivery admission date and time"

** Administration (Course 1) clock
gen double     ACS_TIME = hms(ACS_DOSE1_HH1, ACS_DOSE1_MM1,0)
format %tcHH   ACS_TIME
label variable ACS_TIME "ACS Dose 1, Course 1, time"

** Administration (Course 1) date+time
gen double     ACS_DT = cofd(ACS_DOSE1_DATE1) + ACS_TIME
format         ACS_DT %tcNN/DD/CCYY_HH:MM
label variable ACS_DT "ACS Dose 1, Course 1, date and time"

*
* *
* * * * TIME DIFFERENCES

* Calculating time between admission and delivery (days+hours)
gen            DAYS_ADM_TO_DEL = (DEL_DT  - ADM_DT)/ 864e5 
label variable DAYS_ADM_TO_DEL "Days from admission to delivery (including hours and minutes)"

* Calculating time between ACS administration and delivery
gen            DAYS_ACS_TO_DEL = (DEL_DT  - ACS_DT)/ 864e5 
label variable DAYS_ACS_TO_DEL "Days from Dose 1 to delivery (including hours and minutes)"

* Days from admission to delivery
gen            DAYS_FROM_ADM_TO_DEL = BDF_DT_DELIVERY - BDF_DT_ADM if FORM_BDF == 1
label variable DAYS_FROM_ADM_TO_DEL "Days from admission to delivery"

* Days from administration to delivery
gen            DAYS_FROM_ACS_TO_DEL = BDF_DT_DELIVERY - ACS_DOSE1_DATE1 if FORM_BDF == 1 & FORM_ACS1 == 1
label variable DAYS_FROM_ACS_TO_DEL "Days from 1st ACS to delivery"

*
* *
* * * Error handling: Invalid early USG date (after delivery or dose)

gen USG_TO_BDF = BDF_DT_DELIVERY - BDF_DT_EARLY_USG  if BDF_DT_DELIVERY != . & BDF_DT_EARLY_USG  != .

label variable USG_TO_BDF "Days from BDF EUSG to delivery"

/* Recode to missing if EUSG done after delivery
replace BDF_DT_EARLY_USG      = . if USG_TO_BDF < 0 & USG_TO_BDF != .
replace BDF_GA_EARLYUSG_WKS   = . if USG_TO_BDF < 0 & USG_TO_BDF != .
replace BDF_GA_EARLYUSG_DAYS  = . if USG_TO_BDF < 0 & USG_TO_BDF != .
*/

*
* *
* * * GA at Early USG

gen     EARLYUSG_BDF_DAYS = BDF_GA_EARLYUSG_WKS * 7                  if BDF_GA_EARLYUSG_WKS < 60 & BDF_DT_EARLY_USG != .
replace EARLYUSG_BDF_DAYS = EARLYUSG_BDF_DAYS + BDF_GA_EARLYUSG_DAYS if BDF_GA_EARLYUSG_DAYS < 8 & BDF_DT_EARLY_USG != .
label variable EARLYUSG_BDF_DAYS "Gestational age in days at earliest USG (BDF)"

gen     EARLYUSG_ACS_DAYS = ACS_GA_EARLYUSG_WKS1 * 7 if ACS_GA_EARLYUSG_WKS1 < 60 
replace EARLYUSG_ACS_DAYS = EARLYUSG_ACS_DAYS + ACS_GA_EARLYUSG_DAYS1 if ACS_GA_EARLYUSG_DAYS1 < 8
label variable EARLYUSG_ACS_DAYS "Gestational age in days at earliest USG ACS course 1"

*
* *
* * * EARLIEST USG BEFORE 24 WEEKS (WHO preference over trimesters)

gen     EARLYUSG_BDF_24 = .
replace EARLYUSG_BDF_24 = 1 if EARLYUSG_BDF_DAYS   < 24*7
replace EARLYUSG_BDF_24 = 2 if EARLYUSG_BDF_DAYS  >= 24*7
replace EARLYUSG_BDF_24 = 9 if EARLYUSG_BDF_DAYS  == . & FORM_BDF == 1
replace EARLYUSG_BDF_24 = . if EARLYUSG_BDF_DAYS  == . & FORM_BDF != 1
label variable EARLYUSG_BDF_24 "Timing of Earliest USG in BDF (24 weeks)"

gen     EARLYUSG_ACS_24 = .
replace EARLYUSG_ACS_24 = 1 if EARLYUSG_ACS_DAYS   < 24*7
replace EARLYUSG_ACS_24 = 2 if EARLYUSG_ACS_DAYS  >= 24*7
replace EARLYUSG_ACS_24 = 9 if EARLYUSG_ACS_DAYS  == . & FORM_ACS1 == 1
replace EARLYUSG_ACS_24 = . if EARLYUSG_ACS_DAYS  == . & FORM_ACS1 != 1
label variable EARLYUSG_ACS_24 "Timing of Earliest USG in ACS (24 weeks)"

label define USG24 1 "USG <24 weeks" 2 "USG ≥24 weeks" 9 "No USG"
label values EARLYUSG_BDF_24 USG24
label values EARLYUSG_ACS_24 USG24

*
* *
* * *
* * * * GA at birth (days)

gen     GA_BIRTH = BDF_GA_WEEKS * 7       if BDF_GA_WEEKS < 60 & FORM_BDF==1
replace GA_BIRTH = GA_BIRTH + BDF_GA_DAYS if BDF_GA_DAYS  < 8  & FORM_BDF==1

label variable GA_BIRTH "Gestational age in days at birth using provider estimate"

gen     GA_BIRTH_EUSG = BDF_DT_DELIVERY - BDF_DT_EARLY_USG + EARLYUSG_BDF_DAYS  if FORM_BDF==1 & BDF_DT_DELIVERY != . & BDF_DT_EARLY_USG != . & EARLYUSG_BDF_DAYS  != .

label variable GA_BIRTH_EUSG "Gestational age in days at birth using the earliest USG"


*
* *
* * * ACS age (days)

gen     GA_ACS_DAY = ACS_GA_ADM_WEEKS1 * 7         if ACS_GA_ADM_WEEKS1 < 60
replace GA_ACS_DAY = GA_ACS_DAY + ACS_GA_ADM_DAYS1 if ACS_GA_ADM_DAYS1 < 8
label variable GA_ACS_DAY "Gestational age in days at dose1 course1, provider"

gen     GA_ACS_EUSG = ACS_DOSE1_DATE1 - ACS_DT_EARLY_USG1 + EARLYUSG_ACS_DAYS
label variable GA_ACS_EUSG "Gestational age in days at ACS dose 1 course 1 using the earliest USG"

*
* *
* * *
* * * * GA at birth (category)

gen     GA_BIRTH_CAT = .
replace GA_BIRTH_CAT = 0 if GA_BIRTH >= 0    & GA_BIRTH < 28*7  // 26*7 = 182
replace GA_BIRTH_CAT = 1 if GA_BIRTH >= 28*7 & GA_BIRTH < 34*7  // 34*7 = 238
replace GA_BIRTH_CAT = 2 if GA_BIRTH >= 34*7 & GA_BIRTH < 37*7  // 37*7 = 259
replace GA_BIRTH_CAT = 3 if GA_BIRTH >= 37*7 & GA_BIRTH < 45*7  // 45*7 = 315
replace GA_BIRTH_CAT = 4 if GA_BIRTH >= 45*7
replace GA_BIRTH_CAT = 8 if BDF_GA_WEEKS == 88
replace GA_BIRTH_CAT = 9 if BDF_GA_WEEKS == .
replace GA_BIRTH_CAT = . if FORM_BDF != 1

label variable GA_BIRTH_CAT "Gestational age category at birth from provider BDF"

gen     GA_BIRTH_CATU = .
replace GA_BIRTH_CATU = 0 if GA_BIRTH_EUSG >= 0    & GA_BIRTH_EUSG < 28*7
replace GA_BIRTH_CATU = 1 if GA_BIRTH_EUSG >= 28*7 & GA_BIRTH_EUSG < 34*7
replace GA_BIRTH_CATU = 2 if GA_BIRTH_EUSG >= 34*7 & GA_BIRTH_EUSG < 37*7
replace GA_BIRTH_CATU = 3 if GA_BIRTH_EUSG >= 37*7 & GA_BIRTH_EUSG < 45*7
replace GA_BIRTH_CATU = 4 if GA_BIRTH_EUSG >= 45*7 & GA_BIRTH_EUSG != .
replace GA_BIRTH_CATU = 8 if BDF_GA_EARLYUSG_WKS == 88
replace GA_BIRTH_CATU = 8 if GA_BIRTH_EUSG == .
replace GA_BIRTH_CATU = 9 if BDF_GA_EARLYUSG_WKS == .
replace GA_BIRTH_CATU = . if FORM_BDF != 1

label variable GA_BIRTH_CATU "Gestational age category at birth from earliest USG in BDF"

label define GA_BIRTH_CAT  0 "0+0 - 27+6" 1 "28+0 - 33+6" 2 "34+0 - 36+6" 3 "37+0 - 44+6" 4 "45+0 -" 8 "NK"     9 "Missing"
label define GA_BIRTH_CATU 0 "0+0 - 27+6" 1 "28+0 - 33+6" 2 "34+0 - 36+6" 3 "37+0 - 44+6" 4 "45+0 -" 8 "No USG" 9 "Missing"
label values GA_BIRTH_CAT            GA_BIRTH_CAT 
label values GA_BIRTH_CATU           GA_BIRTH_CATU



*
* *
* * * CORRECTED WEEKS+DAYS

* Delivery Gestation Age (DGA) based on Corrected Earliest USG (EUSG) from BDF as WEEKS+DAYS
gen            DGA_WEEKS = .
replace        DGA_WEEKS = floor(GA_BIRTH_EUSG/7)
label variable DGA_WEEKS "DGA EUSG weeks (BDF)"

gen            DGA_DAYS = .
replace        DGA_DAYS = GA_BIRTH_EUSG - DGA_WEEKS*7
label variable DGA_DAYS "DGA EUSG days (BDF)"



*
* *
* * * ACS (category)

gen     GA_ACS_CAT = .
replace GA_ACS_CAT = 1 if GA_ACS_DAY >= 24*7 & GA_ACS_DAY < 34*7
replace GA_ACS_CAT = 2 if GA_ACS_DAY >= 34*7 & GA_ACS_DAY < 37*7
replace GA_ACS_CAT = 3 if GA_ACS_DAY >= 37*7 & GA_ACS_DAY < 45*7
replace GA_ACS_CAT = 4 if GA_ACS_DAY >= 45*7
replace GA_ACS_CAT = 0 if GA_ACS_DAY  < 24*7
replace GA_ACS_CAT = 9 if GA_ACS_DAY == .
replace GA_ACS_CAT = . if FORM_ACS1 != 1

label variable GA_ACS_CAT "Gestational age provider at ACS 1"

gen     GA_ACS_CATU = .
replace GA_ACS_CATU = 1 if GA_ACS_EUSG >= 24*7 & GA_ACS_EUSG < 34*7 
replace GA_ACS_CATU = 2 if GA_ACS_EUSG >= 34*7 & GA_ACS_EUSG < 37*7 
replace GA_ACS_CATU = 3 if GA_ACS_EUSG >= 37*7 & GA_ACS_EUSG < 45*7 
replace GA_ACS_CATU = 4 if GA_ACS_EUSG >= 45*7 
replace GA_ACS_CATU = 0 if GA_ACS_EUSG  < 24*7 
replace GA_ACS_CATU = 9 if GA_ACS_EUSG == .
replace GA_ACS_CATU = . if FORM_ACS1 != 1

label variable GA_ACS_CATU "Gestational age at ACS 1 from earliest USG"


* Labels for GA cat
label define ACS_CAT 0 "- 23+6" 1 "24+0 - 33+6" 2 "34+0 - 36+6" 3 "37+0 - 44+6" 4 "45+0 -" 9 "NK/NA"

label values GA_ACS_CAT       ACS_CAT
label values GA_ACS_CATU      ACS_CAT


*
* *
* * * EUSG available

gen     EUSG_AVAIL = .
replace EUSG_AVAIL = 0 if FORM_BDF == 1
replace EUSG_AVAIL = 1 if FORM_BDF == 1 &  BDF_GA_EARLYUSG_WKS > 0 & BDF_GA_EARLYUSG_WKS < 88 & BDF_GA_EARLYUSG_DAYS >= 0 & BDF_DT_EARLY_USG != .

*
* *
* * * Number of livebirths

gen     NUM_LIVEBIRTH = 0 if FORM_BDF == 1
replace NUM_LIVEBIRTH = 1                 if BDF_BIRTH_STATUS1 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS2 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS3 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS4 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS5 == 1
replace NUM_LIVEBIRTH = NUM_LIVEBIRTH + 1 if BDF_BIRTH_STATUS6 == 1

gen     NUM_LEFT_ALIVE = 0 if FORM_BDF == 1
replace NUM_LEFT_ALIVE = 1                  if BDF_BIRTH_STATUS1 == 1 & BDF_LEFT_STATUS1 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS2 == 1 & BDF_LEFT_STATUS2 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS3 == 1 & BDF_LEFT_STATUS3 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS4 == 1 & BDF_LEFT_STATUS4 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS5 == 1 & BDF_LEFT_STATUS5 != 3
replace NUM_LEFT_ALIVE = NUM_LEFT_ALIVE + 1 if BDF_BIRTH_STATUS6 == 1 & BDF_LEFT_STATUS6 != 3

*
* *
* * *
* * * *
* * * * * NFU (All mothers followed)

gen     NEEDS_NFU = 0
replace NEEDS_NFU = 1 if BDF_MNFU_CONSENT == 1 & NUM_LEFT_ALIVE >= 1

gen AGE_NFU = NFU_DT_FILL - BDF_DT_DELIVERY
label variable AGE_NFU "Age at NFU, days"

gen     AGE_READMISSION_MOTHER = .
replace AGE_READMISSION_MOTHER = NFU_MOTHER_READMIT_DT - BDF_DT_DELIVERY 

*
* *
* * *

* LABELS:
label define YESNONKNA   1 "Yes" 2 "No" 8 "NK" 9 "NA"

label values BDF_CONSENT         YESNONKNA
label values BDF_ACS_RECEIVED    YESNONKNA
label values BDF_ACUTE_BACT_INF  YESNONKNA
label values BDF_RESUSCITATION1  YESNONKNA
label values BDF_RESUSCITATION2  YESNONKNA
label values BDF_RESUSCITATION3  YESNONKNA
label values BDF_RESUSCITATION4  YESNONKNA
label values BDF_RESUSCITATION5  YESNONKNA
label values BDF_RESUSCITATION6  YESNONKNA
label values BDF_MNFU_CONSENT    YESNONKNA

label define BDF_BIRTH_STATUS 1 "Liveborn" 2 "Stillborn" 8 "NK" 9 "NA"
label values BDF_BIRTH_STATUS1 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS2 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS3 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS4 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS5 BDF_BIRTH_STATUS
label values BDF_BIRTH_STATUS6 BDF_BIRTH_STATUS

label define BDF_MODE_DELIVERY 1 "Vaginal" 2 "C-section" 8 "NK"
label values BDF_MODE_DELIVERY1 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY2 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY3 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY4 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY5 BDF_MODE_DELIVERY
label values BDF_MODE_DELIVERY6 BDF_MODE_DELIVERY

label define BDF_ANC_PATIENT_STATUS 1 "Booked" 2 "Un-booked" 8 "NK" 9 "NA"
label values BDF_ANC_PATIENT_STATUS BDF_ANC_PATIENT_STATUS

label define BDF_PLACE_ACS 1 "Current facility" 2 "Other in NOC" 3 "Other outside NOC" 8 "NK" 9 "NA"
label values BDF_PLACE_ACS BDF_PLACE_ACS

label define BDF_PT_BIRTH_INDICTN 1 "PPROM" 2 "Spontaneous preterm labour" 3 "Pre-eclampsia" 4 "Antepartum haemorrhage" 5 "Other" 8 "NK" 9 "NA"
label values BDF_PT_BIRTH_INDICTN BDF_PT_BIRTH_INDICTN

label define BDF_FHS 1 "FHS present" 2 "FHS absent" 3 "Not documented" 8 "NK" 9 "NA"
label values BDF_FHS BDF_FHS

label define BDF_LEFT_STATUS 1 "Alive in Postnatal Ward" 2 "Alive at NICU" 3 "Dead" 4 "Discharged" 5 "Referred" 8 "NK" 9 "NA"
label values BDF_LEFT_STATUS1 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS2 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS3 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS4 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS5 BDF_LEFT_STATUS
label values BDF_LEFT_STATUS6 BDF_LEFT_STATUS

label define SEX 1 "Female" 2 "Male" 3 "Undetermined" 8 "NK" 9 "NA"
label values BDF_SEX1 SEX
label values BDF_SEX2 SEX
label values BDF_SEX3 SEX
label values BDF_SEX4 SEX
label values BDF_SEX5 SEX
label values BDF_SEX6 SEX

label define TRIMM   1 "1st" 2 "2nd" 3 "3rd" 8 "NK" 9 "NA"
label values BDF_TRIM_1STANC_VISIT TRIMM

label define NFU_INTERVIEW_DONE 1 "Yes" 2 "Lost to follow-up (60 days)"
label values NFU_INTERVIEW_DONE NFU_INTERVIEW_DONE

label define NFU_TYPE_INTERVIEW 1 "Telephonic" 2 "Home visit" 3 "Other"
label values NFU_TYPE_INTERVIEW NFU_TYPE_INTERVIEW

label define NFU_INFORMANT 1 "Mother" 2 "Other family member" 3 "Other"	
label values NFU_INFORMANT NFU_INFORMANT

label define NFU_MOTHER_READMIT_RSN 1 "Infection/Fever" 2 "Other" 8 "NK" 9 "NA"
label values NFU_MOTHER_READMIT_RSN NFU_MOTHER_READMIT_RSN

label define NFU_VITAL_STATUS 1 "Alive" 2 "Dead" 8 "NK" 9 "NA"
label values NFU_B1_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B2_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B3_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B4_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B5_VITAL_STATUS NFU_VITAL_STATUS
label values NFU_B6_VITAL_STATUS NFU_VITAL_STATUS

label define NFU_DEATH_PLACE 1 "Facility" 2 "In transit" 3 "Community/Home" 8 "NK" 9 "NA"
label values NFU_B1_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B2_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B3_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B4_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B5_DEATH_PLACE NFU_DEATH_PLACE
label values NFU_B6_DEATH_PLACE NFU_DEATH_PLACE

label define NFU_DEATH_LOCATION 1 "Labour room" 2 "Gyn/postnatal ward" 3 "Neonatal care unit/SNCU/Nursery" 4 "Other" 8 "NK" 9 "NA"
label values NFU_B1_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B2_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B3_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B4_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B5_DEATH_LOCATION NFU_DEATH_LOCATION
label values NFU_B6_DEATH_LOCATION NFU_DEATH_LOCATION

label values NFU_MOTHER_ALIVE   YESNONKNA
label values NFU_MOTHER_READMIT YESNONKNA
label values NFU_B1_SNCU YESNONKNA
label values NFU_B2_SNCU YESNONKNA
label values NFU_B3_SNCU YESNONKNA
label values NFU_B4_SNCU YESNONKNA
label values NFU_B5_SNCU YESNONKNA
label values NFU_B6_SNCU YESNONKNA

label define BINARY 0 "No" 1 "Yes"
label values EUSG_AVAIL BINARY
label values NEEDS_NFU  BINARY

* P2B


label values BDF_ANTIBIOTICS    YESNONKNA
label values BDF_ANTIB_PPROM    YESNONKNA
label values BDF_ANTIB_CS       YESNONKNA
label values BDF_ANTIB_OTHER    YESNONKNA
label values BDF_MAGNESIUM_SUL  YESNONKNA
label values BDF_MAG_NEURO      YESNONKNA
label values BDF_MAG_SPE        YESNONKNA
label values BDF_MAG_OTHER      YESNONKNA
label values ACS_TOCOLYTICS1    YESNONKNA
label values ACS_SIGNS_ACUTE_INFECTION1 YESNONKNA

label values ACS_FHS1        BDF_FHS
label values ACS_PRIM_DIAGN1 BDF_PT_BIRTH_INDICTN

label define ACS_OUTCOME_ADM 1 "No delivery (Discharged/LAMA alive prior to delivery)" 2 "Delivered" 3 "Referred to a higher-level facility" 4 "Maternal death" 5 "Miscarriage/Abortion" 6 "Remained in the facility for another treatment" 8 "NK"
label values ACS_OUTCOME_ADM1 ACS_OUTCOME_ADM

*
* * 
* * * 
* * * * 
* * * * * SAVE FULL DATA * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

keep if PID != ""

order COUNTRY

saveold "Full_database_analysis_ALL_COUNTRIES_P2.dta", replace version(13)

* export excel     using "Full_database_analysis_ALL_COUNTRIES.xlsx", firstrow(variables) nolabel replace
* export delimited using "Full_database_analysis_ALL_COUNTRIES_P2.csv", replace 

*
* * 
* * * 
* * * * 
* * * * * 
* * * * * *
* * * * * * * LONG FORMAT - KEY VARIABLES * * * * * * * * * * * * * * * * * * * * * * *

clear
use "/Users/juha/X/WHO/WHO24/Monitoring/Data2/Full_database_analysis_ALL_COUNTRIES_P2.dta"

* DROP UNKNOWN NEONATES
drop if BDF_NUM_FETUS == 8

* Reveal missing BW
replace BDF_BIRTH_WEIGHT1 = 9999 if BDF_BIRTH_WEIGHT1 == . & BDF_NUM_FETUS == 1
replace BDF_BIRTH_WEIGHT2 = 9999 if BDF_BIRTH_WEIGHT2 == . & BDF_NUM_FETUS >= 2
replace BDF_BIRTH_WEIGHT3 = 9999 if BDF_BIRTH_WEIGHT3 == . & BDF_NUM_FETUS >= 3
replace BDF_BIRTH_WEIGHT4 = 9999 if BDF_BIRTH_WEIGHT4 == . & BDF_NUM_FETUS >= 4
replace BDF_BIRTH_WEIGHT5 = 9999 if BDF_BIRTH_WEIGHT5 == . & BDF_NUM_FETUS >= 5
replace BDF_BIRTH_WEIGHT6 = 9999 if BDF_BIRTH_WEIGHT6 == . & BDF_NUM_FETUS >= 6

list COUNTRY PID BDF_BIRTH_WEIGHT1 if BDF_BIRTH_WEIGHT1 == 9999
list COUNTRY PID BDF_BIRTH_WEIGHT2 if BDF_BIRTH_WEIGHT2 == 9999
list COUNTRY PID BDF_BIRTH_WEIGHT3 if BDF_BIRTH_WEIGHT3 == 9999
list COUNTRY PID BDF_BIRTH_WEIGHT4 if BDF_BIRTH_WEIGHT4 == 9999
list COUNTRY PID BDF_BIRTH_WEIGHT5 if BDF_BIRTH_WEIGHT5 == 9999
list COUNTRY PID BDF_BIRTH_WEIGHT6 if BDF_BIRTH_WEIGHT6 == 9999

* Rename NFU variables to fit long format:
rename NFU_B1_VITAL_STATUS NFU_VITAL_STATUS1
rename NFU_B2_VITAL_STATUS NFU_VITAL_STATUS2
rename NFU_B3_VITAL_STATUS NFU_VITAL_STATUS3
rename NFU_B4_VITAL_STATUS NFU_VITAL_STATUS4
rename NFU_B5_VITAL_STATUS NFU_VITAL_STATUS5
rename NFU_B6_VITAL_STATUS NFU_VITAL_STATUS6

rename NFU_B1_DEATH_PLACE NFU_DEATH_PLACE1
rename NFU_B2_DEATH_PLACE NFU_DEATH_PLACE2
rename NFU_B3_DEATH_PLACE NFU_DEATH_PLACE3
rename NFU_B4_DEATH_PLACE NFU_DEATH_PLACE4
rename NFU_B5_DEATH_PLACE NFU_DEATH_PLACE5
rename NFU_B6_DEATH_PLACE NFU_DEATH_PLACE6

rename NFU_B1_DEATH_DATE NFU_DEATH_DATE1
rename NFU_B2_DEATH_DATE NFU_DEATH_DATE2
rename NFU_B3_DEATH_DATE NFU_DEATH_DATE3
rename NFU_B4_DEATH_DATE NFU_DEATH_DATE4
rename NFU_B5_DEATH_DATE NFU_DEATH_DATE5
rename NFU_B6_DEATH_DATE NFU_DEATH_DATE6

rename NFU_B1_SNCU  NFU_SNCU1
rename NFU_B2_SNCU  NFU_SNCU2
rename NFU_B3_SNCU  NFU_SNCU3
rename NFU_B4_SNCU  NFU_SNCU4
rename NFU_B5_SNCU  NFU_SNCU5
rename NFU_B6_SNCU  NFU_SNCU6

rename NFU_B1_SNCU_NUM NFU_SNCU_NUM1
rename NFU_B2_SNCU_NUM NFU_SNCU_NUM2
rename NFU_B3_SNCU_NUM NFU_SNCU_NUM3
rename NFU_B4_SNCU_NUM NFU_SNCU_NUM4
rename NFU_B5_SNCU_NUM NFU_SNCU_NUM5
rename NFU_B6_SNCU_NUM NFU_SNCU_NUM6

rename NFU_B1_DEATH_LOCATION NFU_DEATH_LOCATION1
rename NFU_B2_DEATH_LOCATION NFU_DEATH_LOCATION2
rename NFU_B3_DEATH_LOCATION NFU_DEATH_LOCATION3
rename NFU_B4_DEATH_LOCATION NFU_DEATH_LOCATION4
rename NFU_B5_DEATH_LOCATION NFU_DEATH_LOCATION5
rename NFU_B6_DEATH_LOCATION NFU_DEATH_LOCATION6

* Clean to fit variables
tostring BDF_CHILD_ID3, replace format("%11.1f") force
tostring BDF_CHILD_ID4, replace format("%11.1f") force
tostring BDF_CHILD_ID5, replace format("%11.1f") force
tostring BDF_CHILD_ID6, replace format("%11.1f") force

tostring NFU_SNCU_HOSP_ADM1_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM2_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM3_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM4_B1, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM5_B1, replace format("%9.0g") force

tostring NFU_SNCU_HOSP_ADM1_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM2_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM3_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM4_B2, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM5_B2, replace format("%9.0g") force

tostring NFU_SNCU_HOSP_ADM1_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM2_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM3_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM4_B3, replace format("%9.0g") force
tostring NFU_SNCU_HOSP_ADM5_B3, replace format("%9.0g") force

* Reshape on baby variables. Generates variable BABY_NUM indicating each newborn as one line:
reshape long BDF_CHILD_ID BDF_BIRTH_ORDER BDF_MODE_DELIVERY BDF_BIRTH_STATUS BDF_BIRTH_WEIGHT BDF_SEX BDF_RESUSCITATION BDF_LEFT_STATUS ///
			 NFU_VITAL_STATUS NFU_DEATH_PLACE NFU_DEATH_DATE NFU_DEATH_LOCATION ///
			 NFU_SNCU NFU_SNCU_NUM ///
			 NFU_SNCU_ID_ADM1_B NFU_SNCU_HOSP_ADM1_B ///
			 NFU_SNCU_ID_ADM2_B NFU_SNCU_HOSP_ADM2_B ///
			 NFU_SNCU_ID_ADM3_B NFU_SNCU_HOSP_ADM3_B ///
			 NFU_SNCU_ID_ADM4_B NFU_SNCU_HOSP_ADM4_B ///
			 NFU_SNCU_ID_ADM5_B NFU_SNCU_HOSP_ADM5_B, i(PID) j(BABY_NUM)
		 
rename NFU_SNCU_ID_ADM1_B NFU_SNCU_ID_ADM1
rename NFU_SNCU_ID_ADM2_B NFU_SNCU_ID_ADM2
rename NFU_SNCU_ID_ADM3_B NFU_SNCU_ID_ADM3
rename NFU_SNCU_ID_ADM4_B NFU_SNCU_ID_ADM4
rename NFU_SNCU_ID_ADM5_B NFU_SNCU_ID_ADM5

rename NFU_SNCU_HOSP_ADM1_B NFU_SNCU_HOSP_ADM1
rename NFU_SNCU_HOSP_ADM2_B NFU_SNCU_HOSP_ADM2
rename NFU_SNCU_HOSP_ADM3_B NFU_SNCU_HOSP_ADM3
rename NFU_SNCU_HOSP_ADM4_B NFU_SNCU_HOSP_ADM4
rename NFU_SNCU_HOSP_ADM5_B NFU_SNCU_HOSP_ADM5

label variable NFU_SNCU_HOSP_ADM1 "SNCU 1st admission hosp"
label variable NFU_SNCU_HOSP_ADM2 "SNCU 2nd admission hosp"
label variable NFU_SNCU_HOSP_ADM3 "SNCU 3rd admission hosp"
label variable NFU_SNCU_HOSP_ADM4 "SNCU 4th admission hosp"
label variable NFU_SNCU_HOSP_ADM5 "SNCU 5th admission hosp"
				   
* Label long variables
*label values BDF_SEX SEX
*label value BDF_MODE_DELIVERY BDF_MODE_DELIVERY

*label values NFU_VITAL_STATUS NFU_VITAL_STATUS
*label values NFU_DISCHARGED YESNONKNA
*label values NFU_DEATH_PLACE NFU_DEATH_PLACE

* Drop non-babies 2-6 generated due to long format:
drop if FORM_BDF == 1 & BDF_BIRTH_STATUS == . & BDF_BIRTH_WEIGHT == .

* Drop babies without birth status (due to error in data collection)
drop if BDF_BIRTH_STATUS == 9

/* Drop extra ACS/EHS/MIF generated due to long format (i.e., keep 1st instance a.k.a. BABY_NUM==1)
drop if FORM_BDF != 1 & FORM_ACS1 == 1 & BABY_NUM > 1
drop if FORM_BDF != 1 & FORM_NFU  == 1 & BABY_NUM > 1
*/

* Drop non-PID
drop if PID == ""

*
* *
* * * Gestation category based on corrected EUSG or, if EUSG missing, then birthweight

gen     GEST_CAT = .
replace GEST_CAT = 9 if FORM_BDF == 1
replace GEST_CAT = 0 if GA_BIRTH_CATU == 0
replace GEST_CAT = 1 if GA_BIRTH_CATU == 1
replace GEST_CAT = 2 if GA_BIRTH_CATU == 2
replace GEST_CAT = 3 if GA_BIRTH_CATU == 3
replace GEST_CAT = 4 if GA_BIRTH_CATU == 4
replace GEST_CAT = 0 if GA_BIRTH_EUSG >= 0 & GA_BIRTH_EUSG < 24*7
replace GEST_CAT = 0 if GEST_CAT > 4 & BDF_BIRTH_WEIGHT <  1000 & BDF_BIRTH_WEIGHT != .
replace GEST_CAT = 1 if GEST_CAT > 4 & BDF_BIRTH_WEIGHT >= 1000 & BDF_BIRTH_WEIGHT <= 1500
replace GEST_CAT = 2 if GEST_CAT > 4 & BDF_BIRTH_WEIGHT >  1500 & BDF_BIRTH_WEIGHT <= 2000
replace GEST_CAT = 3 if GEST_CAT > 4 & BDF_BIRTH_WEIGHT >  2000 & BDF_BIRTH_WEIGHT <  8000

label define   GEST_CAT 0 "EEPT" 1 "EPT" 2 "LPT" 3 "Term" 4 "Invalid USG" 9 "No USG/BW"
label values   GEST_CAT GEST_CAT
label variable GEST_CAT "2 Gestation age category at birth using earliest USG or weight"


	* Old GEST_CAT ignored <28 weeks as NK. Now a separate option.
	gen     GEST_CAT_old = .
	replace GEST_CAT_old = 9 if FORM_BDF == 1
	replace GEST_CAT_old = 1 if GA_BIRTH_CATU == 1
	replace GEST_CAT_old = 2 if GA_BIRTH_CATU == 2
	replace GEST_CAT_old = 3 if GA_BIRTH_CATU == 3
	replace GEST_CAT_old = 1 if GEST_CAT_old == 9 & BDF_BIRTH_WEIGHT >= 1000 & BDF_BIRTH_WEIGHT <= 1500
	replace GEST_CAT_old = 2 if GEST_CAT_old == 9 & BDF_BIRTH_WEIGHT >  1500 & BDF_BIRTH_WEIGHT <= 2000
	replace GEST_CAT_old = 3 if GEST_CAT_old == 9 & BDF_BIRTH_WEIGHT >  2000 & BDF_BIRTH_WEIGHT <  8000

	label define   GEST_CAT_old 1 "EPT" 2 "LPT" 3 "Term" 9 "NK" 
	label values   GEST_CAT_old GEST_CAT_old
	label variable GEST_CAT_old "OLD GEST CAT"

	tab  GEST_CAT GEST_CAT_old


*
* *
* * * EPT & PT (Preterm)

gen     EPT = .
replace EPT = 1 if GEST_CAT == 1
replace EPT = 0 if GEST_CAT != 1 & GEST_CAT != .

label variable EPT "EPT, binary using EUSG or BW"

gen     PT = .
replace PT = 1 if GEST_CAT == 1 | GEST_CAT == 2
replace PT = 0 if GEST_CAT != 1 & GEST_CAT != 2 & GEST_CAT != .

label variable EPT "Preterm, binary using EUSG or BW"

*
* *
* * *
* * * *
* * * * * NFU

gen     NEEDS_NFU_MOTHER = 0
replace NEEDS_NFU_MOTHER = 1 if BDF_MNFU_CONSENT == 1

gen     NEEDS_NFU_BABY = 0
replace NEEDS_NFU_BABY = 1 if BDF_MNFU_CONSENT == 1 & BDF_BIRTH_STATUS == 1 & BDF_LEFT_STATUS != 3

label values NEEDS_NFU_BABY   BINARY
label values NEEDS_NFU_MOTHER BINARY

*
* *
* * * MORTALITY

* Age (days) at death
gen AGE_DEATH = NFU_DEATH_DATE - BDF_DT_DELIVERY
label variable AGE_DEATH "Age at death, days"

* Neonatal mortality:
gen     NNM = .
replace NNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   >= 28 & NFU_VITAL_STATUS == 1 & AGE_NFU != .
replace NNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH >= 29 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace NNM = 2 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH <= 28 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace NNM = 2 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   <= 28 & NFU_VITAL_STATUS == 2 & AGE_NFU != .
replace NNM = 2 if BDF_BIRTH_STATUS == 1 & BDF_LEFT_STATUS == 3

label variable NNM "Neonatal mortality: Liveborn, verified status at 28 days"

label define NNM 1 "Alive at 28 days" 2 "Dead at 28 days"
label values NNM NNM

* Perinatal mortality:
gen     PNM = .
replace PNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_NFU   >= 7 & NFU_VITAL_STATUS == 1 & AGE_NFU != .
replace PNM = 1 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH  > 7 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace PNM = 2 if BDF_BIRTH_STATUS == 1 & FORM_NFU == 1 & AGE_DEATH <= 7 & NFU_VITAL_STATUS == 2 & AGE_DEATH != .
replace PNM = 2 if BDF_LEFT_STATUS == 3
replace PNM = 3 if BDF_BIRTH_STATUS == 2

label variable PNM "Perinatal mortality: Verified status at 7 days"

label define PNM 1 "Alive 7d" 2 "Died 0-7d" 3 "Stillborn"
label values PNM PNM

* Any baby death
gen     ANY_BABY_DEATH = .
replace ANY_BABY_DEATH = 1 if BDF_BIRTH_STATUS == 1
replace ANY_BABY_DEATH = 2 if BDF_BIRTH_STATUS == 2
replace ANY_BABY_DEATH = 3 if NNM == 1
replace ANY_BABY_DEATH = 4 if NNM == 2
replace ANY_BABY_DEATH = 4 if PNM == 2
replace ANY_BABY_DEATH = 4 if BDF_BIRTH_STATUS == 2

label variable ANY_BABY_DEATH "Any mortality: Status at birth or 28 days"

label define ANY_BABY_DEATH 1 "Alive at birth" 2 "Stillborn" 3 "Alive at 28 days" 4 "Dead at 28 days"
label values ANY_BABY_DEATH ANY_BABY_DEATH

*
* *
* * * EXCLUSION CRITERIA

* 1) Births less than 28 weeks gestation by the earliest ultrasound are excluded. 
* 2) Births less than 1000 grams are excluded. This weight cut point is only used for babies without information from the earliest ultrasound available. 
* 3) Women who delivered at a facility outside the network of care are excluded from the main indicators. 

gen     EXCLUDE = 0
replace EXCLUDE = 1 if GA_BIRTH_EUSG < 28*7 & GA_BIRTH_EUSG != .
replace EXCLUDE = 2 if BDF_BIRTH_WEIGHT < 1000 & BDF_BIRTH_WEIGHT != . & GA_BIRTH_EUSG == .
replace EXCLUDE = 3 if FORM_BDF != 1

label variable EXCLUDE "Exclusion criteria"

label define EXCLUDE 0 "Valid, keep" 1 "Invalid GA (<28 EUSG), drop" 2 "Invalid weight (<1000) without EUSG, drop" 3 "Invalid place of birth (no BDF), drop"
label values EXCLUDE EXCLUDE

* FOR ANALYSIS:
preserve
 keep if EXCLUDE != 0
 saveold "Full_database_analysis_EXCLUDED_LONG.dta", replace version(13)
restore

* DROP THOSE TO BE EXCLUDED:
** keep if EXCLUDE == 0

*
* *
* * *
* * * *
* * * * * 

* SEPTEMBER ONWARDS OUT OF P2a:
preserve
 keep if MM >= 9 & MM != . & APP == "P2A"
 saveold "September_P2a.dta", replace
restore

drop if MM >= 9 & MM != . & APP == "P2A"

* BEFORE SEPTEMBER  OUT OF P2b:
preserve
 keep if MM < 9 & MM != . & APP == "P2B"
 saveold "September_P2b.dta", replace
restore

drop if MM < 9 & MM != . & APP == "P2B"

* * * * *
* * * * 
* * *
* *
*

*
* * BABY_ID

egen BABY_ID = concat(PID BDF_BIRTH_ORDER) if BDF_BIRTH_ORDER != .

order PID BABY_NUM BDF_BIRTH_ORDER BABY_ID COUNTRY_NUM COUNTRY CLUST_NUM CLUST_NAME HOSPNUM_BDF FORM_BDF FORM_NFU 

*
* *
* * * Save

saveold "Full_database_analysis_ALL_COUNTRIES_P2_LONG.dta", replace version(13)

*
* *
* * *
* * * *
* * * * * 
* * * * * * * MONITORING VARIABLES

clear 
cd "/Users/juha/X/WHO/WHO24/Monitoring/Data2/"
use "Full_database_analysis_ALL_COUNTRIES_P2_LONG.dta"

*
* *
* * *

gen AGE_TODAY = TODAY - BDF_DT_DELIVERY

* *
* * * Truncated Admission to Delivery

gen     admission_to_del_hours = DAYS_ADM_TO_DEL * 24
replace admission_to_del_hours = 24 if DAYS_ADM_TO_DEL > 1
replace admission_to_del_hours = 0  if DAYS_ADM_TO_DEL < 0

gen admission_to_del_hours2 = floor(admission_to_del_hours)

*
* *
* * * USG TO DELIVERY (3 GROUPS)

gen     USG_TO_BDF_BIN = ""
replace USG_TO_BDF_BIN = "Delivery day USG" if USG_TO_BDF <= 0
replace USG_TO_BDF_BIN = "USG one day before delivery" if USG_TO_BDF == 1
replace USG_TO_BDF_BIN = "USG 2+ days before delivery" if USG_TO_BDF > 1
replace USG_TO_BDF_BIN = "" if EUSG_AVAIL == 0

*
* *
* * * USG TO ADMISSION

gen USG_TO_ADM = BDF_DT_ADM - BDF_DT_EARLY_USG  if EUSG_AVAIL == 1 & BDF_DT_ADM != .

label variable USG_TO_ADM "Days from BDF EUSG to admission"

gen     USG_TO_ADM_GROUP = ""
replace USG_TO_ADM_GROUP = "Admission day"     if USG_TO_ADM <= 0
replace USG_TO_ADM_GROUP = "1 day before"      if USG_TO_ADM == 1
replace USG_TO_ADM_GROUP = "2-7 days before"   if USG_TO_ADM >= 2  & USG_TO_ADM <= 7
replace USG_TO_ADM_GROUP = "8-28 days before"  if USG_TO_ADM >= 8  & USG_TO_ADM <= 28
replace USG_TO_ADM_GROUP = "29-59 days before" if USG_TO_ADM >= 29 & USG_TO_ADM <= 59
replace USG_TO_ADM_GROUP = "60+ days before"   if USG_TO_ADM >= 60 & USG_TO_ADM != .


*
* *
* * * Weight category

gen     BW = .
replace BW = 1 if BDF_BIRTH_WEIGHT > 0     & BDF_BIRTH_WEIGHT <  500
replace BW = 2 if BDF_BIRTH_WEIGHT >= 500  & BDF_BIRTH_WEIGHT < 1000
replace BW = 3 if BDF_BIRTH_WEIGHT >= 1000 & BDF_BIRTH_WEIGHT < 1500
replace BW = 4 if BDF_BIRTH_WEIGHT >= 1500 & BDF_BIRTH_WEIGHT < 2000
replace BW = 5 if BDF_BIRTH_WEIGHT >= 2000 & BDF_BIRTH_WEIGHT < 2500
replace BW = 6 if BDF_BIRTH_WEIGHT >= 2500 & BDF_BIRTH_WEIGHT < 8000
replace BW = 7 if BDF_BIRTH_WEIGHT >= 8000
replace BW = 8 if BDF_BIRTH_WEIGHT == 8888
replace BW = 9 if BDF_BIRTH_WEIGHT == 9999 | BDF_BIRTH_WEIGHT == .

label define BW 1 "-499" 2 "500-999" 3 "1,000-1,499" 4 "1,500-1,999" 5 "2,000-2,499" 6 "2,500-" 7 "over" 8 "NK" 9 "Missing"
label values BW BW

*
* *
* * * Weigh precision

gen rounded_1    = round(BDF_BIRTH_WEIGHT, 1)
gen rounded_5    = round(BDF_BIRTH_WEIGHT, 5)
gen rounded_10   = round(BDF_BIRTH_WEIGHT, 10)
gen rounded_50   = round(BDF_BIRTH_WEIGHT, 50)
gen rounded_100  = round(BDF_BIRTH_WEIGHT, 100)
gen rounded_500  = round(BDF_BIRTH_WEIGHT, 500)
gen rounded_1000 = round(BDF_BIRTH_WEIGHT, 1000)

gen     weight_level = .
replace weight_level = 1 if BDF_BIRTH_WEIGHT == rounded_1
replace weight_level = 2 if BDF_BIRTH_WEIGHT == rounded_5
replace weight_level = 3 if BDF_BIRTH_WEIGHT == rounded_10
replace weight_level = 4 if BDF_BIRTH_WEIGHT == rounded_50
replace weight_level = 5 if BDF_BIRTH_WEIGHT == rounded_100
replace weight_level = 6 if BDF_BIRTH_WEIGHT == rounded_500
replace weight_level = 7 if BDF_BIRTH_WEIGHT == rounded_1000
replace weight_level = 8 if BDF_BIRTH_WEIGHT == . | BDF_BIRTH_WEIGHT == 8888 | BDF_BIRTH_WEIGHT == 9999

drop rounded_1 rounded_5 rounded_10 rounded_50 rounded_100 rounded_500 rounded_1000

label define weight_level 1 "1 g" 2 "5 g" 3 "10 g" 4 "50 g" 5 "100 g" 6 "500 g" 7 "1000 g" 8 "NK"
label values weight_level weight_level
label variable weight_level "Weight measured to accuracy"

*
* *
* * * Missing BDF

list COUNTRY PID BABY_NUM FORM_NFU NFU_DT_FILL Submit_NFU if HOSPNUM==.
drop if HOSPNUM == .

*
* *
* * * DROP DROPPED CLUSTERS

* Bangaldesh drops clusters: 08 Habiganj & 11 Chandpur
drop if COUNTRY ==  "BD" & CLUST_NUM  == 8
drop if COUNTRY ==  "BD" & CLUST_NUM  == 11

* EEthiopia drops clusters 02 Mekelle, 04 Bahir Dar, and 07 Adama.
drop if COUNTRY ==  "ET" & CLUST_NUM  == 2
drop if COUNTRY ==  "ET" & CLUST_NUM  == 4
drop if COUNTRY ==  "ET" & CLUST_NUM  == 7

* Pakistan drop cluster 05 Chakwal & 11 Tharparkar
drop if COUNTRY ==  "PK" & CLUST_NUM  == 5
drop if COUNTRY ==  "PK" & CLUST_NUM  == 11

* Nigeria drop cluster 04 Jigawa & 11 Plateau
drop if COUNTRY ==  "NG" & CLUST_NUM  == 4
drop if COUNTRY ==  "NG" & CLUST_NUM  == 11


*
* *
* * *
* * * *
* * * * * SAVE STATA

saveold "Full_database_analysis_ALL_COUNTRIES_P2_LONG_X.dta", replace version(13)

* * *
* *
*

*
* * 
* * * Reability edits for the monitoring report

replace COUNTRY = "Bangladesh" if COUNTRY == "BD"
replace COUNTRY = "Ethiopia"   if COUNTRY == "ET"
replace COUNTRY = "Nigeria"    if COUNTRY == "NG"
replace COUNTRY = "Pakistan"   if COUNTRY == "PK"

gen     Facility = "Core" if ACS_IF == 1
replace Facility = "NOC"  if ACS_IF == 2

gen     CLUS = string(CLUST_NUM) + " " + CLUST_NAME
replace CLUS = "0" + CLUS if CLUST_NUM < 10

gen     HOSP = string(HOSPNUM_BDF) + " " + HOSPITAL_NAME_BDF
replace HOSP = "0" + HOSP if HOSPNUM_BDF < 10

*
* *
* * * SAVE TO R (Monitoring report)

export delimited using "Full_database_analysis_ALL_COUNTRIES_P2_LONG_M.csv", replace 

*
* *
* * * SAVE TO R (Delay from delivery to submit to transfer)

export delimited COUNTRY MM Facility PID CLUST_NUM CLUS HOSPNUM_BDF ///
      HOSP BDF_DT_DELIVERY BDF_TM_DELIVERY_HH BDF_TM_DELIVERY_MM NFU_DT_FILL ///
	  Submit_BDF Transfer_BDF Submit_NFU Transfer_NFU using "P2_del_sub_tra.csv", replace

*end

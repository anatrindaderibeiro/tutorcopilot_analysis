*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Clean main session-level variables and save dataset, create descriptive tables 
*
* Programming:
*   Stata Version:  Stata 17.0 SE
*   Original Author: CDR (July 25, 2024)
*   Last Modified:  ATR (May 24, 2025)
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* Set the critical parameters of the computing environment.
*-------------------------------------------------------------------------------
* Specify the version of Stata for this analysis [CHANGE IF OLDER VERSION]:
    version 15
  
* Clear all computer memory and delete any existing stored graphs and matrices:
    clear all
	
*-------------------------------------------------------------------------------
* Set the Filepaths and Switches
*-------------------------------------------------------------------------------	
// Run globals

*Globals for paths - Double click dofile from folder for globals to work without manually setting directory
if "$root"=="" {
global root = substr("`c(pwd)'", 1, strpos("`c(pwd)'","scripts") - 1 )
}
*-or manually change root directory here:
*global root "$root_dir/Shared drives/NSSA Research/FEV/FEV_AICopilot/data/replication/" 

run "$root/scripts/stata/_global_paths.do"


*-------------------------------------------------------------------------------
**# IMPORT
*-------------------------------------------------------------------------------
import delimited "$datafiles/filtered_copilot_data", varnames(1) clear

*-------------------------------------------------------------------------------
**# clean
*-------------------------------------------------------------------------------

count // 4,136

gen treat = 1 if tutor_copilot_assignment == "TREATMENT"
replace treat = 0 if tutor_copilot_assignment == "CONTROL"

egen race = group(student_race_ethnicity)
replace race = 8 if student_race_ethnicity == ""

egen strata = group(stratum)

destring exit_ticket_passed, replace force
tab exit_ticket_passed, m

// destring session rating 
destring session_rating tutor_rating student_survey_understanding_ove student_survey_tutor_cared_about student_survey_know_can_learn, replace force

// de-stringing and imputing
// tutor_qa
destring tutor_qa_score, replace force // 4 missing

// impute with regression
regress tutor_qa_score tutor_is_female tutor_age
predict tutor_qa_score_pred, xb
// only use imputed value if it doesn't exist.
replace tutor_qa_score_pred = tutor_qa_score if !missing(tutor_qa_score)
count // 4136

// winter map
destring student_winter_map_2324, replace force // 957 missing

// impute student covariates
regress student_winter_map_2324 student_is_female race student_free_reduced_lunch student_special_education student_lep
predict moy_map2324_pred, xb
// only use imputed value if it doesn't exist.
replace moy_map2324_pred = student_winter_map_2324 if !missing(student_winter_map_2324)
count // 4136

// tutor_QA imputation
		destring tutor_qa_score, replace
		
		regress tutor_qa_score tutor_is_female tutor_age
		predict tutor_qa_pred, xb
		replace tutor_qa_pred = tutor_qa_score if !missing(tutor_qa_score)




* Clean and save
********************************************************************************

cap rename participation_points_standardize particip_points_std
cap rename exit_ticket_attempted exitticket_attempt
cap rename exit_ticket_passed exitticket_passed_c
cap rename exit_ticket_passed_inclusive exitticket_passed_u
cap rename student_survey_understanding_ov st_survey_underst
cap rename student_survey_tutor_cared_about st_survey_tcared
cap rename student_survey_know_can_learn st_survey_canlearn
cap rename used_tutor_copilot used_tc

label var treat "Treatment"

save "$datafiles/filtered_copilot_data_foranalysis.dta", replace



* Descriptive session tables
********************************************************************************

* Number of sessions per grade
tab grade, m


* Tutor characteristics as predictors for TC use 

estimates clear
eststo clear
local c = 0
	
foreach depvar in used_tc num_tutor_copilot_use {
	local c = `c'+1
    eststo a`c':  reg `depvar' tutor_is_female tutor_age tutor_qa_pred if treat==1 , cluster(tutor_id)
}

* 
esttab  using "$output/regs_session_tc_use.tex", ///
se label b(a2) title("") mtitles("\shortstack{Used}" "\shortstack{Number of Uses}" ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(tutor_is_female tutor_age tutor_qa_pred) stats( N,  /// 
label("N" ) fmt( %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. ") ///
nonotes






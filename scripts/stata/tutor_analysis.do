*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Tutor Analysis (attrition, balance and survey outcome tables)
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
* Save Tutor Assignment and Survey data
*-------------------------------------------------------------------------------

import delimited "$rawdata/tutor/tutor_survey.csv", clear

gen treat = tutor_copilot_assignment=="Treatment"
rename tutorusername tutor_user_name

save "$datafiles/tutor_assignment.dta", replace


*-------------------------------------------------------------------------------
* Load and join session data
*-------------------------------------------------------------------------------

use "$datafiles/filtered_copilot_data_foranalysis.dta", clear 
count // 4,136

* Predicting Tutor CoPilot use from tutor characteristics. 
reg used_tc tutor_is_female tutor_age tutor_qa_score if treat==1, cluster(tutor_id)
reg num_tutor_copilot_use tutor_is_female tutor_age tutor_qa_score if treat==1, cluster(tutor_id)


collapse (count) session_count=session_id (sum) actual_session_duration, by(tutor_id tutor_user_name tutor_is_female tutor_qa_score tutor_qa_pred tutor_age tutor_copilot_assignment)
duplicates drop

joinby tutor_user_name using "$datafiles/tutor_assignment.dta", unmatched(both) _merge(_merge) 
tab _merge tutor_copilot_assignment, m // 2 tutors not in original assignment list but in session data, one treatment and one control
count // 876

*drop tutors who did not answer pre-study survey
keep if pre_survey_completed=="True"
count // 872

* Create attrition vars
gen post_survey_no = post_survey_completed=="False"
gen tutor_nosessions = _merge==2
drop _merge

gen session_sample = tutor_nosessions==0 
gen post_survey_sample = post_survey_completed=="True" & tutor_nosessions==0


* Create/combine balance check vars 
replace tutor_qa_score = averageqascore if tutor_qa_score==.
tab tutor_qa_score, m

replace tutor_age = ageinthesystem if tutor_age==.
tab tutor_age, m

replace tutor_is_female = 1 if gender=="Female"
replace tutor_is_female = 0 if gender=="Male"
tab tutor_is_female, m 


* Differential attrition table
*********************************************

label var treat "Treatment"
label var tutor_qa_score "Tutor Quality Score"
label var tutor_age "Tutor Experience (Months)"
label var tutor_is_female "Tutor Gender: Female"

estimates clear
eststo clear
local c = 0

foreach depvar in tutor_nosession post_survey_no {
	local c = `c'+1
    eststo a`c':  reg `depvar' treat tutor_qa_score tutor_age tutor_is_female, r
}

esttab a1 a2 using "$output/regs_tutor_attrition.tex", ///
se label b(a2) title("") mtitles("\shortstack{Session Attrition}" "\shortstack{Survey Attrition}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(*) stats( N, /// 
label( "N" ) fmt( %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses.  ") ///
nonotes



* Balance checks
*********************************************

// pre-study sample
ttest tutor_is_female, by(treat)
ttest tutor_age, by(treat)
ttest tutor_qa_score, by(treat)

// session sample
ttest tutor_is_female if tutor_nosessions ==0, by(treat)
ttest tutor_age if tutor_nosessions ==0, by(treat)
ttest tutor_qa_score  if tutor_nosessions ==0, by(treat)
ttest session_count  if tutor_nosessions ==0, by(treat)
ttest actual_session_duration  if tutor_nosessions ==0, by(treat)

// survey sample (conditional on session sample)
ttest tutor_is_female if post_survey_no ==0 & tutor_nosessions ==0, by(treat)
ttest tutor_age if post_survey_no ==0 & tutor_nosessions ==0, by(treat)
ttest tutor_qa_score  if post_survey_no ==0 & tutor_nosessions ==0, by(treat)
ttest session_count  if post_survey_no ==0 & tutor_nosessions ==0, by(treat)
ttest actual_session_duration  if post_survey_no ==0 & tutor_nosessions ==0, by(treat)



* Tutor Survey outcomes
*********************************************

// destring outcomes
destring post_study_student_learn_more_th post_study_confident_recognize_m post_study_effective_help_fix_mi more_effective_help_fix_mistake, replace force

rename post_study_student_learn_more_th post_study_st_learn 
rename post_study_confident_recognize_m post_study_confident
rename post_study_effective_help_fix_mi post_study_effective
rename more_effective_help_fix_mistake  more_effective


	
estimates clear
eststo clear
local c = 0
local multhyptest = ""
local multhyptest_ind = " "

	
foreach depvar in post_study_st_learn post_study_confident post_study_effective more_effective {
	local c = `c'+1
	if `c'>1 { 
		local multhyptest_ind = "`multhyptest_ind', " 
	}
    eststo a`c':  reg `depvar' treat tutor_qa_pred tutor_age tutor_is_female if post_survey_sample==1 , r
	
	local multhyptest = "`multhyptest'  (`="`e(cmdline)'"')"
	local multhyptest_ind = "`multhyptest_ind'  treat "
	
	margins if treat == 0
	estadd scalar cmean= r(table)[1,1]
	scalar csd= r(table)[2,1]
	estadd local csd= "(`:di %4.3f `=csd'')" : a`c'
}

** Romano-Wolf P-values
di "`multhyptest'"
rwolf2 `multhyptest', indepvars("`multhyptest_ind'")  reps(100) usevalid
mat rwolf = e(RW)
mat list rwolf
local rwrow = 0
forval j=1/`=`c''  {
	local rwrow = `rwrow' +1 
 estadd local rw_pval = "[`:di %4.3f rwolf[`rwrow',3]']"	: a`j'
 di `=`rwrow''
 }
local c = `c'+1


* 
esttab  using "$output/regs_tutor_survey.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{Do you agree or disagree \\ with this statement: My \\ students learn more by \\ making mistakes ?}" "\shortstack{How confident are you \\ at recognizing the kind \\ of mathematical \\ mistakes students \\ are making? }"  "\shortstack{How effective are you \\ at helping students \\ fix their mistakes? }" "\shortstack{How much more or less \\ effective are you at \\ helping student fix their \\ mistakes now than you \\were three months ago?}" ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(cmean csd rw_pval  r2 N,  /// 
label("Control Mean" " " "Romano-Wolf p-val" "R-Square" "N" ) fmt(%9.3f %9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes


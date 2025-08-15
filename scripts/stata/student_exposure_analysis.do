*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Student exposure effect on achievement analysis 
*
* Programming:
*   Stata Version:  Stata 17.0 SE
*   Original Author: ATR (July 24, 2025)
*   Last Modified:  ATR (July 24, 2025)
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


global covars = "i.student_is_female i.race i.student_free_reduced_lunch i.student_special_education i.student_lep moy_map2324_pred i.strata"


*-------------------------------------------------------------------------------
**# IMPORT
*-------------------------------------------------------------------------------
import delimited "$rawdata/student/student_achievement.csv", varnames(1) clear

*-------------------------------------------------------------------------------
**# clean: variables of interest
*-------------------------------------------------------------------------------

summarize // 1787 students

gen is_female = 1 if student_is_female == 1
replace is_female = 0 if student_is_female == 0
replace is_female = 2 if missing(student_is_female)

encode student_race_ethnicity, gen(race_ethnicity)
replace race_ethnicity = 8 if missing(race_ethnicity)

gen has_frl = 1 if student_free_reduced_lunch == 1
replace has_frl = 0 if student_free_reduced_lunch == 0
replace has_frl = 2 if missing(student_free_reduced_lunch)

gen is_sped = 1 if student_special_education == 1
replace is_sped = 0 if student_special_education == 0
replace is_sped = 2 if missing(student_special_education)

gen is_lep = 1 if student_lep == 1
replace is_lep = 0 if student_lep == 0
replace is_lep = 2 if missing(student_lep)

* Add fixed effects grade x school
keep if inlist(grade_level, "3rd", "4th", "5th", "6th")
gen grade = substr(grade_level, 1, 1)

egen strata = group(grade school_id)

count
summarize


* Destring outcomes
destring math_map_spring_24 reading_map_spring_24, replace force

tostring student_id_ecisd, replace


save "$datafiles/student_achievement_2023-24.dta", replace

*-------------------------------------------------------------------------------
**# Import and merge session data 
*-------------------------------------------------------------------------------

import delimited "$rawdata/sessions/tutor_copilot_session_level", varnames(1) clear

// recoding
gen treat = 1 if tutor_copilot_assignment == "TREATMENT"
replace treat = 0 if tutor_copilot_assignment == "CONTROL"
replace treat = . if tutor_is_floating_pool == 1 |  tutor_location=="FLT" 
tab treat, m

egen race = group(student_race_ethnicity)
replace race = 8 if student_race_ethnicity == ""


collapse (count) exp_session_count = treat (sum) treat_count=treat, by(student_id)
drop if exp_session_count==0 // exclude students who did not have at least one tutoring session with a randomized tutor

joinby student_id using "$datafiles/student_achievement_2023-24.dta", unmatched(none)



* Create imputed values for baseline achievement when missing
regress winter_map_2324 i.is_female i.race_ethnicity i.has_frl i.is_sped is_lep 
predict winter_map_2324_pred, xb
replace winter_map_2324_pred = winter_map_2324 if !missing(winter_map_2324)

* Standardize achievement variables
egen math_map_spring_24_std = std(math_map_spring_24)
egen winter_map_2324_pred_std = std(winter_map_2324_pred)
egen winter_map_2324_std = std(winter_map_2324)
egen fall_map_2324_std = std(fall_map_2324)



histogram treatment_perc if exp_session_count>0, bin(20) frequency ///
xlabel(0(0.1)1, grid) ///
ylabel(, angle(horizontal)) ///
xtitle("Proportion of Treatment Sessions") ///
ytitle("Frequency") ///
title("Distribution of Student Treatment Exposure") ///
legend(off) ///
lcolor(white) fcolor(navy) ///
scheme(s2mono)

graph export "$output/treatment_exposure.png", replace


* Regressions 

estimates clear
eststo clear
local c = 0

** with imputed
foreach spec in "treatment_perc" "treatment_perc num_sessions" "c.treatment_perc##c.num_session" {
	local c = `c'+1
    eststo a`c': areg math_map_spring_24_std `spec' i.is_female i.race_ethnicity i.has_frl i.is_sped i.is_lep c.winter_map_2324_pred_std if exp_session_count>0, a(strata) robust

}

** without imputed
foreach spec in "treatment_perc" "treatment_perc num_sessions" "c.treatment_perc##c.num_session" {
	local c = `c'+1
    eststo a`c': areg math_map_spring_24_std `spec' i.is_female i.race_ethnicity i.has_frl i.is_sped i.is_lep c.winter_map_2324_std if exp_session_count>0, a(strata) robust

}

esttab a1 a2 a3 a4 a5 a6 using "$output/regs_treatment_exposure.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{Math MAP (std) \\ With Imputation}" "\shortstack{Math MAP (std) \\ With Imputation}"  "\shortstack{Math MAP (std) \\ With Imputation}" "\shortstack{Math MAP (std) \\ Without Imputation}" "\shortstack{Math MAP (std) \\ Without Imputation}" "\shortstack{Math MAP (std) \\ Without Imputation}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treatment_perc num_sessions c.treatment_perc#c.num_sessions) ///
stats(N, label( "N" ) fmt( %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes


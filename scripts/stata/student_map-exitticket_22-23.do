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
**# IMPORT and  Clean FEV Session data 2022-23
*-------------------------------------------------------------------------------

import delimited "$rawdata/extensions/2022-23_MAP_exittickets/Ector County Session History AY22-23.csv", delimiter(comma) bindquote(strict) varnames(1) stripquote(no) emptylines(include) asdouble maxquotedrows(200) clear
* Filter obs of interest

drop if session_id==. //1 obs deleted
count // 48,038

tab subject_name, m
keep if subject_name=="Math" //restrict analysis sample to math sessions only
count // 29,689

tab studentgrade, m
keep if inlist(studentgrade, "3rd", "4th", "5th", "6th", "7th", "8th") //restrict to grades that used tutor copilot
count // 28,286 3-8, 19,460 3-6

tab session_status, m
keep if session_status=="Completed"
count // 13,122 3-8, 10,992 3-6

* Check dates range
gen session_date = date(word(starttime, 1), "MDY")
format session_date %td
tab session_date, m // Aug 23 2022 - May 18 2023

* Create district student id
gen student_id_ecisd = substr(studentusername, 1, 6)
destring student_id_ecisd, replace force
drop if student_id_ecisd==.

rename student_id student_id_fev


* Aggregate exit tickets at the student level
gen exit_ticket_passed = exit_ticket_score>66 & exit_ticket_score!=.
collapse (sum) exit_ticket_passed (count) session_count = session_id, by(student_id_ecisd student_id_fev)
count // 761 g3-8 , 517 g3-6 

save "$datafiles/student_exittickets22-23.dta", replace


*-------------------------------------------------------------------------------
* Clean FEV MAP data
*-------------------------------------------------------------------------------

import excel "$rawdata/extensions/2022-23_MAP_exittickets\Ector County Matched Benchmark Data AY22-23 F-S.xlsx", sheet("Ector County Matched Benchmark ") firstrow case(lower) clear


count //26,370

tab subject, m
keep if subject == "Mathematics"
count //11,860

tab grade, m
destring grade, replace force
keep if inrange(grade, 3, 6)
count //10,402 g3-8, 6,925 g3-6

rename studentid student_id_ecisd
keep student_id_ecisd grade subject fallrit springrit fsgrowth 
duplicates drop

joinby student_id_ecisd using "$datafiles/student_exittickets22-23.dta", unmatched(none)


*-------------------------------------------------------------------------------
* Clean FEV MAP data
*-------------------------------------------------------------------------------
drop if springrit==. | fallrit==. | exit_ticket_passed==.


egen springrit_std = std(springrit)
egen fallrit_std = std(fallrit)

reg springrit_std fallrit_std exit_ticket_passed, r //


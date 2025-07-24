*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Create main session-level results with reviewer suggested random effects (without multiple hypothesis testing because it takes a very long time to run)
*
* Programming:
*   Stata Version:  Stata 17.0 SE
*   Original Author: CDR (July 25, 2024)
*   Last Modified:  ATR (May 16, 2025)
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
**# Load
*-------------------------------------------------------------------------------
use "$datafiles/filtered_copilot_data_foranalysis.dta", clear

*-------------------------------------------------------------------------------
**# Tables
*-------------------------------------------------------------------------------
estimates clear
eststo clear
local c = 0

** mixed effects linear itt
foreach depvar in participation_points particip_points_std exitticket_attempt exitticket_passed_c exitticket_passed_u st_survey_underst st_survey_tcared st_survey_canlearn session_rating tutor_rating {
	local c = `c'+1
    eststo a`c': mixed `depvar' treat i.student_is_female i.race i.student_free_reduced_lunch i.student_special_education i.student_lep moy_map2324_pred i.strata || tutor_id: || student_id:
		
	margins if treat == 0
	estadd scalar cmean= r(table)[1,1]
	scalar csd= r(table)[2,1]
	estadd local csd= "(`:di %4.3f `=csd'')" : a`c'
}

** mixed effects logit
foreach depvar in exitticket_attempt exitticket_passed_c exitticket_passed_u  {
	local c = `c'+1
	eststo a`c': melogit `depvar' treat i.student_is_female i.race i.student_free_reduced_lunch i.student_special_education i.student_lep moy_map2324_pred i.strata || tutor_id: || student_id:
	
	estadd scalar oddsratio = exp(e(b)[1,1])
	scalar zval = r(table)[3,1]
	estadd local zval= "`:di %4.3f `=zval''" : a`c'
}


/*
di "`multhyptest'"
rwolf2 `multhyptest', indepvars("`multhyptest_ind'") reps(100) usevalid
mat rwolf = e(RW)
mat list rwolf
local rwrow = 0
forval j=1/`=`c''  {
	local rwrow = `rwrow' +1 
 estadd local rw_pval = "[`:di %4.3f rwolf[`rwrow',3]']"	: a`j'
 di `=`rwrow''
 }
local c = `c'+1
*/


* Mixed Effects - Linear ITT part 1
esttab a1 a2 a3 a4 a5 using "$output/regs_melinear_itt_1.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{Participation \\ Points}" "\shortstack{Participation \\ Points \\ Standardized}"  "\shortstack{Exit Tickets \\ Attempted}" "\shortstack{Exit Tickets \\ Passed \\ Conditional}" "\shortstack{Exit Tickets \\ Passed \\ Unconditional}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(cmean csd  r2 N,  /// 
label("Control Mean" " "  "R-Square" "N" ) fmt(%9.3f %9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes

* Mixed Effects - Linear ITT part 2
esttab a6 a7 a8 a9 a10 using "$output/regs_melinear_itt_2.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{My Tutor cared about \\ understanding \\ math over \\ memorizing \\ the solution.}" "\shortstack{ My tutor cared \\ about how well I \\ do in math.}"  "\shortstack{Even when math \\ is hard, I know \\ I can learn it.}" "\shortstack{Session \\ Rating}" "\shortstack{Tutor \\ Rating}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(cmean csd  r2 N,  /// 
label("Control Mean" " "  "R-Square" "N" ) fmt(%9.3f %9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes

* Mixed Effects - Logit
esttab a11 a12 a13 using "$output/regs_melogit.tex", ///
se label b(a2) title("Title") mtitles( "\shortstack{Exit Tickets \\ Attempted}" "\shortstack{Exit Tickets \\ Passed \\ Conditional}" "\shortstack{Exit Tickets \\ Passed \\ Unconditional}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(rw_pval zval oddsratio N,  /// 
label("Romano-Wolf p-val" "Z" "Odds Ratio" "N" ) fmt(%9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes



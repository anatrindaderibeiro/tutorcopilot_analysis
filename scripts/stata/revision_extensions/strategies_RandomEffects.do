*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Create main strategy use results with reviewer suggested random effects (without multiple hypothesis testing because it takes a very long time to run)
*
* Programming:
*   Stata Version:  Stata 17.0 SE
*   Original Author: ATR (June 11, 2025)
*   Last Modified:  ATR (July 22, 2025)
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
import delimited "$datafiles\messages\annotated_strategies.csv", bindquote(strict) 


gen treat =  tutor_copilot_assignment=="TREATMENT"
gen tutor_student = string(tutor_id) + "_" + string(student_id)


*Label

label var strategies2 "Ask Question to Guide Thinking"
label var strategies4 "Give Solution Strategy"
label var strategies5 "Prompt Student to Explain"
label var strategies6 "Encourage Student in Generic Way"
label var strategies7 "Affirm Student's Correct Attempt"
label var strategies8 "Give Away Answer/Explanation"
label var strategies9 "Ask Student to Retry"

*-------------------------------------------------------------------------------
**# Tables
*-------------------------------------------------------------------------------

global strategies "strategies5 strategies2 strategies7 strategies9 strategies8 strategies4 strategies6"



estimates clear
eststo clear
local c = 0
local coefplot_list = ""


** mixed effects logit
foreach depvar in $strategies {
	local c = `c'+1
	eststo `depvar': melogit `depvar' treat  || tutor_id: || student_id:
	
	estadd scalar oddsratio = exp(e(b)[1,1])
	scalar zval = r(table)[3,1]
	estadd local zval= "`:di %4.3f `=zval''" : `depvar'
	
	local coefcolor = cond( `=r(table)[4,1]'>0.05, "gray", cond(`=e(b)[1,1]'<0,  "blue", "red"))
	local coefplot_list = "`coefplot_list' (`depvar', bcolor(`coefcolor'))"
}


* Mixed Effects - Strategies
esttab $strategies using "$output/regs_melogit_strategies.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{Prompt Student \\ to Explain}" "\shortstack{Ask Question to \\ Guide Thinking}"  "\shortstack{Affirm Student's \\ Correct Attempt}" "\shortstack{Ask Student \\ to Retry}" "\shortstack{Give Away \\ Answer/Explanation}" "\shortstack{Give Solution \\ Strategy}" "\shortstack{Encourage Student \\ in Generic Way}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(zval oddsratio N,  /// 
label("Z" "Odds Ratio" "N" ) fmt(%9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. ") ///
nonotes




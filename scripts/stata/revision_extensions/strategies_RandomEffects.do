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
import delimited "$datafiles\messages\annotated_huggingface\strategy_classified.csv", bindquote(strict) clear


joinby session_id using "$datafiles/filtered_copilot_data_foranalysis.dta", unmatched(both) _merge(_merge)
tab _merge
keep if _merge==3




*Label

label var strategy_askquestion_class "Ask Question to Guide Thinking" 		 
label var strategy_solutionstrategy_class "Give Solution Strategy" 			 
label var strategy_promptexplanation_class "Prompt Student to Explain"		 
label var strategy_encouragestudent_class "Encourage Student in Generic Way"  
label var strategy_affirmcorrect_class "Affirm Student's Correct Attempt"	 
label var strategy_answerexplanation_class "Give Away Answer/Explanation" 	 
label var strategy_promptretry_class "Ask Student to Retry" 				

foreach i in "promptexplanation" "askquestion" "affirmcorrect" "promptretry" "answerexplanation" "solutionstrategy" "encouragestudent" {
	rename strategy_`i'_class s_`i'
}

																	
*-------------------------------------------------------------------------------
**# Tables
*-------------------------------------------------------------------------------

global strategies "s_promptexplanation s_askquestion s_affirmcorrect s_promptretry s_answerexplanation s_solutionstrategy s_encouragestudent"


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




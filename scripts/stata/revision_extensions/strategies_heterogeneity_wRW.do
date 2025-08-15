*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Create main strategy use results with and without student-tutor pair clustering and with multiple hypothesis testing
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



preserve
keep tutor_id tutor_qa_score_pred tutor_age
duplicates drop
sum tutor_qa_score_pred , d // median = 0.42
sum tutor_age, d // median = 20

restore


xtile tutor_qa_score_pred_tercile = tutor_qa_score_pred, n(3)
xtile tutor_age_tercile = tutor_age, n(3)

*-------------------------------------------------------------------------------
**# Tables
*-------------------------------------------------------------------------------

global strategies "s_promptexp s_askq s_affirmcorrect s_promptretry s_answerexp s_solutionstrat s_encouragestu"


estimates clear
eststo clear
local c = 0
local multhyptest = ""
local multhyptest_ind = " "


foreach group in "Low" "Medium" "High" {

	if "`group'"== "Low" {
		local val = 1
	}
	if "`group'"== "Medium" {
		local val = 2
	}
	if "`group'"== "High" {
		local val = 3
	}

	foreach heterog in tutor_qa_score_pred tutor_age {
		if "`heterog'" == "tutor_qa_score_pred" {
			local type = "Quality Rating Score"
			local shorttype = "qs"
		}
		if "`heterog'" == "tutor_age" {
			local type = "Experience"
			local shorttype = "exp"
		}	
		
local title  "`group' `type' Tutors"


** logit with cluster

foreach depvar in $strategies {
	local c = `c'+1
	if `c'>1 { 
		local multhyptest_ind = "`multhyptest_ind', " 
	}
*table set up
    eststo `depvar'_`shorttype'_`group':  logit `depvar' treat if `heterog'_tercile == `val', cluster(student_tutor)
	estadd scalar oddsratio = exp(e(b)[1,1])
	scalar zval = r(table)[3,1]
	estadd local zval= "`:di %4.3f `=zval''" : `depvar'_`shorttype'_`group'


	local multhyptest = "`multhyptest'  (`="`e(cmdline)'"')"
	local multhyptest_ind = "`multhyptest_ind'  treat "
}
	
global table_list_`shorttype'_`group' = " `table_list_`shorttype'_`group'' "

}
}

****************************************************************************************



** Romano-Wolf P-values
di "`multhyptest'"
rwolf2 `multhyptest', indepvars("`multhyptest_ind'") cluster(student_tutor) reps(100) usevalid
mat rwolf = e(RW)
mat list rwolf

local rwrow = 0
local table_list_`shorttype'_`group' = ""


foreach group in "Low" "Medium" "High" {
	local title  "`group' `type' Tutors"

	if "`group'"== "Low" {
		local val = 1
	}
	if "`group'"== "Medium" {
		local val = 2
	}
		if "`group'"== "High" {
		local val = 3
	}

	foreach heterog in tutor_qa_score_pred tutor_age {
		if "`heterog'" == "tutor_qa_score_pred" {
			local type = "Quality Rating Score"
			local shorttype = "qs"
		}
		if "`heterog'" == "tutor_age" {
			local type = "Experience"
			local shorttype = "exp"
		}	


	foreach depvar in $strategies {
		local rwrow = `rwrow' +1 
		cap estadd local rw_pval = "[`:di %4.3f rwolf[`rwrow',3]']"	: `depvar'_`shorttype'_`group'
		di `=`rwrow''
		
		local table_list_`shorttype'_`group' = " `table_list_`shorttype'_`group'' `depvar'_`shorttype'_`group' "
		}



* Logit with cluster - Strategies
esttab `table_list_`shorttype'_`group'' using "$output/regs_logitcluster_strategies_`shorttype'_`group'.tex", ///
se label b(a2) title("`title'") mtitles("\shortstack{Prompt Student \\ to Explain}" "\shortstack{Ask Question to \\ Guide Thinking}"  "\shortstack{Affirm Student's \\ Correct Attempt}" "\shortstack{Ask Student \\ to Retry}" "\shortstack{Give Away \\ Answer/Explanation}" "\shortstack{Give Solution \\ Strategy}" "\shortstack{Encourage Student \\ in Generic Way}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(rw_pval zval oddsratio N,  /// 
label("Romano-Wolf p-val" "Z" "Odds Ratio" "N" ) fmt(%9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Student-tutor pair clustered standard errors are shown in parentheses. ") ///
nonotes


}
}






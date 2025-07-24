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
import delimited "$datafiles\messages\annotated_strategies.csv", bindquote(strict) clear


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


joinby session_id using "$datafiles/filtered_copilot_data_foranalysis.dta", unmatched(master) _merge(_merge)
tab _merge
drop _merge

preserve
keep tutor_id tutor_qa_score_pred tutor_age
duplicates drop
sum tutor_qa_score_pred , d // median = 0.42
sum tutor_age, d // median = 20

restore



*-------------------------------------------------------------------------------
**# Tables
*-------------------------------------------------------------------------------

global strategies "strategies5 strategies2 strategies7 strategies9 strategies8 strategies4 strategies6"


foreach group in "Below" "Above" {
	if "`group'"== "Below" {
		local sign  "<"
		local title  "Below median `type' tutors"
	}
	if "`group'"=="Above" {
		local sign = ">="
		local title = "Above median `type' tutors"
	}

	foreach heterog in tutor_qa_score_pred tutor_age {
		if "`heterog'" == "tutor_qa_score_pred" {
			local restriction = "tutor_qa_score_pred `sign' 0.42"
			local type = "quality rating"
		}
		if "`heterog'" == "tutor_age" {
			local restriction = "tutor_age `sign' 20"
			local type = "experience"
		}	

di `"`group'"'
di "`sign'"
di "`type'"

estimates clear
eststo clear
local c = 0
local multhyptest = ""
local multhyptest_ind = " "


** logit with cluster
local coefplot_list = ""

foreach depvar in $strategies {
	local c = `c'+1
	if `c'>1 { 
		local multhyptest_ind = "`multhyptest_ind', " 
	}
    eststo `depvar':  logit `depvar' treat if `restriction', cluster(tutor_student)
	local a`c' = `depvar'
	
	estadd scalar oddsratio = exp(e(b)[1,1])
	scalar zval = r(table)[3,1]
	estadd local zval= "`:di %4.3f `=zval''" : `depvar'
	
	local coefcolor = cond( `=r(table)[4,1]'>0.05, "gray", cond(`=r(table)[1,1]'<0,  "blue", "red"))
	local coefplot_list = "`coefplot_list' (`depvar', bcolor(`coefcolor'))"

	local multhyptest = "`multhyptest'  (`="`e(cmdline)'"')"
	local multhyptest_ind = "`multhyptest_ind'  treat "
	}
	

	
global coefplot_list " `coefplot_list' "



** Romano-Wolf P-values
di "`multhyptest'"
rwolf2 `multhyptest', indepvars("`multhyptest_ind'") cluster(tutor_student) reps(100) usevalid
mat rwolf = e(RW)
mat list rwolf
local rwrow = 0

foreach depvar in $strategies {
	local rwrow = `rwrow' +1 
	estadd local rw_pval = "[`:di %4.3f rwolf[`rwrow',3]']"	: `depvar'
 di `=`rwrow''
}


* Logit with cluster - Strategies
esttab $strategies using "$output/regs_logitcluster_strategies_`type'_`group'.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{Prompt Student \\ to Explain}" "\shortstack{Ask Question to \\ Guide Thinking}"  "\shortstack{Affirm Student's \\ Correct Attempt}" "\shortstack{Ask Student \\ to Retry}" "\shortstack{Give Away \\ Answer/Explanation}" "\shortstack{Give Solution \\ Strategy}" "\shortstack{Encourage Student \\ in Generic Way}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(rw_pval zval oddsratio N,  /// 
label("Romano-Wolf p-val" "Z" "Odds Ratio" "N" ) fmt(%9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Student-tutor pair clustered standard errors are shown in parentheses. ") ///
nonotes

coefplot $coefplot_list , ///
keep(treat) recast(bar)  barwidth(0.9) ///
 ciopts(recast(rcap)  lcolor(black)) citop ///
 asequation swapnames nokey grid(none)  ///
 xline(0) xlabel(-0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5)  text(0 -0.3 "Control") text(0 0.3 "Treatment") text(9.3 0 "`title' - Log odds ratio with 95% CI", size(12pt)) text(9.8 0 "Standard errors clustered by student-tutor pair", size(10pt)) graphregion(margin(b+2 t-1 r+3) ) aspectratio(0.5) ysize(4)  
graph export "$output/strategies_logodds_clustered_`type'_`group'.png", replace

}
}

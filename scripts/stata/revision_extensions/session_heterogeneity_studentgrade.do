*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Create student grade heterogeneity (reviewer request)
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
// Filepath - ROOT Folder	
	// global root "G:\Shared drives\NSSA Research\FEV\FEV_AICopilot\data"
	global root "G:/Shared drives/NSSA Research/FEV/FEV_AICopilot/data/replication/xander/tutor_copilot_analysis"
	
// Filepaths
	//global raw "$root/rawdata\Main Tutor CoPilot Data"
	global raw "$root/data"
	
*-------------------------------------------------------------------------------
**# IMPORT
*-------------------------------------------------------------------------------
import delimited "$raw/filtered_copilot_data", varnames(1) clear

*-------------------------------------------------------------------------------
**# clean
*-------------------------------------------------------------------------------
rename *, upper

// recoding for stata
gen treat = 1 if TUTOR_COPILOT_ASSIGNMENT == "TREATMENT"
	replace treat = 0 if TUTOR_COPILOT_ASSIGNMENT == "CONTROL"

egen race = group(STUDENT_RACE_ETHNICITY)
	replace race = 8 if STUDENT_RACE_ETHNICITY == ""

egen strata = group(STRATUM)
	
foreach var of varlist STUDENT_IS_FEMALE STUDENT_FREE_REDUCED_LUNCH STUDENT_SPECIAL_EDUCATION STUDENT_LEP TUTOR_IS_FEMALE {
	replace `var' = 2 if `var' == -1
}

gen exit_tix_attempt = 1 if OUTCOME_EXIT_TICKET_ATTEMPTED 

gen exit_tix_pass = 1 if OUTCOME_EXIT_TICKET_PASSED == "1"
	replace exit_tix_pass = 0 if OUTCOME_EXIT_TICKET_PASSED == "0"
	
	
replace OUTCOME_EXIT_TICKET_PASSED = "." if OUTCOME_EXIT_TICKET_PASSED == "NA"
destring OUTCOME_EXIT_TICKET_PASSED, replace
summarize OUTCOME_EXIT_TICKET_PASSED
	
// destring session rating 
foreach var of varlist SESSION_RATING TUTOR_RATING STUDENT_SURVEY_UNDERSTANDING_OVE STUDENT_SURVEY_TUTOR_CARED_ABOUT STUDENT_SURVEY_KNOW_CAN_LEARN  {
	replace `var' = "." if `var' == "NA"
	destring `var', replace
	}

// DE-STRINGING AND IMPUTING
	// tutor_QA
	replace TUTOR_QA_SCORE = "." if TUTOR_QA_SCORE == "NA"
		destring TUTOR_QA_SCORE, replace // 4 missing

		// Impute with regression
		regress TUTOR_QA_SCORE TUTOR_IS_FEMALE TUTOR_AGE
		predict TUTOR_QA_SCORE_pred, xb
		// Only use imputed value if it doesn't exist. 
		replace TUTOR_QA_SCORE_pred = TUTOR_QA_SCORE if !missing(TUTOR_QA_SCORE)
		count // Check this is still 4136
		
	// Winter MAP
	replace STUDENT_WINTER_MAP_2324 = "." if STUDENT_WINTER_MAP_2324 == "NA"
		destring STUDENT_WINTER_MAP_2324, replace // 957 missing
		
		// Impute with student covariates
		regress STUDENT_WINTER_MAP_2324 STUDENT_IS_FEMALE race STUDENT_FREE_REDUCED_LUNCH STUDENT_SPECIAL_EDUCATION STUDENT_LEP 
		predict MOY_MAP2324_pred, xb
		// Only use imputed value if it doesn't exist. 
		replace MOY_MAP2324_pred = STUDENT_WINTER_MAP_2324 if !missing(STUDENT_WINTER_MAP_2324)
		count // Check this is still 4136	
// 	e



********************************************************************************


cap rename PARTICIPATION_POINTS_STANDARDIZE 	PARTICIP_POINTS_STD
cap rename OUTCOME_EXIT_TICKET_ATTEMPTED 		EXITTICKET_ATTEMPT
cap rename OUTCOME_EXIT_TICKET_PASSED 			EXITTICKET_PASSED_C 
cap rename OUTCOME_EXIT_TICKET_PASSED_INCLU 	EXITTICKET_PASSED_U
cap rename STUDENT_SURVEY_UNDERSTANDING_OV		ST_SURVEY_UNDERST
cap rename STUDENT_SURVEY_TUTOR_CARED_ABOUT		ST_SURVEY_TCARED
cap rename STUDENT_SURVEY_KNOW_CAN_LEARN 		ST_SURVEY_CANLEARN
*cap rename SESSION_RATING
*cap rename TUTOR_RATING
cap rename USED_TUTOR_COPILOT USED_TC



** Apply:

*ATT: can't include school FE because of multicol (6th grade == 1 school)

reg EXITTICKET_PASSED_U treat##i.GRADE_NUMBER  i.STUDENT_IS_FEMALE i.race i.STUDENT_FREE_REDUCED_LUNCH i.STUDENT_SPECIAL_EDUCATION i.STUDENT_LEP MOY_MAP2324_pred i.TUTOR_IS_FEMALE i.TUTOR_AGE, cluster(STUDENT_TUTOR)

margins treat, at(GRADE_NUMBER =(3 4 5 6))

marginsplot, ///
    recast(scatter) /// Line plot instead of the default
    title("Grade Heterogeneity") /// Add a title
    ytitle("Student Exit Ticket Pass Rate") /// Label for y-axis
    xtitle("Grade") /// Label for x-axis
    legend(order(1 "Control" 2 "Treatment") position(6)) /// Customize legend
    scheme(s2color) /// Use a different color scheme
    xlabel(3 "3rd" 4 "4th" 5 "5th" 6 "6th") /// Label x-axis categories
	ylab(0.35(0.1)0.95) /// Set y axis range
    graphregion(color(white)) /// Set background color to white
    plotregion(margin(l=5 r=5 t=5 b=5)) /// Adjust margins around the plot
    // name("QA_effect_plot", replace) /// Save the plot with a name


graph export "../../results/session_grade_heterogeneity.png", replace


**







/*
label var treat "Treatment"

estimates clear
eststo clear
local c = 0
local multhyptest = ""
local multhyptest_ind = " "

** ITT
foreach depvar in PARTICIPATION_POINTS PARTICIP_POINTS_STD EXITTICKET_ATTEMPT EXITTICKET_PASSED_C EXITTICKET_PASSED_U /**/ ST_SURVEY_UNDERST ST_SURVEY_TCARED ST_SURVEY_CANLEARN SESSION_RATING TUTOR_RATING {
	local c = `c'+1
	if `c'>1 { 
		local multhyptest_ind = "`multhyptest_ind', " 
	}
    eststo a`c':  reg `depvar' treat i.STUDENT_IS_FEMALE i.race i.STUDENT_FREE_REDUCED_LUNCH i.STUDENT_SPECIAL_EDUCATION i.STUDENT_LEP MOY_MAP2324_pred i.strata, cluster(STUDENT_TUTOR)  
	
	local multhyptest = "`multhyptest'  (`="`e(cmdline)'"')"
	local multhyptest_ind = "`multhyptest_ind'  treat "
	
	margins if treat == 0
	estadd scalar cmean= r(table)[1,1]
	scalar csd= r(table)[2,1]
	estadd local csd= "(`:di %4.3f `=csd'')" : a`c'

}

** ToT
foreach depvar in PARTICIPATION_POINTS PARTICIP_POINTS_STD EXITTICKET_ATTEMPT EXITTICKET_PASSED_C EXITTICKET_PASSED_U /**/ ST_SURVEY_UNDERST ST_SURVEY_TCARED ST_SURVEY_CANLEARN SESSION_RATING TUTOR_RATING {
	local c = `c'+1
	if `c'>1 { 
		local multhyptest_ind = "`multhyptest_ind', " 
	}
    eststo a`c': ivreg2 `depvar' (USED_TC = treat) i.strata i.STUDENT_IS_FEMALE i.race i.STUDENT_FREE_REDUCED_LUNCH i.STUDENT_SPECIAL_EDUCATION i.STUDENT_LEP MOY_MAP2324_pred, cl(STUDENT_TUTOR) first partial(i.strata)
	
	local multhyptest = "`multhyptest'  (`="`e(cmdline)'"')"
	local multhyptest_ind = "`multhyptest_ind'  USED_TC "
	
	*margins if USED_TC == 0
	*estadd scalar cmean= r(table)[1,1]
	*scalar csd= r(table)[2,1]
	*estadd local csd= "(`:di %4.3f `=csd'')" : a`c'

}

** Logit
foreach depvar in EXITTICKET_ATTEMPT EXITTICKET_PASSED_C EXITTICKET_PASSED_U  {
	local c = `c'+1
	if `c'>1 { 
		local multhyptest_ind = "`multhyptest_ind', " 
	}
    eststo a`c':  logit `depvar' treat i.STUDENT_IS_FEMALE i.race i.STUDENT_FREE_REDUCED_LUNCH i.STUDENT_SPECIAL_EDUCATION i.STUDENT_LEP MOY_MAP2324_pred i.strata, cluster(STUDENT_TUTOR)  
	
	local multhyptest = "`multhyptest'  (`="`e(cmdline)'"')"
	local multhyptest_ind = "`multhyptest_ind'  treat "
	
	margins if treat == 0
	estadd scalar cmean= r(table)[1,1]
	scalar csd= r(table)[2,1]
	estadd local csd= "(`:di %4.3f `=csd'')" : a`c'
	
}


** Romano-Wolf
di "`multhyptest'"
rwolf2 `multhyptest', indepvars("`multhyptest_ind'") cluster(STUDENT_TUTOR) reps(100) usevalid
mat rwolf = e(RW)
mat list rwolf
local rwrow = 0
forval j=1/`=`c''  {
	local rwrow = `rwrow' +1 
 estadd local rw_pval = "[`:di %4.3f rwolf[`rwrow',3]']"	: a`j'
 di `=`rwrow''
 }
local c = `c'+1



* ITT part 1
esttab a1 a2 a3 a4 a5 using "../../results/regs_itt_1.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{Participation \\ Points}" "\shortstack{Participation \\ Points \\ Standardized}"  "\shortstack{Exit Tickets \\ Attempted}" "\shortstack{Exit Tickets \\ Passed \\ Conditional}" "\shortstack{Exit Tickets \\ Passed \\ Unconditional}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(cmean csd rw_pval  r2 N,  /// 
label("Control Mean" " " "Romano-Wolf p-val" "R-Square" "N" ) fmt(%9.3f %9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes

* ITT part 2
esttab a6 a7 a8 a9 a10 using "../../results/regs_itt_2.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{My Tutor cared about \\ understanding \\ math over \\ memorizing \\ the solution.}" "\shortstack{ My tutor cared \\ about how well I \\ do in math.}"  "\shortstack{Even when math \\ is hard, I know \\ I can learn it.}" "\shortstack{Session \\ Rating}" "\shortstack{Tutor \\ Rating}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(cmean csd rw_pval  r2 N,  /// 
label("Control Mean" " " "Romano-Wolf p-val" "R-Square" "N" ) fmt(%9.3f %9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes


* ToT part 1
esttab a11 a12 a13 a14 a15 using "../../results/regs_tot_1.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{Participation \\ Points}" "\shortstack{Participation \\ Points \\ Standardized}"  "\shortstack{Exit Tickets \\ Attempted}" "\shortstack{Exit Tickets \\ Passed \\ Conditional}" "\shortstack{Exit Tickets \\ Passed \\ Unconditional}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(USED_TC) stats(rw_pval  r2 N,  /// 
label( "Romano-Wolf p-val" "R-Square" "N" ) fmt(%9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes

* ToT part 2
esttab a16 a17 a18 a19 a20 using "../../results/regs_tot_2.tex", ///
se label b(a2) title("Title") mtitles("\shortstack{My Tutor cared about \\ understanding \\ math over \\ memorizing \\ the solution.}" "\shortstack{ My tutor cared \\ about how well I \\ do in math.}"  "\shortstack{Even when math \\ is hard, I know \\ I can learn it.}" "\shortstack{Session \\ Rating}" "\shortstack{Tutor \\ Rating}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(USED_TC) stats( rw_pval  r2 N,  /// 
label( "Romano-Wolf p-val" "R-Square" "N" ) fmt(%9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes

* Logit
esttab a21 a22 a23 using "../../results/regs_logit.tex", ///
se label b(a2) title("Title") mtitles( "\shortstack{Exit Tickets \\ Attempted}" "\shortstack{Exit Tickets \\ Passed \\ Conditional}" "\shortstack{Exit Tickets \\ Passed \\ Unconditional}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat) stats(cmean csd rw_pval  r2 N,  /// 
label("Control Mean" " " "Romano-Wolf p-val" "R-Square" "N" ) fmt(%9.3f %9.3f %9.3f %9.3f %12.0f)) nocons replace  addnotes("Notes: Robust standard errors are shown in parentheses. Romano-Wolf P-values are shown in brackets. ") ///
nonotes



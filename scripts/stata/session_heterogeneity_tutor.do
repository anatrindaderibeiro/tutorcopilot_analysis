*-------------------------------------------------------------------------------
* FEV
* AI Copilot - Create main session-level results with multiple hypothesis testing adjustment
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


global covars = "i.student_is_female i.race i.student_free_reduced_lunch i.student_special_education i.student_lep student_winter_map_2324 i.strata"


*-------------------------------------------------------------------------------
**# Load data
*-------------------------------------------------------------------------------
use "$datafiles/filtered_copilot_data_foranalysis", clear


*-------------------------------------------------------------------------------
* Tutor Heterogeneity Extensions (Reviewer Requests)
*-------------------------------------------------------------------------------


binscatter exitticket_passed_u tutor_qa_score_pred  , nq(50) line(qfit) by(treat) ///
title("") /// Add a title
    ytitle("Student Exit Ticket Pass Rate") /// Label for y-axis
    xtitle("Tutor Quality Rating") /// Label for x-axis
    legend(order(1 "Control" 2 "Treatment") position(6)) /// Customize legend
    scheme(s2color) /// Use a different color scheme
	ylab(0.3(0.2)1) /// Set y axis range
    graphregion(color(white)) /// Set background color to white
    plotregion(margin(l=5 r=5 t=5 b=5)) /// Adjust margins around the plot
	xlabel(-0.2(0.5)1) /// Label x-axis categories

graph export "$output/fig_tutor_qs.png", replace


	
binscatter exitticket_passed_u tutor_age , nq(20) line(qfit) by(treat) ///
title("") /// Add a title
    ytitle("Student Exit Ticket Pass Rate") /// Label for y-axis
    xtitle("Tutor Experience (Months)") /// Label for x-axis
    legend(order(1 "Control" 2 "Treatment") position(6)) /// Customize legend
    scheme(s2color) /// Use a different color scheme
	ylab(0.3(0.2)1) /// Set y axis range
    graphregion(color(white)) /// Set background color to white
    plotregion(margin(l=5 r=5 t=5 b=5)) /// Adjust margins around the plot
	xlabel(5(10)60) /// Label x-axis categories

graph export "$output/fig_tutor_exp.png", replace



* Generate variables for interactions and non-linear parameters	
*****************************************************************	

*tercile vars -- forcing dropped var to be ==3
xtile tutor_qa_score_pred_tercile = tutor_qa_score_pred, n(3)
gen tutor_qa_score_pred_tercile1 = tutor_qa_score_pred_tercile==1
gen tutor_qa_score_pred_tercile2 = tutor_qa_score_pred_tercile==2

xtile tutor_age_tercile = tutor_age, n(3)
gen tutor_age_tercile1 = tutor_age_tercile==1
gen tutor_age_tercile2 = tutor_age_tercile==2

*quadradtic vars
gen tutor_qa_score_pred2=tutor_qa_score_pred^2
gen tutor_age2=tutor_age^2

*treatment interaction vars
*linear
gen treat_tutor_qa = treat*tutor_qa_score_pred
gen treat_tutor_age = treat*tutor_age

*quadratic
gen treat_tutor_qa2 = treat*tutor_qa_score_pred2
gen treat_tutor_age2 = treat*tutor_age2


*terciles
gen treat_tutor_qa_ter1 = treat*tutor_qa_score_pred_tercile1 
gen treat_tutor_qa_ter2 = treat*tutor_qa_score_pred_tercile2
gen treat_tutor_age_ter1 = treat*tutor_age_tercile1
gen treat_tutor_age_ter2 = treat*tutor_age_tercile2

*triple intercation with linear and tercile
gen treat_tutor_qa_ter1_cont = treat*tutor_qa_score_pred_tercile1*tutor_qa_score_pred
gen treat_tutor_qa_ter2_cont = treat*tutor_qa_score_pred_tercile2*tutor_qa_score_pred
gen treat_tutor_age_ter1_cont = treat*tutor_age_tercile1*tutor_age
gen treat_tutor_age_ter2_cont = treat*tutor_age_tercile2*tutor_age

*triple interaction with linear and quadratic
gen treat_tutor_qa_lin2 = treat*tutor_qa_score_pred*tutor_qa_score_pred2
gen treat_tutor_age_lin2 = treat*tutor_age2*tutor_age2


* Generate labels for tables	
*****************************************************************	
	
label var treat "Treatment"
label var tutor_qa_score_pred "Tutor Quality Rating"
label var tutor_qa_score_pred2 "Tutor Quality Rating Sq"
label var tutor_age "Tutor Experience"
label var tutor_age2 "Tutor Experience Sq"

label var tutor_qa_score_pred_tercile1 "Tutor Quality Rating Low"
label var tutor_qa_score_pred_tercile2 "Tutor Quality Rating Medium"
label var tutor_age_tercile1 "Tutor Experience Low"
label var tutor_age_tercile2 "Tutor Experience Medium"

label var treat_tutor_qa_ter1 "Treat x Tutor Quality Rating Low"
label var treat_tutor_qa_ter2 "Treat x Tutor Quality Rating Medium"
label var treat_tutor_age_ter1 "Treat x Tutor Experience Low"
label var treat_tutor_age_ter2 "Treat x Tutor Experience Medium"

label var treat_tutor_qa "Treat x Tutor Quality Rating (Cont)"
label var treat_tutor_age "Treat x Tutor Experience (Cont)"
label var treat_tutor_qa2 "Treat x Tutor Quality Rating Sq"
label var treat_tutor_age2 "Treat x Tutor Experience Sq"


label var treat_tutor_qa_ter1_cont "Treat x Tutor QR (Cont) x QR Low"
label var treat_tutor_qa_ter2_cont "Treat x Tutor QR (Cont) x QR Medium"
label var treat_tutor_age_ter1_cont "Treat x Tutor Exp (Cont) x Exp Low"
label var treat_tutor_age_ter2_cont "Treat x Tutor Exp (Cont) x Exp Medium"

label var treat_tutor_qa_lin2 "Treat x Tutor QR x QR Sq"
label var treat_tutor_age_lin2 "Treat x Tutor Exp x Exp Sq"


* Generates table with regression results
*****************************************************************	

estimates clear
eststo clear

*linear interact
eststo a1: reg exitticket_passed_u treat tutor_qa_score_pred ///
	treat_tutor_qa tutor_age treat_tutor_age $covars, cluster(student_tutor) 

*linear and quadratic
eststo a2: reg exitticket_passed_u treat ///
	tutor_qa_score_pred tutor_qa_score_pred2  ///
	c.tutor_qa_score_pred#c.tutor_qa_score_pred2 ///
	tutor_age tutor_age2 ///
	c.tutor_age#c.tutor_age2 ///
	treat_tutor_qa treat_tutor_qa2 ///
	treat_tutor_age treat_tutor_age2 ///
	treat_tutor_qa_lin2 treat_tutor_age_lin2 ///
	$covars, cluster(student_tutor)
  
*tercile interact
eststo a3: reg exitticket_passed_u treat ///
	tutor_qa_score_pred_tercile1 tutor_qa_score_pred_tercile2 ///
	tutor_age_tercile1 tutor_age_tercile2 ///
	treat_tutor_qa_ter1 treat_tutor_qa_ter2 ///
	treat_tutor_age_ter1 treat_tutor_age_ter2 ///
	$covars, cluster(student_tutor)
  

esttab a1 a2 a3 using "$output/regs_tutor_heterog.tex", ///
se label b(a3) title("Title") mtitles("\shortstack{Exit Tickets \\ Passed \\ Unconditional}" "\shortstack{Exit Tickets \\ Passed \\ Unconditional}" "\shortstack{Exit Tickets \\ Passed \\ Unconditional}"  ) ///
star(+ 0.10 * 0.05 ** 0.01 *** 0.001) keep(treat*) stats( N,  /// 
label( "N" ) fmt(%12.0f)) nocons replace  addnotes("Robust standard errors are shown in parentheses.")






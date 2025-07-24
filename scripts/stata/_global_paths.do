*-------------------------------------------------------------------------------
* Tutor Copilot
* 0 - Setup
*
* Programming:
*   Stata Version:  Stata 17.0 SE
*   Original Author: Ana Ribeiro (May 10, 2025)
*   Last Modified:  2025-05-10
*-------------------------------------------------------------------------------

/*
Set up file
*/

*-------------------------------------------------------------------------------
* Set the critical parameters of the computing environment.
*-------------------------------------------------------------------------------
* Specify the version of Stata for this analysis [CHANGE IF OLDER VERSION]:
    version 17.0
  
* Clear all computer memory and delete any existing stored graphs and matrices:
    clear all
	
	mata: mata mlib index

/// Install grstyle for versions of Stata newer than 17.0SE
	ssc install grstyle, replace
	
*-------------------------------------------------------------------------------
* Set date
*-------------------------------------------------------------------------------	
	global date "2025.05.23"
	
*-------------------------------------------------------------------------------
* Set the Filepaths
*-------------------------------------------------------------------------------		

*Globals for paths - Double click dofile from folder for globals to work without manually setting directory
if "$root"=="" {
global root = substr("`c(pwd)'", 1, strpos("`c(pwd)'","scripts") - 1)
}
*/
// Filepaths
	*global root "$root_dir/Shared drives/NSSA Research/FEV/FEV_AICopilot/data/replication/" // or set root directory here
	global rawdata "$root/rawdata"
	global datafiles "$root/datafiles"
	global output "$root/output" 
	global dofiles "$root/scripts/stata" 


*-------------------------------------------------------------------------------
* Color Settings
*-------------------------------------------------------------------------------	
//Set NSSA Color Palette
capture program drop colorpalette_accelerate
program colorpalette_accelerate
    c_local P #83aec5,#dd9553,#273e53,#b1d3e1,#767171,#21918c
	c_local I blue, orange, darkblue, liblue, grey, virblue
end	

grstyle init

//Set Accelerator colorscheme: blue, orange, darkblue, grey, virblue, liblue
grstyle set color #83aec5 #dd9553 #273e53 #767171 #21918c #b1d3e1 

grstyle color background white
grstyle color graphregion white
grstyle color legend none
grstyle color legend_line none

//Set color
global mblue "131 174 197"
global orange "221 149 83"
global dblue "39 62 83"
global lblue "177 211 225"
global gray "118 113 113"
	
global turq "33 144 140"
global col2 "59 82 139"

*-----------------------------------------------------------------------------
* Graph Settings
*-------------------------------------------------------------------------------


*-------------------------------------------------------------------------------
* Table Settings
*-------------------------------------------------------------------------------
//Set table & figure globals
	// Esttab
	global esttab_opts b(%9.3f) se(%9.3f) r2(%9.3f) obslast compress nogaps label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001)

*-------------------------------------------------------------------------------
* Figure Settings
*-------------------------------------------------------------------------------
// Graph options 1 - gropt
	global gropt ///
		ylab(,angle(0) nogrid) ///
		title(, justification(left) ///
		color(black) span pos(11)) ///
		subtitle(, justification(left) color(black))
	
// Labels
	global pct02 `" 0 "0%" 1 "1%"  2 "2%" "'

	global pct04 `" 0 "0%" 1 "1%"  2 "2%" 3 "3%" 4 "4%" "'
	global pct05 `" 0 "0%" 1 "1%"  2 "2%" 3 "3%" 4 "4%" 5 "5%" "'
	global pct09 `" 0 "0%" 1 "1%"  2 "2%" 3 "3%" 4 "4%" 5 "5%" 6 "6%" 7 "7%" 8 "8%" 9 "9%" "'

	global pct040 `" 0 "0%" 10 "10%"  20 "20%" 30 "30%" 40 "40%" "'
	global pct050 `" 0 "0%" 10 "10%"  20 "20%" 30 "30%" 40 "40%" 50 "50%" "'
	global pct060 `" 0 "0%" 10 "10%"  20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%""'

	global pct080 `" 50 "50%" 60 "60%"  70 "70%" 80 "80%""'
	global pct100 `" 30 "30%" 40 "40%" 50 "50%" 60 "60%"  70 "70%" 80 "80%" 90 "90%" 100 "100%""'

	global likert `" 1 "Not at all" 2 "Slightly" 3 "Somewhat" 4 "Quite a bit"  5 "Extremely/A lot" "'


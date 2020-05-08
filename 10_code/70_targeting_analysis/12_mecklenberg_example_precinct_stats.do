
    ************************************************************************
    **
    **
    **        PROJECT AUTHORS:    CLINTON, EUBANK, FRESH & SHEPHERD
    **        DO FILE AUTHOR:       SHEPHERD
    **        DATE BEGUN:         May 9, 2018
    **
    **        PROJECT:            NC Electioneering
    **        DETAILS:			 Just exports share of mecklenberg county
	**  							 that's black in example
    **
    **        UPDATES:
    **
    **
    **        VERSION:             Stata 14
    **
    **
    *************************************************************************




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* preliminaries
*-------------------------------------------------------------------------------


clear
set more off


* set the directory
*------------------

cd $nc_electioneering



			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* use data
*-------------------------------------------------------------------------------


* use the data
*-------------

if "$sample_size" == "full" {
    zipuse 20_intermediate_files/40_voter_panel_long_dta.zip, clear
}
else {
    use 20_intermediate_files/40_voter_panel_10pctsample_long.dta, clear
}

* First state


gen dem = (party == 1) if party !=.
gen white = (race == 0) if race != .

foreach x in white dem {

sum `x'
local cleaned_statistic: display %12.0fc `r(mean)' * 100
display "`cleaned_statistic'"

file open myfile using $nc_electioneering/50_results_$sample_size/share_state_`x'.tex, write text replace
file write myfile "`cleaned_statistic'"
file close myfile
}

* Now precinct only

keep if city == "CHARLOTTE" & precinct_name == "22" & year == 2016

foreach x in white dem {

sum `x'
local cleaned_statistic: display %12.0fc `r(mean)' * 100
display "`cleaned_statistic'"

file open myfile using $nc_electioneering/50_results_$sample_size/share_precinct22_`x'.tex, write text replace
file write myfile "`cleaned_statistic'"
file close myfile
}

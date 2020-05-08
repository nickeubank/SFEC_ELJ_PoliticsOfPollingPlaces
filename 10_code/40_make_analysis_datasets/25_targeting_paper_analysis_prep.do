
    ************************************************************************
    **
    **
    **        PROJECT AUTHORS:    CLINTON, EUBANK, FRESH & SHEPHERD
    **        DO FILE AUTHOR:       SHEPHERD
    **        DATE BEGUN:         May 9, 2018
    **
    **        PROJECT:            NC Electioneering
    **        DETAILS:
    **
    **        UPDATES:  		  Targeting Paper output data.
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
* read in the data
*-------------------------------------------------------------------------------


* use the data
*-------------

cd $nc_electioneering

if "$sample_size" == "full" {
    zipuse 20_intermediate_files/60_voter_panel_long_w_analysisvars_no_movers_dta.zip, clear
}
else {
    use 20_intermediate_files/60_voter_panel_10pctsample_long_w_analysisvars_no_movers.dta, clear
}




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* define output
*-------------------------------------------------------------------------------


* define output directory
*------------------------

global output "$nc_electioneering/80_results_$sample_size"
global filename "table3_maintargeting"





			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* create new variables
*-------------------------------------------------------------------------------


* categories of party
*--------------------

gen party_dem = party == 0
gen party_rep = party == 1
gen party_ind = party == 2


* drop libertarians
*------------------

//



* share republicans who are white
*--------------------------------

count
local total = r(N)
count if party == 3
local cleaned_statistic: display %12.1fc (`r(N)' / `total') * 100
display "`cleaned_statistic'"

file open myfile using $nc_electioneering/50_results_$sample_size/share_voters_libertarian.tex, write text replace
file write myfile "`cleaned_statistic'"
file close myfile

drop if party == 3



* race party categories
*----------------------

gen race_black = race == 1
gen race_white = race == 0
gen race_other = race > 2 & race != .


gen partyrace_rep_white = party_rep == 1 & race_white == 1

gen partyrace_dem_white = party_dem == 1 & race_white == 1
gen partyrace_dem_black = party_dem == 1 & race_black == 1
gen partyrace_dem_other = party_dem == 1 & race_other == 1

gen partyrace_ind_white = party_ind == 1 & race_white == 1
gen partyrace_ind_black = party_ind == 1 & race_black == 1
gen partyrace_ind_other = party_ind == 1 & race_other == 1




* check coverage of race party variables
*---------------------------------------

capture drop test
gen test = partyrace_ind_other + partyrace_ind_black + partyrace_ind_white + ///
           partyrace_dem_other + partyrace_dem_black + partyrace_dem_white + ///
           partyrace_rep_white
egen test2 = sum(test)
sum test2
local top = r(mean)
count
display `top' / `r(N)'
assert `top' / `r(N)' > 0.97
drop test test2



* share republicans who are white
*--------------------------------

sum race_white if party_rep == 1
local cleaned_statistic: display %12.1fc `r(mean)' * 100
display "`cleaned_statistic'"

file open myfile using $nc_electioneering/50_results_$sample_size/share_republicans_white.tex, write text replace
file write myfile "`cleaned_statistic'"
file close myfile



* voted in the last election
*---------------------------

sort voter_index 	election_index
gen voted_last 		= L.voted_ANY



* change in driving time from last election
*------------------------------------------

sort voter_index 	election_index
gen pp_minutes_driving_change = D.pp_minutes_driving

	// replace change in drive time to zero if there is no polling place change
replace pp_minutes_driving_change = 0 	if pp_has_changed == 0



* county name as string
*----------------------

gen county_name = county
label var county_name "county name as string"
replace county_name = regexr(county_name, "( County)", "")



* age squared
*------------

gen age2 = age*age



* PP close/further binary
*------------------------

gen pp_further = pp_has_changed
recode pp_further (1=0) 		if pp_minutes_driving_change < 0

gen pp_closer = pp_has_changed
recode pp_closer (1=0) 			if pp_minutes_driving_change > 0



* non-co-partisan variable
*-------------------------

gen opposition = .
label var opposition "\emph{Opposition}"

replace opposition = 1 		if party_dem == 1 & year == 2016
replace opposition = 1 		if party_rep == 1 & year == 2012
replace opposition = 0 		if opposition == .


gen opporace_oppo_white = party_rep == 1 & race_white == 1 if year == 2012
replace opporace_oppo_white = party_rep == 0 & race_white == 1 if year == 2016

gen opporace_oppo_black = party_rep == 1 & race_black == 1 if year == 2012
replace opporace_oppo_black = party_rep == 0 & race_black == 1 if year == 2016

gen opporace_oppo_other = party_rep == 1 & race_other == 1 if year == 2012
replace opporace_oppo_other = party_rep == 0 & race_other == 1 if year == 2016

gen opporace_ind_white = party_ind == 1 & race_white == 1
gen opporace_ind_black = party_ind == 1 & race_black == 1
gen opporace_ind_other = party_ind == 1 & race_other == 1

assert opporace_oppo_white == 0 if party_rep == 1 & year == 2016
assert opporace_oppo_white == 0 if party_dem == 1 & year == 2012


			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* create new VRA variables
*-------------------------------------------------------------------------------

* VRA status
*---------------

gen vra=.

replace vra=1 if strpos(county, "Anson")
replace vra=1 if strpos(county, "Beaufort")
replace vra=1 if strpos(county, "Bertie")
replace vra=1 if strpos(county, "Bladen")
replace vra=1 if strpos(county, "Camden")
replace vra=1 if strpos(county, "Caswell")
replace vra=1 if strpos(county, "Chowan")
replace vra=1 if strpos(county, "Cleveland")
replace vra=1 if strpos(county, "Craven")
replace vra=1 if strpos(county, "Cumberland")
replace vra=1 if strpos(county, "Edgecombe")
replace vra=1 if strpos(county, "Franklin")
replace vra=1 if strpos(county, "Gaston")
replace vra=1 if strpos(county, "Gates")
replace vra=1 if strpos(county, "Granville")
replace vra=1 if strpos(county, "Greene")
replace vra=1 if strpos(county, "Guilford")
replace vra=1 if strpos(county, "Halifax")
replace vra=1 if strpos(county, "Harnett")
replace vra=1 if strpos(county, "Hertford")
replace vra=1 if strpos(county, "Hoke")
replace vra=1 if strpos(county, "Jackson")
replace vra=1 if strpos(county, "Lee")
replace vra=1 if strpos(county, "Lenoir")
replace vra=1 if strpos(county, "Martin")
replace vra=1 if strpos(county, "Nash")
replace vra=1 if strpos(county, "Northampton")
replace vra=1 if strpos(county, "Onslow")
replace vra=1 if strpos(county, "Pasquotank")
replace vra=1 if strpos(county, "Perquimans")
replace vra=1 if strpos(county, "Person")
replace vra=1 if strpos(county, "Pitt")
replace vra=1 if strpos(county, "Robeson")
replace vra=1 if strpos(county, "Rockingham")
replace vra=1 if strpos(county, "Scotland")
replace vra=1 if strpos(county, "Union")
replace vra=1 if strpos(county, "Vance")
replace vra=1 if strpos(county, "Washington")
replace vra=1 if strpos(county, "Wayne")
replace vra=1 if strpos(county, "Wilson")
replace vra=0 if vra!=1



* post by covered
*----------------

gen post_x_covered=1 if vra==1 & year==2016
replace post_x_covered=0 if post_x_covered!=1

label var post_x_covered "\emph{CoveredSection5 * Post-Shelby}"




* county numeric
*---------------

egen county_numeric = group(county_name)
label var county_numeric "county numeric"

label var county "county name with 'county' at the end"



			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**

*-------------------------------------------------------------------------------
* change variable labels for table output
*-------------------------------------------------------------------------------


* label
*------

label var pp_has_changed 				"$\Delta$\emph{PollingPlace} $(\hat{\beta})$"
label var pp_minutes_driving_change		"$\Delta$\emph{DriveTime} $(\hat{\psi})$"


label var age							"\emph{Age}"
label var age2							"\emph{Age}$^{2}$"
label var female						"\emph{Female}"
label var census_hh_med_income			"\emph{Income}"

label var race_black 					"\emph{Black}"
label var race_white 					"\emph{White}"
label var race_other 					"\emph{OtherRace}"

label var party_dem 					"\emph{Dem}"
label var party_rep 					"\emph{Rep}"
label var party_ind 					"\emph{Unaff}"


label var partyrace_rep_white 			"\emph{WhiteRep}"

label var partyrace_dem_white 			"\emph{WhiteDem}"
label var partyrace_dem_black 			"\emph{BlackDem}"
label var partyrace_dem_other 			"\emph{OtherDem}"

label var partyrace_ind_white 			"\emph{WhiteUnaff}"
label var partyrace_ind_black 			"\emph{BlackUnaff}"
label var partyrace_ind_other 			"\emph{OtherUnaff}"


label var opporace_oppo_white "\emph{WhiteOpp}"
label var opporace_oppo_black "\emph{BlackOpp}"
label var opporace_oppo_other "\emph{OtherOpp}"
label var opporace_ind_white  "\emph{WhiteUnaff}"
label var opporace_ind_black  "\emph{BlackUnaff}"
label var opporace_ind_other "\emph{OtherUnaff}"






			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* people per polling place variable
*-------------------------------------------------------------------------------


* people per polling place
*-------------------------

gen counter = 1
bysort election_index precinct_id_withinyear: egen polling_place_registrants = sum(counter)
count
if r(N) < 1000000{
    assert "$sample_size" == "10percent"
    replace polling_place_registrants = polling_place_registrants * 10
}

drop counter
sort voter_index election_index
gen change_num_pp_registrants = D.polling_place_registrants


* assert
*-------

assert change_num_pp_registrants == . if year == 2008
label var  change_num_pp_registrants "\emph{$\Delta$ Voters Registered at PP}"



* summarize
*----------

sum polling_place_registrants
local cleaned_statistic: display %12.1fc `r(mean)'
display "`cleaned_statistic'"



* save output
*------------

file open myfile using $nc_electioneering/50_results_$sample_size/avg_num_polling_place_registrants.tex, write text replace
file write myfile "`cleaned_statistic'"
file close myfile


*-------------------------------------------------------------------------------
* Responsive counties
*-------------------------------------------------------------------------------

gen responsive_county=.
replace responsive_county = 1 if strpos(county_name, "Cleveland")
replace responsive_county = 1 if strpos(county_name, "Pasquotank")
replace responsive_county = 1 if strpos(county_name, "Beaufort")
replace responsive_county = 1 if strpos(county_name, "Caswell")
replace responsive_county = 1 if strpos(county_name, "Halifax")
replace responsive_county = 1 if strpos(county_name, "Martin")
replace responsive_county = 1 if strpos(county_name, "Nash")
replace responsive_county = 1 if strpos(county_name, "Person")
replace responsive_county = 1 if strpos(county_name, "Robeson")
replace responsive_county = 1 if strpos(county_name, "Wayne")
replace responsive_county = 1 if strpos(county_name, "Craven")
replace responsive_county = 1 if strpos(county_name, "Cumberland")
replace responsive_county = 1 if strpos(county_name, "Edgecombe")
replace responsive_county = 1 if strpos(county_name, "Forsyth")
replace responsive_county = 1 if strpos(county_name, "Hoke")
replace responsive_county = 1 if strpos(county_name, "Pamlico")
replace responsive_county = 1 if strpos(county_name, "Pitt")
replace responsive_county = 1 if strpos(county_name, "Richmond")
replace responsive_county = 1 if strpos(county_name, "Union")
replace responsive_county = 1 if strpos(county_name, "Lenoir")

replace responsive_county = 0 if responsive_county == .
label var responsive_county "County Reported To Be Responsive"

* Check count
egen tag = tag(county_name)
count if tag == 1 & responsive_county == 1
assert r(N) == 20
drop tag

gen all = 1
label var all "always 1. variable for stand-in if condition to select all observations."




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* save data
*-------------------------------------------------------------------------------


* save
*-----

if "$sample_size" == "full" {
    zipsave 20_intermediate_files/65_voter_panel_long_fortargeting_no_movers_dta.zip, replace
}
else {
    save 20_intermediate_files/65_voter_panel_long_fortargeting_no_movers.dta, replace
}



			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**

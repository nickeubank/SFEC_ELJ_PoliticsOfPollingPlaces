


			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* preliminaries
*-------------------------------------------------------------------------------


* preliminaries
*--------------

set more off
clear




* set the directory
*------------------

cd $nc_electioneering



* use the data
*-------------


if "$sample_size" == "full" {
    zipuse 20_intermediate_files/65_voter_panel_long_fortargeting_dta.zip, clear
}
else {
    use 20_intermediate_files/65_voter_panel_long_fortargeting_dta.dta, clear
}



* define output directory
*------------------------

global output "$nc_electioneering/50_results_$sample_size"



			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* regressions
*-------------------------------------------------------------------------------


* globals
*--------

global dv1					= "pp_has_changed"

global iv1					= "opposition"


global controls				= "party_ind age age2"




* temp file
*----------

tempname memhold
tempfile results
postfile `memhold' 	beta_pp_has_changed se_pp_has_changed ///
					str10 county_name county_num str10 year  using `results'



* county group
*-------------

capture drop county_group
egen county_group = group(county_name)

* Make cluster vars
*---------------
gen test = precinct_id_withinyear if year == 2008
bysort ncid:  egen precinct_2008 = max(test)
drop test

gen test = precinct_id_withinyear if year == 2012
bysort ncid: egen precinct_2012 = max(test)
drop test

gen test = precinct_id_withinyear if year == 2016
bysort ncid:  egen precinct_2016 = max(test)
drop test

egen cluster_panel = group(precinct_2008 precinct_2012 precinct_2016)
egen cluster_2012 = group(precinct_2008 precinct_2012)
egen cluster_2016 = group(precinct_2012 precinct_2016)



* estimate each beta for the panel
*---------------------------------

	forvalues x = 1/100 {

		levelsof county_name 	if county_group == `x', local(county_name) clean


		// panel
		reg ${dv1} ${iv1}  ${controls}  if county_group == `x', cluster(cluster_panel)  ///
					,
			post `memhold' (_b[${iv1}]) (_se[${iv1}]) ("`county_name'") (`x') ("all")

        reg ${dv1} ${iv1}  ${controls}  if county_group == `x' & year == 2012, cluster(cluster_2012) ///
					,
			post `memhold' (_b[${iv1}]) (_se[${iv1}]) ("`county_name'") (`x') ("2012")

        reg ${dv1} ${iv1}  ${controls}  if county_group == `x' & year == 2016, cluster(cluster_2012) ///
					,
			post `memhold' (_b[${iv1}]) (_se[${iv1}]) ("`county_name'") (`x') ("2016")

	}



* post close
*-----------

postclose `memhold'
use `results', clear



* save so that can use later
*---------------------------
save "$nc_electioneering/20_intermediate_files/100_individual_county_regression_coefficients_$sample_size.dta", replace





			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**

					 ** end of do file **

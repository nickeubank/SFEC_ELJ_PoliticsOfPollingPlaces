
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
set matsize 800


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

/*
if "$sample_size" == "full" {
    zipuse 20_intermediate_files/65_voter_panel_long_fortargeting_dta.zip, clear
}
else {
    use 20_intermediate_files/65_voter_panel_long_fortargeting.dta, clear
}
*/

if "$sample_size" == "full" {
    zipuse 20_intermediate_files/65_voter_panel_long_fortargeting_dta.zip, clear
}
else {
    use 20_intermediate_files/65_voter_panel_long_fortargeting.dta, clear
}



			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* output directory
*-------------------------------------------------------------------------------


* define output directory
*------------------------

global output "$nc_electioneering/50_results_$sample_size"
global filename "maintargeting"




* program to de-mean the outcome variables by individuals
*---------------------------------------------

	// to reflect the variation that we're leveraging in the analysis


capture program drop summary_stats
program define summary_stats
	local estimate `1'
	local dv `2'
	local fe `3'

	* Make sure works
	count if e(sample)
	assert e(N) == r(N)
	assert r(N) != 0

	* Add DV mean
	sum `dv' if e(sample)
	estadd scalar meandv = `r(mean)': `estimate'

	* Add within-individual SD
	bysort `fe': egen mean_dv = mean(`dv') if e(sample)
	gen demeaned_dv = `dv' - mean_dv if e(sample)
	sum demeaned_dv if e(sample)
	estadd scalar stddv = `r(sd)': `estimate'

	drop mean_dv demeaned_dv

end




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**

							** TABLES **

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**

*-------------------------------------------------------------------------------
*	TABLE ?
*
* 		DV Vote: 		Polling Place Change
*		IV: 			black party_dem
*		Sample: 		Panel
*		Interactions: 	None
*-------------------------------------------------------------------------------



* globals for specifications
*---------------------------

global dv1    				= "pp_has_changed"
global dv2 					= "pp_further"
global dv3 					= "change_num_pp_registrants"

global samplerestriction1   = "all == 1"
global samplerestriction2   = "pp_has_changed == 1"
global samplerestriction3   = "all == 1"

global number_of_outcomes	= 3

global iv1					= "opposition"
global iv2				    = "opporace_oppo_white opporace_oppo_black"

global controls             = "age age2"
global controls1			= "party_ind"
global controls2			= "opporace_oppo_other opporace_ind_white opporace_ind_black opporace_ind_other"

global cluster1				= "county"




* set the data
*-------------

tsset voter_index election_index

 forvalues x = 1/$number_of_outcomes {

    * clear eststo
    *-------------

    _eststo clear



    * save coefficient results
    *-------------------------



    // specification 0
    local estimate = "est_0"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':	reg ${dv`x'} ${iv1} if ${samplerestriction`x'}, cluster(${cluster1})


    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"Panel": `estimate'
    				estadd local yearfe			"": `estimate'
    				estadd local countyyearfe		"": `estimate'
    				estadd local countyfe		"": `estimate'
    				estadd local controls 		"": `estimate'

    				sum ${dv`x'} if e(sample)
    				estadd scalar meandv = `r(mean)': `estimate'
    				estadd scalar stddv = `r(sd)': `estimate'


	// specification 0.5
    local estimate = "est_05"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':	areg ${dv`x'} ${iv1}  i.year##i.county_fips		///
    								 if ${samplerestriction`x'} ///
                                     , vce(cl ${cluster1})  absorb(county)

					summary_stats "`estimate'" ${dv`x'} county

    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"Panel": `estimate'
    				estadd local yearfe			"\checkmark": `estimate'
    				estadd local countyyearfe	"\checkmark": `estimate'
    				estadd local countyfe		"\checkmark": `estimate'
    				estadd local controls 		"": `estimate'
					
					
    // specification 1
    local estimate = "est_1"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':	areg ${dv`x'} ${iv1}  ${controls} ${controls1} i.year##i.county_fips		///
    								 if ${samplerestriction`x'} ///
                                     , vce(cl ${cluster1})  absorb(county)

					summary_stats "`estimate'" ${dv`x'} county

    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"Panel": `estimate'
    				estadd local yearfe			"\checkmark": `estimate'
    				estadd local countyyearfe	"\checkmark": `estimate'
    				estadd local countyfe		"\checkmark": `estimate'
    				estadd local controls 		"\checkmark": `estimate'




    // specification 2
    local estimate = "est_2"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':	areg ${dv`x'} ${iv1} ${controls} ${controls1}  if	 year == 2012			///
    								&  ${samplerestriction`x'} ///
                                    , vce(cl ${cluster1})  absorb(county)

					summary_stats "`estimate'" ${dv`x'} county

    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"2012": `estimate'
    				estadd local countyfe		"\checkmark": `estimate'
    				estadd local controls 		"\checkmark": `estimate'

    					/* // coefficient estimates
    					local beta 		= (_b[${iv1}]) * 100

    						${closef}
    						${openf} "${filename}_`estimate'.tex", write replace
    						${writef} %7.1f (`beta')
    						${closef} */



    // specification 3
    local estimate = "est_3"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':	xi:		areg ${dv`x'} ${iv1}  ${controls}  ${controls1} if	 year==2016		///
    								 & ${samplerestriction`x'}  ///
                                     , vce(cl ${cluster1})  absorb(county)

					summary_stats "`estimate'" ${dv`x'} county

    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"2016": `estimate'
    				estadd local countyfe		"\checkmark": `estimate'
    				estadd local controls 		"\checkmark": `estimate'






    // specification 1b
    local estimate = "est_1b"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':			areg ${dv`x'} ${iv2}  ${controls} 	 ${controls2} i.year##i.county_fips	///
    								 if ${samplerestriction`x'} ///
                                     , vce(cl ${cluster1})  absorb(county)

					summary_stats "`estimate'" ${dv`x'} county

    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"Panel": `estimate'
    				estadd local yearfe			"\checkmark": `estimate'
    				estadd local countyyearfe		"\checkmark": `estimate'
    				estadd local countyfe		"\checkmark": `estimate'
    				estadd local controls 		"\checkmark": `estimate'



    // specification 2b
    local estimate = "est_2b"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':		areg ${dv`x'} ${iv2} ${controls} ${controls2} if	 year==2012			///
    								& ${samplerestriction`x'} ///
                                    , vce(cl ${cluster1})  absorb(county)

					summary_stats "`estimate'" ${dv`x'} county

    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"2012": `estimate'
    				estadd local countyfe		"\checkmark": `estimate'
    				estadd local controls 		"\checkmark": `estimate'



    // specification 3b
    local estimate = "est_3b"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':		areg ${dv`x'} ${iv2}  ${controls} ${controls2} if	 year == 2016		///
    								 & ${samplerestriction`x'} ///
                                     , vce(cl ${cluster1})  absorb(county)


    				// test _b[opporace_oppo_white] == _b[opporace_oppo_black]

					summary_stats "`estimate'" ${dv`x'} county

    				estadd scalar clusters = e(N_clust): `estimate'

    				estadd local sample			"2016": `estimate'
    				estadd local countyfe		"\checkmark": `estimate'
    				estadd local controls 		"\checkmark": `estimate'


    * output the regressions
    *-----------------------



    cd "${output}"

    	#delimit;

    	esttab
            est_0
			est_05
    		est_1
    		est_2
    		est_3
            est_1b
    		est_2b
    		est_3b


    		using "${filename}_${dv`x'}_nocontrols.tex",
    			b(a2) label replace nogaps compress se(a2) bookt
    			noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
    			fragment keep(${iv1} ${iv2})


    			stats(countyfe yearfe countyyearfe controls sample N meandv stddv ,
    				labels(	"County FE"
    						"Year FE"
    						"Ct. x Yr. FE"
    						"Controls"
    						"Year Sample"
    						"Observations"
    						"Mean of DV"
    						"SD of DV"

    						) )
    			title("")
    			nomtitles


    		;

    	#delimit cr


    cd "${output}"


    	#delimit;

    	esttab
            est_0
			est_05
    		est_1
    		est_2
    		est_3
            est_1b
    		est_2b
    		est_3b


    		using "${filename}_${dv`x'}_wcontrols.tex",
    			b(a2) label replace nogaps compress se(a2) bookt
    			noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
    			fragment keep(${iv1} ${iv2}  ${controls} ${controls1} ${controls2})


    			stats(countyfe yearfe countyyearfe controls sample N meandv stddv ,
    				labels(	"County FE"
    						"Year FE"
    						"Ct. x Yr. FE"
    						"Controls"
    						"Year Sample"
    						"Observations"
    						"Mean of DV"
    						"SD of DV"

    						) )
    			title("")
    			nomtitles


    		;

    	#delimit cr



}


	************************************************************************
    **
    **
    **        PROJECT AUTHORS:    CLINTON, EUBANK, FRESH & SHEPHERD
    **        DO FILE AUTHOR:       SHEPHERD
    **        DATE BEGUN:         June 21, 2018
    **
    **        PROJECT:            NC Electioneering
    **        DETAILS:
    **
    **        UPDATES:  		  Shelby
    **
    **
    **        VERSION:             Stata 14.2
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
set trace on


* set the directory
*------------------

cd $nc_electioneering


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




* use the data
*-------------

if "$sample_size" == "full" {
    zipuse 20_intermediate_files/65_voter_panel_long_fortargeting_dta.zip, clear
}
else {
    use 20_intermediate_files/65_voter_panel_long_fortargeting.dta, clear
}



* define output directory
*------------------------

global output "$nc_electioneering/50_results_$sample_size"

global filename "shelby"





* subset & add vars
*------------------

keep if year == 2016



			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**

							** TABLES **

			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* table
*-------------------------------------------------------------------------------


* globals for specifications
*---------------------------

global dv1    				= "pp_has_changed"
global dv2 					= "change_num_pp_registrants"
global dv3 				    = "pp_further"
* global dv5 				= "pp_minutes_driving_change"


global number_of_outcomes	= 3

global iv1					= "opporace_oppo_white opporace_oppo_black"

global controls             = "age age2"
global controls1			= "opporace_oppo_other opporace_ind_white opporace_ind_black opporace_ind_other"

global cluster1				= "county"




* set the data
*-------------




* clear eststo
*-------------

_eststo clear


* specification
*--------------


foreach vra in 1 0 {

    * First two dependent variables have 1 specifiation so loop.
    foreach x in 1 2 {
        if vra == 1 {
            fvset base 4 county_numeric
        }
        if vra == 0 {
            fvset base 1 county_numeric
        }

        local estimate = "shelby_`x'_`vra'"

        eststo `estimate':	areg  	${dv`x'} ${iv1} ${controls} ${controls1} if vra == `vra', ///
									absorb(county_numeric) vce(cl $cluster1)

						summary_stats "`estimate'" ${dv`x'} county_numeric

                        estadd scalar clusters = e(N_clust): `estimate'

        				sum ${dv`x'} if vra == `vra'

                        estadd local controls 		"\checkmark": `estimate'

						estadd local countyFE 		"\checkmark": `estimate'


        * For column headers. Do here so can't mis-label.
        if `vra' == 0 {
            global name_`x'_`vra' = "Non-Section 5"
        }
        else {
            global name_`x'_`vra' = "Section 5"
        }

    }

    // specification 3
    local estimate = "shelby_3_`vra'"
    fvset base 2008 year
    fvset base 190 voter_index  		// arbitrary

    eststo `estimate':	xi:		areg ${dv3} ${iv1}  ${controls}  ${controls1} if vra == `vra' & pp_has_changed == 1 ///
								 , vce(cl ${cluster1})  absorb(county_numeric)

						summary_stats "`estimate'" ${dv3} county_numeric

                        estadd scalar clusters = e(N_clust): `estimate'

        				sum ${dv3} if vra == `vra' & pp_has_changed == 1

                        estadd local controls 		"\checkmark": `estimate'

    					estadd local countyFE 		"\checkmark": `estimate'

            if `vra' == 0 {
                global name_3_`vra' = "Non-Section 5"
            }
            else {
                global name_3_`vra' = "Section 5"
            }



}





* output the regressions
*-----------------------

	cd "${output}"

	#delimit ;

	esttab
        shelby_1_1
		shelby_1_0
        shelby_3_1
        shelby_3_0
        shelby_2_1
        shelby_2_0


		using "${filename}.tex",
			b(a2) label replace nogaps compress se(a2) bookt
			noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
			fragment keep( opporace_oppo_white opporace_oppo_black )


			stats(controls countyFE N meandv stddv clusters ,
				labels(	"Controls"
						"County FE"
						"Observations"
						"Mean of DV"
						"SD of DV"
                        "County Clusters"
						) )
			title("")
			mtitles("$name_1_1" "$name_1_0" "$name_3_1" "$name_3_0" "$name_2_1" "$name_2_0" )
		;;

	esttab
        shelby_1_1
		shelby_1_0
        shelby_3_1
        shelby_3_0
        shelby_2_1
        shelby_2_0


		using "${filename}_withcontrols.tex",
			b(a2) label replace nogaps compress se(a2) bookt
			noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
			fragment


			stats(controls countyFE N meandv stddv clusters ,
				labels(	"Controls"
						"County FE"
						"Observations"
						"Mean of DV"
						"SD of DV"
                        "County Clusters"
						) )
			title("")
			mtitles("$name_1_1" "$name_1_0" "$name_3_1" "$name_3_0" "$name_2_1" "$name_2_0" )
		;;

	#delimit cr




* compare differences
*--------------------

reg  	${dv1} i.vra##opporace_oppo_white i.vra##opporace_oppo_black ${controls} ///
					if year == 2016, cluster($cluster1)


reg  	${dv2} i.vra##opporace_oppo_white i.vra##opporace_oppo_black ${controls} ///
					if year == 2016, cluster($cluster1)






* END OF SPECIFICATIONS DO FILE
*------------------------------

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



* set the directory
*------------------

cd $nc_electioneering




* use the data
*-------------

if "$sample_size" == "full" {
    zipuse 20_intermediate_files/65_voter_panel_long_fortargeting_dta.zip, clear
}
else {
    use 20_intermediate_files/65_voter_panel_long_fortargeting.dta, clear
}

keep if responsive_county == 1


* define output directory
*------------------------

global output "$nc_electioneering/50_results_$sample_size"

global filename "responsive"





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
global dv2 				    = "pp_further"
global dv3 					= "change_num_pp_registrants"

global samplerestriction1   = "all == 1"
global samplerestriction2   = "pp_has_changed == 1"
global samplerestriction3   = "all == 1"

global number_of_outcomes	= 3

global iv1					= "opposition"
global iv2					= "opporace_oppo_white opporace_oppo_black"




global controls             = "age age2"
global controls1			= "party_ind"
global controls2			= "opporace_oppo_other opporace_ind_white opporace_ind_black opporace_ind_other"
global cluster1				= "county"




* set the data
*-------------




* clear eststo
*-------------

_eststo clear


* specification DID 1
*----------------


* First two dependent variables have 1 specifiation so loop.
forvalues x = 1/$number_of_outcomes {

    local estimate = "responsive_`x'_0"

    eststo `estimate':	areg  	${dv`x'} ${iv1} ${controls} ${controls1} if ${samplerestriction`x'} ///
                            , absorb(county_numeric) vce(cl $cluster1)

					summary_stats "`estimate'" ${dv`x'} county_numeric

                    estadd scalar clusters = e(N_clust): `estimate'

                    estadd local controls 		"\checkmark": `estimate'

					estadd local countyFE 		"\checkmark": `estimate'

    local estimate = "responsive_`x'_1"

    eststo `estimate':	areg  	${dv`x'} ${iv2} ${controls} ${controls2} if ${samplerestriction`x'} ///
                        , absorb(county_numeric) vce(cl $cluster1)

					summary_stats "`estimate'" ${dv`x'} county_numeric

                    estadd scalar clusters = e(N_clust): `estimate'

                    estadd local controls 		"\checkmark": `estimate'

					estadd local countyFE 		"\checkmark": `estimate'


}





* output the regressions
*-----------------------

	cd "${output}"

	#delimit ;

	esttab
        responsive_1_0
		responsive_1_1
        responsive_2_0
        responsive_2_1
        responsive_3_0
        responsive_3_1


		using "${filename}.tex",
			b(a2) label replace nogaps compress se(a2) bookt
			noconstant nodepvars star(* 0.1 ** 0.05 *** 0.01)
			fragment keep(opposition opporace_oppo_white opporace_oppo_black )

			stats(controls countyFE N meandv stddv clusters ,
				labels(	"Controls"
						"County FE"
						"Observations"
						"Mean of DV"
						"SD of DV"
                        "County Clusters"
						) )
			title("")
			nomtitles
		;;

	esttab
        responsive_1_0
        responsive_1_1
        responsive_2_0
        responsive_2_1
        responsive_3_0
        responsive_3_1


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
			nomtitles
		;;

	#delimit cr




* compare differences
*--------------------

reg  	${dv1} i.vra##opporace_oppo_white i.vra##opporace_oppo_black ${controls} if year == 2016, cluster($cluster1)


reg  	${dv2} i.vra##opporace_oppo_white i.vra##opporace_oppo_black ${controls} if year == 2016, cluster($cluster1)






* END OF SPECIFICATIONS DO FILE
*------------------------------

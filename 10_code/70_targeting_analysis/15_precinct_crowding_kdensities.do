
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

drop if abs(change_num_pp_registrants) < 10





			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* plots
*-------------------------------------------------------------------------------

* plot
*-----

# delimit ;

	twoway
		(kdensity change_num_pp_registrants
			if party_dem == 1 ,
			bwidth(100) lcolor(gs2) )

		(kdensity change_num_pp_registrants
			if party_rep == 1 ,
			bwidth(100) lcolor(gs8) lpattern(shortdash) )
		,

			ylabel( ,
				tlength(0) angle(hori) nogrid labsize(medsmall) )
			ytitle("Density",
				angle(hori)	color(black) size(medium) )

			xlabel(  ,
				labsize(medsmall) tlcolor(black) labcolor(black) )
			xtitle("Change in Num Voters at Polling Place",
				color(black) size(medium) )

			xscale(noline)
			yscale(noline)
			graphregion(fcolor(white) lcolor(white) )
			plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))
			title("  ",
				color(black) size(medsmall) pos(5) )
			subtitle("",
				color(black) justification(center))
			legend(
				position(6)
				cols(2)
				label(1 "Democratic Voters")
				label(2 "Republican Voters")
				region( color(none) )
				size(medsmall)
			)
	   // note("Voters whose precincts change by less than 10 people excluded for visibility.")



	;
	#delimit cr


	* save plot
	*----------

	graph export $output/kdensity_change_pp_registrants.pdf, replace




* loop
*-----

foreach year in 2012 2016 {

	#delimit ;

    twoway
			(kdensity change_num_pp_registrants
				if party_dem == 1 & year == `year' ,
				lcolor(gs2) )

			(kdensity change_num_pp_registrants
				if party_rep == 1 & year == `year' ,
				lcolor(gs8) lpattern(shortdash) )
			,

			ylabel( ,
				tlength(0) angle(hori) nogrid labsize(medsmall) )
			ytitle("Density",
				angle(hori)	color(black) size(medium) )

			xlabel(  ,
				labsize(medsmall) tlcolor(black) labcolor(black) )
			xtitle("Change in Num Voters at Polling Place",
				color(black) size(medium) )

			xscale(noline)
			yscale(noline)
			graphregion(fcolor(white) lcolor(white) )
			plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))
			title("  ",
				color(black) size(medsmall) pos(5) )
			subtitle("",
				color(black) justification(center))
			legend(
				position(6)
				cols(2)
				label(1 "Democratic Voters")
				label(2 "Republican Voters")
				region( color(none) )
				size(medsmall)
			)
		   // note("Voters whose precincts change by less than 10 people excluded for visibility.")




	;
	#delimit cr


	* save
	*-----

    graph export $output/kdensity_change_pp_registrants_`year'.pdf, replace


}



			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**

					  ** end of do file **

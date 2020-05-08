
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
    use 20_intermediate_files/65_voter_panel_long_fortargeting.dta, clear
}



* define output directory
*------------------------

global output "$nc_electioneering/50_results_$sample_size"





			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* generate averages
*-------------------------------------------------------------------------------


* averages
*---------

bysort year opposition vra: egen avg_pp_has_changed = mean(pp_has_changed)
label var avg_pp_has_changed "avg polling place has changed by year opposition and vra"


			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**



*-------------------------------------------------------------------------------
* shelby diff-in-diff plot
*-------------------------------------------------------------------------------


* tag
*----

capture drop tag_vra_opp_year
egen tag_vra_opp_year = tag(vra opposition year)
keep if tag_vra_opp_year == 1


* plot
*-----

#delimit ;


	twoway

		// uncovered
		(scatter avg_pp_has_changed year
			if vra == 0 & opposition == 1 & tag_vra_opp_year == 1,
				msize(small) mcolor(black)  xline(2013, lcolor(gs9)) )

		(line avg_pp_has_changed year
			if vra == 0 & opposition == 1 & tag_vra_opp_year == 1,
				lcolor(black)  )

		// covered
		(scatter avg_pp_has_changed year
			if vra == 1 & opposition == 1 & tag_vra_opp_year == 1,
				msize(small) mcolor(gs7) msymbol(circle_hollow) )

		(line avg_pp_has_changed year
			if vra == 1 & opposition == 1 & tag_vra_opp_year == 1,
				lcolor(gs7) lpattern(dash)  )


		,
        title("")
        subtitle("")

		ylabel( .12(.02).22,
    			tlength(0) angle(hori) nogrid labsize(small) )
    	ytitle( "Pr(Opposition Experiencing a PP Change)",
    			angle(hori)	color(black) size(medium) )

    	xlabel(  ,
    			tlength(0) labsize(small) tlcolor(none) labcolor(none) )
    	xtitle("Year",
    			color(black) size(medium) )

		yscale(noline)
		xscale(noline)
    	graphregion(fcolor(white) lcolor(white) )
    	plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))
        legend(
			position(6)
			cols(2)
			order(1 "Covered Counties" 3 "Uncovered Counties")
			region( color(none) )
			size(medsmall)
			)
		;

	#delimit cr


	* output
	*-------

	capture cd "$nc_electioneering/50_results_$sample_size"
    graph export shelby_dind.pdf, replace

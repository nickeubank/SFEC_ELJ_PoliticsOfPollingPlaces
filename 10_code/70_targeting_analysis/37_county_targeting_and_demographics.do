

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




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* make county level dataset
*-------------------------------------------------------------------------------


* keep and collapse
*------------------

keep county_fips county year party_dem race_black
collapse party_dem race_black, by(county_fips year county)



* evaluate for duplicates
*------------------------

duplicates report year county_fips
assert r(unique_value) == r(N)



* label variables
*----------------

label var party_dem "County Democratic Vote Share"
label var race_black "Share of County That Identifies as Black"



* rename county
*--------------

rename county_fips county_num
rename county county_name
gen county_full_name = subinstr(county_name, " County", "",.)
replace county_name = substr(subinstr(county_name, " County", "",.), 1, 10)



* drop
*-----

tostring year, replace
drop if year == "2008"




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* merge with county-level estimates
*-------------------------------------------------------------------------------


* merge
*------

merge 1:1 county_name year using "$nc_electioneering/20_intermediate_files/100_individual_county_regression_coefficients_$sample_size.dta"
drop if year == "all"
assert _m == 3
drop _m

gen swing_county = 1 - abs(party_dem - 0.5)


* make plot
*----------

foreach year in "2012" "2016" {

	foreach iv in "party_dem" "race_black" "swing_county" {

		if "`iv'" == "party_dem" {
            local title = "County Democratic Vote Share"
        }
        else if "`iv'" == "race_black" {
            local title = "Share of the County Black"
        }
		else if "`iv'" == "swing_county" {
			local title = "Swing County (1 - Abs(Dem Vote Share - 0.5))"
		}


		#delimit ;

        twoway

			(lpolyci beta_pp_has_changed `iv' if year == "`year'"  ,
					clcolor(gs5) clpattern(dash) fcolor(none) alcolor(gs2) alpattern(dot) alwidth(thick) )

            (scatter beta_pp_has_changed `iv' if year == "`year'" ,
                  mcolor(black) msymbol(circle_hollow) msize(medium)  )

				 ,

				ylabel( ,
					tlength(0) angle(hori) nogrid labsize(medsmall) )
				ytitle("Increase in Pr(PollingPlaceChange)" "for Opposition Voters",
					angle(hori)	color(black) size(medium) )

				xlabel( ,
					labsize(medsmall) tlcolor(black) labcolor(black) )
				xtitle("`title'",
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
					order(2 "LPoly Fit"  3 "Estimate of Targeting")
					region( color(none) )
					size(medsmall)
				)

               ;


		#delimit cr

		graph export $nc_electioneering/50_results_$sample_size/countyestimates_`iv'_`year'.pdf, replace

    }

}





* END OF County Regs DO FILE
*------------------------------

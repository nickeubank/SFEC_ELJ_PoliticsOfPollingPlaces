


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




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* load the data
*-------------------------------------------------------------------------------


* use the data
*-------------

use "$nc_electioneering/20_intermediate_files/100_individual_county_regression_coefficients_$sample_size.dta", clear




			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* multiple test correction
*-------------------------------------------------------------------------------


* first do multiple test corrections
* -----------------------------------

	/*
		hypotheses be sorted in order of decreasing significance
		M  = num tests
		r = test index when sorted by significance
		q = 0.05 (FDR)
		Let c be the largest r for which p_r < qr/M
		Let c be the largest r for which pr < qr/M.
	*/


gen no_estimate = se_pp_has_changed == 0 & beta_pp_has_changed == 0

foreach year in "2012" "2016" "all"  {

    gen tvalue = beta_pp_has_changed / se_pp_has_changed if year == "`year'" & no_estimate == 0
    gen pvalue = 2*ttail(1000,abs(tvalue)) // Don't just have z-stat, so pick df that converges to normal. Samples always huge.
    sort pvalue
    gen r = _n if year == "`year'" & no_estimate == 0
    egen num_tests = max(r)
    sum num_tests
    local M = r(mean)
    assert `M' <= 100
    assert `M' > 75


    * BKY 2-pass correction
    *----------------------

    // Pass 1
    local q = 0.05
    local q_prime = `q' / (1 + `q')

    gen test_stat = `q_prime' * r / `M'
    gen sig = pvalue < test_stat

    sum sig
    if r(max) == 0{
        gen temp = .
        gen max_reject = 0
    }
    else {
        egen temp = max(r) if sig == 1
        egen max_reject = max(temp)
    }

    gen reject_null_BKY_pass1 = r <= max_reject

    egen rejections = sum(reject_null_BKY_pass1)
    sum rejections
    local c = r(mean)
    drop max_reject temp sig test_stat reject_null_BKY_pass1 rejections



    // Pass 2
    if `c' == 0 {
        gen reject_null_BKY_pass2_`year' = 0 if year == "`year'"
    }
    else {
        * Pass 2
        local m_hat = `M' - `c'
        gen test_stat = `q' * r / `m_hat'
        gen sig = pvalue < test_stat  if year == "`year'"

        egen temp = max(r) if sig == 1
        egen max_reject = max(temp)

        gen reject_null_BKY_pass2_`year' = r <= max_reject  if year == "`year'"
        drop max_reject temp sig test_stat

    }
    drop num_tests tvalue r pvalue


}








			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* confidence intervals
*-------------------------------------------------------------------------------


* generate ci
*------------

gen sortid = _n

local ends = "pp_has_changed"

foreach x of local ends {

	gen cihi_`x' = beta_`x' + (1.96 * se_`x')
	gen cilo_`x' = beta_`x' - (1.96 * se_`x')

}



* county name
*------------

encode county_name, gen(temp)
drop county_name
rename temp county_name



* resort the county number order
*-------------------------------

gen county_num2 = 101 - county_num






			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* make the plots
*-------------------------------------------------------------------------------


* loop to make the plots
*-----------------------

local ends = "pp_has_changed"


foreach year in "2012" "2016" "all"  {

    if "`year'" == "2012" {
        local title = "Democratic Control (2012)"
    }
    if "`year'" == "2016" {
        local title = "Republican Control (2016)"
    }
    if "`year'" == "all" {
        local title = "2012 & 2016"
    }




    foreach x of local ends {


    * plot: ANY vote, part 1 (counties 100-50)
    *-----------------------------------------

    #delimit ;

    	twoway


				// not significant
    		( rcap cihi_`x' cilo_`x' county_num

					if beta_`x' != .  & county_num <= 100 &
						reject_null_BKY_pass2_`year' == 0 & year == "`year'" & se_`x' != 0

    			, lwidth(medthin) color(black) msize(vtiny) hor
    			  xline(0, lwidth(medthin) lcolor(gs9) lpattern(dash) ) )
    		( scatter county_num beta_`x'

					if beta_`x' != .  & county_num <= 100 &
                           reject_null_BKY_pass2_`year' == 0 & year == "`year'" & se_`x' != 0

    			, color(black)  msize(medsmall) msymbol(square_hollow) )


				// significant
            ( rcap cihi_`x' cilo_`x' county_num

				if beta_`x' != .  & county_num <= 100 &
                    reject_null_BKY_pass2_`year' == 1 & year == "`year'" & se_`x' != 0

    			, lwidth(medthin) color(red) msize(vtiny) hor )

    		( scatter county_num beta_`x'

				if beta_`x' != .  & county_num <= 100 &
                        reject_null_BKY_pass2_`year' == 1 & year == "`year'" & se_`x' != 0

    			, color(black)  msize(medium) msymbol(D) mcolor(red) )


    			,

    		ylabel( 	100 "Alamance"
    					99 "Alexander"
    					98 "Alleghany"
    					97 "Anson"
    					96 "Ashe"
    					95 "Avery"
    					94 "Beaufort"
    					93 "Bertie"
    					92 "Bladen"
    					91 "Brunswick"
    					90 "Buncombe"
    					89 "Burke"
    					88 "Cabarrus"
    					87 "Caldwell"
    					86 "Camden"
    					85 "Carteret"
    					84 "Caswell"
    					83 "Catawba"
    					82 "Chatham"
    					81 "Cherokee"
    					80 "Chowan"
    					79 "Clay"
    					78 "Cleveland"
    					77 "Columbus"
    					76 "Craven"
    					75 "Cumberland"
    					74 "Currituck"
    					73 "Dare"
    					72 "Davidson"
    					71 "Davie"
    					70 "Duplin"
    					69 "Durham"
    					68 "Edgecombe"
    					67 "Forsyth"
    					66 "Franklin"
    					65 "Gaston"
    					64 "Gates"
    					63 "Graham"
    					62 "Granville"
    					61 "Greene"
    					60 "Guilford"
    					59 "Halifax"
    					58 "Harnett"
    					57 "Haywood"
    					56 "Henderson"
    					55 "Hertford"
    					54 "Hoke"
    					53 "Hyde"
    					52 "Iredell"
    					51 "Jackson"
    					50 "Johnston"
						49 "Jones"
    					48 "Lee"
    					47 "Lenoir"
    					46 "Lincoln"
    					45 "Macon"
    					44 "Madison"
    					43 "Martin"
    					42 "McDowell"
    					41 "Mecklenburg"
    					40 "Mitchell"
    					39 "Montgomery"
    					38 "Moore"
    					37 "Nash"
    					36 "New Hanover"
    					35 "Northampton"
    					34 "Onslow"
    					33 "Orange"
    					32 "Pamlico"
    					31 "Pasquotank"
    					30 "Pender"
    					29 "Perquimans"
    					28 "Person"
    					27 "Pitt"
    					26 "Polk"
    					25 "Randolph"
    					24 "Richmond"
    					23 "Robeson"
    					22 "Rockingham"
    					21 "Rowan"
    					20 "Rutherford"
    					19 "Sampson"
    					18 "Scotland"
    					17 "Stanly"
    					16 "Stokes"
    					15 "Surry"
    					14 "Swain"
    					13 "Translyvania"
    					12 "Tyrrell"
    					11 "Union"
    					10 "Vance"
    					9 "Wake"
    					8 "Warren"
    					7 "Washington"
    					6 "Watauga"
    					5 "Wayne"
    					4 "Wilkes"
    					3 "Wilson"
    					2 "Yadkin"
    					1 "Yancey"
    					0 " "

    				,
    			tlength(0) angle(hori) nogrid labsize(medsmall) )

    		ytitle( " ",
    			angle(hori)	color(black) size(vsmall) )

    		xlabel(  ,
    			tlength(0) labsize(medium) tlcolor(none) labcolor(none) )
    		xtitle("Increase in Pr(PollingPlaceChange) for Opposition Voters",
    			color(none) size(medium) )

    		xsize(4)
    		ysize(13)
    		xscale(noline range(-.3 .2))
    		yscale(noline)
    		graphregion(fcolor(white) lcolor(white) )
    		plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))
    		title("",
    			color(black) size(medsmall) pos(12) )
    		subtitle("",
    			color(black) justification(center))
    		legend(off  )
    		;

    		#delimit cr




    * output
    *-------

    	capture cd "$nc_electioneering/50_results_$sample_size"
    	capture graph export Plot_County_Coefficients_`x'_part1_`year'.pdf, replace





	// density of county estimates by year
	//------------------------------------
	/*
    twoway(kdensity beta_`x' if se_`x' != 0 & year == "`year'"), ///
        title("Distribution of County-Level Estimates for `year'") ///
        subtitle("Of Increased Likelihood of PP Change for Opposition Voters") ///
        ytitle("Density") ///
        xtitle("Increase in Pr(PollingPlaceChange) for Opposition Voters")
    capture cd "$nc_electioneering/50_results_$sample_size"
    graph export county_point_estimate_density_`x'_`year'.pdf, replace
	*/






	// normal distribution
	//--------------------

	#delimit ;

		pnorm beta_`x' if se_`x' != 0 & year == "`year'"

		,
			mlabel(county_name ) mlabsize(medsmall) mlabangle(-45) mlabposition(4)
			rlop( lcolor(gs7) )  mcolor(black) mlabcolor(black) msymbol(circle_hollow)

			ylabel( ,
    			tlength(0) angle(hori) nogrid labsize(small) )
			ytitle( "Expected Normal Value",
    			angle(hori)	color(black) size(medium) )

			xlabel(  ,
    			tlength(0) labsize(small) tlcolor(none) labcolor(none) )
			xtitle("Observed Value",
    			color(none) size(medium) )

			xsize(9)
			ysize(4)
			xscale(noline)
			yscale(noline)
			graphregion(fcolor(white) lcolor(white) )
			plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))
			title("",
    			color(black) size(medsmall) pos(12) )
			subtitle("",
    			color(black) justification(center))
			legend(off )

	;
	#delimit cr

	* export
	*-------

	graph export county_point_estimate_pnorm_`x'_`year'.pdf, replace


    gen results = 1
    set obs 100000
    replace results = 0 if results == .
    sum beta_`x' if se_`x' != 0 & year == "`year'"
    local min = r(min)
    if `min' > -0.2 {
        local min = -0.2
    }

    local max = r(max)
    if `max' > 0.2 {
        local max = 0.2
    }

    if "`year'" == "2012" {
        gen norm = rnormal(r(mean), `r(sd)' * 0.6)
    }
    else {
        gen norm = rnormal(r(mean), r(sd) * 0.9)
    }

    drop if norm < `min' | norm > `max'




	// plot of distribution of all estimates by year
	//----------------------------------------------

	#delimit ;

    twoway
		(kdensity beta_`x'
			if se_`x' != 0 & year == "`year'" & results == 1,
            xline(0, lwidth(medthin) lcolor(gs9) ) lcolor(gs2) )

        (kdensity norm
			if results == 0 ,
			lcolor(gs7) lpattern(shortdash) )
		,
        title("")
        subtitle("")

		ylabel( ,
    			tlength(0) angle(hori) nogrid labsize(small) )
    	ytitle( "Density",
    			angle(hori)	color(black) size(medium) )

    	xlabel(  ,
    			tlength(0) labsize(small) tlcolor(none) labcolor(none) )
    	xtitle("Increase in Pr(PollingPlaceChange) for Opposition Voters",
    			color(black) size(medium) )

		yscale(noline)
		xscale(noline)
    	graphregion(fcolor(white) lcolor(white) )
    	plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))
        legend(
			position(6)
			cols(2)
			label(1 "County-Estimates") label(2 "Normal PDF")
			region( color(none) )
			size(medsmall)
			)
		;
	#delimit cr


	// export graph
	//-------------

    capture cd "$nc_electioneering/50_results_$sample_size"
    graph export county_point_estimate_density_w_norm_`x'_`year'.pdf, replace





	// drop
	//-----

    drop if results == 0
    capture drop norm
	capture drop results


    }
}





			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


*-------------------------------------------------------------------------------
* 	Distribution of VRA vs. Not VRA point estimates
*-------------------------------------------------------------------------------


* local
*------

sort county_name
local ends = "pp_has_changed"



* gen vra
*--------

capture drop vra
gen vra = 0
replace vra = 1 if county_name == 4
replace vra = 1 if county_name == 7
replace vra = 1 if county_name == 8
replace vra = 1 if county_name == 9
replace vra = 1 if county_name == 15
replace vra = 1 if county_name == 17
replace vra = 1 if county_name == 21
replace vra = 1 if county_name == 23
replace vra = 1 if county_name == 25
replace vra = 1 if county_name == 26
replace vra = 1 if county_name == 33
replace vra = 1 if county_name == 35
replace vra = 1 if county_name == 36
replace vra = 1 if county_name == 37
replace vra = 1 if county_name == 39
replace vra = 1 if county_name == 40
replace vra = 1 if county_name == 41
replace vra = 1 if county_name == 42
replace vra = 1 if county_name == 43
replace vra = 1 if county_name == 46
replace vra = 1 if county_name == 47
replace vra = 1 if county_name == 50
replace vra = 1 if county_name == 53
replace vra = 1 if county_name == 54
replace vra = 1 if county_name == 58
replace vra = 1 if county_name == 64
replace vra = 1 if county_name == 66
replace vra = 1 if county_name == 67
replace vra = 1 if county_name == 70
replace vra = 1 if county_name == 72
replace vra = 1 if county_name == 73
replace vra = 1 if county_name == 74
replace vra = 1 if county_name == 78
replace vra = 1 if county_name == 79
replace vra = 1 if county_name == 83
replace vra = 1 if county_name == 90
replace vra = 1 if county_name == 91
replace vra = 1 if county_name == 94
replace vra = 1 if county_name == 96
replace vra = 1 if county_name == 98



* plot
*-----

#delimit ;

    twoway

		(kdensity beta_`x'
			if se_`x' != 0  & year == "2016" & vra == 1,

				xline(0, lwidth(medthin) lcolor(gs9) ) lcolor(gs2) )

		(kdensity beta_`x'
			if se_`x' != 0  & year == "2016" & vra == 0,

				lcolor(gs7) lpattern(shortdash) )


		,
        title("")
        subtitle("")

		ylabel( ,
    			tlength(0) angle(hori) nogrid labsize(small) )
    	ytitle( "Density",
    			angle(hori)	color(black) size(medium) )

    	xlabel(  ,
    			tlength(0) labsize(small) tlcolor(none) labcolor(none) )
    	xtitle("Increase in Pr(PollingPlaceChange) for Opposition Voters",
    			color(black) size(medium) )

		yscale(noline)
		xscale(noline)
    	graphregion(fcolor(white) lcolor(white) )
    	plotregion(fcolor(white) lstyle(none) lcolor(white) ilstyle(none))
        legend(
			position(6)
			cols(2)
			label(1 "Covered Counties") label(2 "Uncovered Counties")
			region( color(none) )
			size(medsmall)
			)
		;

	#delimit cr


	* output
	*-------

	capture cd "$nc_electioneering/50_results_$sample_size"
    graph export county_point_estimate_density_vra.pdf, replace






			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**
			**	**	**	**	**	**	**	**	**	**	**	**	**


						** end of do file **

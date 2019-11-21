capture log close
log using "$logdir/rawTrends$S_DATE.log", replace

	***************************************************
	* Raw trends : plots                              *
	***************************************************  
clear
use "${finaldatadir}/AllpostSUDState2010_2018_compiled.dta",clear
drop if year ==2009

//exclude late adopters in the plots
	drop if state_code=="PA"| state_code=="IN"| state_code=="AK"| state_code=="MT" ///
	| state_code=="LA"| state_code=="MI"| state_code=="NH"| state_code=="WI"
/*  GRAPHS FOR ALL-YEAR OUTCOMES */

	global outcomes_all lnonhealthPop lhealth_exceptPop lSUDPop ///
	lCounselorPop lEntryLevelPractitionerPop lExclude10JobsPop lMidLevelPractitionerPop ///
	lPrimaryPractitionerPop lPsychologistPop lSocialWorkerPop lTherapistPop ///
	lPsychologist lSocialWorker lTherapist lCounselor lMidLevelPractitioner  ///
	lEntryLevelPractitioner lPrimaryPractitioner lOutpatientPop lHospitalPop ///
	lResidentialPop ///
	nonhealthPop health_exceptPop SUDPop ///
	CounselorPop EntryLevelPractitionerPop Exclude10JobsPop MidLevelPractitionerPop ///
	PrimaryPractitionerPop PsychologistPop SocialWorkerPop TherapistPop ///
	OutpatientPop HospitalPop ResidentialPop count_SUD 
	
	collapse (mean) $outcomes_all , by(year expansion2)
	sort year expansion2
	reshape wide $outcomes_all, i(year) j(expansion2)

	sum nonhealthPop*
//Graphs for number of prescriptions
gen c=10 if year<=2014 //This is the year that Medicaid expansion happen
foreach x in  lnonhealthPop  {
twoway (area c year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("B. Non-Healthcare Sectors", color(black) size(5)) ytitle( "Posts/100k residents, logged", size(5)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(1)2018, angle(horizontal)labsize(4)) ylabel(6(1)10, noticks nogrid labsize(4) angle(horizontal) format(%9.0fc)) ///
	legend(rows(1) order(2 "Expansion States" 3 "Non-Expansion States") size(medium))  saving("${intdir}/DDlnonhealthPop", replace))
drop c
}


gen c=10 if year<=2014 //This is the year that Medicaid expansion happen
foreach x in  lhealth_exceptPop  {
twoway (area c year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("A. Healthcare Sector (Excluding SUDT)", color(black)  size(5)) ytitle( "Posts/100k residents, logged", size(5)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(1)2018, angle(horizontal)labsize(4)) ylabel(6(1)10, noticks nogrid labsize(4) angle(horizontal) format(%9.0fc)) ///
	legend(rows(1) order(2 "Expansion States" 3 "Non-Expansion States") size(medium))  saving("${intdir}/DDlhealth_exceptPop", replace))
drop c
}

	gr combine "${intdir}/DDlhealth_exceptPop.gph" "${intdir}/DDlnonhealthPop.gph",  ///
	 graphregion(color(white)) col(2) iscale(.7273) ysize(3) graphregion(margin(zero))
	graph export "${plotdir}/figure_s2_BG_Medicaid_Healthcare.tif" ,  replace	 width(2000)
	graph export "${plotdir}/figure_s2_BG_Medicaid_Healthcare.png" ,  replace	 width(4000)



gen c=5 if year<=2014 //This is the year that Medicaid expansion happen
gen d=-7 if year<=2014 //This is the year that Medicaid expansion happen

foreach x in lSUDPop  {
twoway (area c year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("A. All SUDT facilities", color(black)  size(4)) ytitle( "Posts per residents, logged", size(4)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(1)2018, angle(horizontal)labsize(4)) ylabel(0(1)5, noticks nogrid labsize(4) angle(horizontal) ) ///
	legend(off) saving("${intdir}/DDlSUDPop", replace) ) 
}

foreach x in lOutpatientPop  {
twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14))  ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("A. Outpatient SUDT facilities", color(black)  size(4)) ytitle( "Posts per residents, logged", size(4)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(1)2018, angle(horizontal)labsize(4)) ylabel(-7(1)5, noticks nogrid labsize(4) angle(horizontal) ) ///
	legend(off) saving("${intdir}/DD`x'", replace) ) 
}

foreach x in lHospitalPop  {
twoway (area c year, bcolor(gs14))   ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("C. Hospital SUDT facilities", color(black)  size(4)) ytitle( "Posts per residents, logged", size(4)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(1)2018, angle(horizontal)labsize(4)) ylabel(0(1)5, noticks nogrid labsize(4) angle(horizontal) ) ///
	legend(rows(1) order(2 "Expansion" 3 "Non-Expansion") size(medsmall)) saving("${intdir}/DD`x'", replace) ) 
}


foreach x in lResidentialPop  {
twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("D. Residential SUDT facilities", color(black)  size(4)) ytitle( "Posts per residents, logged", size(4)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(1)2018, angle(horizontal)labsize(4)) ylabel(-7(1)5, noticks nogrid labsize(4) angle(horizontal) ) ///
	legend(rows(1) order(3 "Expansion" 4 "Non-Expansion")  size(3)) saving("${intdir}/DD`x'", replace) ) 
}


	gr combine "${intdir}/DDlSUDPop"  "${intdir}/DDlOutpatientPop"  "${intdir}/DDlHospitalPop"  ///
	"${intdir}/DDlResidentialPop" , ///
	 graphregion(color(white)) col(2) iscale(.6) ysize(6) graphregion(margin(zero))
	graph export "${plotdir}/figure_5_BGdicaid_SUDT_SubSector.tif"  ,  replace	 width(2000)
	graph export "${plotdir}/figure_5_BGdicaid_SUDT_SubSector.png"  ,  replace	 width(4000)

	
foreach x in lSUDPop  {
twoway (area c year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("A. All SUDT facilities: raw trends", color(black)  size(5)) ytitle( "Posts per residents, logged", size(5)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(1)2018, angle(horizontal)labsize(4)) ylabel(0(1)5, noticks nogrid labsize(4) angle(horizontal) ) ///
	legend(rows(1) order(2 "Expansion States" 3 "Non-Expansion States")  size(3.5)) saving("${intdir}/A_DDlSUDPop", replace) ) 
}
	
// top  occupations
*	CounselorPop EntryLevelPractitionerPop Exclude10JobsPop MidLevelPractitionerPop ///
*	PrimaryPractitionerPop PsychologistPop SocialWorkerPop TherapistPop
drop c d 
gen c=5 if year<=2014 //This is the year that Medicaid expansion happen
gen d=-7 if year<=2014 //This is the year that Medicaid expansion happen
	foreach x in lPsychologistPop  {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("A. Psychologists & Psychiatrists",  color(black)  size(3)) ytitle( "Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal) ) ///
	legend(off) saving("${intdir}/DDlPsychologistPop", replace)) 
}

	foreach x in lSocialWorkerPop  {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("B. Social Workers",  color(black)  size(3)) ytitle("Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal) ) ///
	legend(off)  saving("${intdir}/DDlSocialWorkerPop", replace)) 
}

	foreach x in lCounselorPop  {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("C. Counselors", color(black)  size(3)) ytitle( "Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal) ) ///
	legend(off)  saving("${intdir}/DDlCounselorPop", replace) ) 
}

	foreach x in lTherapistPop  {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("D. Therapists",  color(black)  size(3)) ytitle( "Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal) ) ///
	legend(off) saving("${intdir}/DDlTherapistPop", replace)) 
}

	foreach x in  lEntryLevelPractitionerPop {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("E. Entry-Level Practitioners", color(black)  size(3)) ytitle( "Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal) ) ///
	legend(off)  saving("${intdir}/DDlEntryLevelPractitionerPop", replace)) 
}

	foreach x in  lMidLevelPractitionerPop  {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("F. Mid-Level Practitioners", color(black)  size(3)) ytitle( "Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small ) ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal) ) ///
	legend(off) saving("${intdir}/DDlMidLevelPractitionerPop", replace)) 
}

	foreach x in lPrimaryPractitionerPop  {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("G. Primary Practitioners", color(black)  size(3)) ytitle( "Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small )  ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal)) ///
	legend(off)  saving("${intdir}/DDlPrimaryPractitionerPop", replace)  ) 
}


	foreach x in lExclude10JobsPop  {
	twoway (area c year, bcolor(gs14)) (area d year, bcolor(gs14)) ///
	(connected `x'1 `x'0 year , ///
	graphregion(color(white)) ///
	title("H. Other Professionals", color(black)  size(3)) ytitle( "Posts/100k, logged",size(3)) ///
	xtitle(" ") lcolor("4 21 14" "255 0 1" ) msymbol(square triangle ) msize(small small )  ///
	mcolor("4 21 14" "255 0 1" ) lpattern(solid dash )  lw(*1.5 *1.5 ..) ///
	xlabel(2010(2)2018, angle(horizontal)labsize(3)) ylabel(-7(2)5, noticks nogrid labsize(3) angle(horizontal)) ///
	legend(rows(1) order(3 "Expansion" 4 "Non-Expansion") size(small))  saving("${intdir}/DDlExclude10JobsPop", replace)  ) 
}

	gr combine "${intdir}/DDlPsychologistPop"  "${intdir}/DDlSocialWorkerPop"  "${intdir}/DDlCounselorPop"  ///
	"${intdir}/DDlTherapistPop" "${intdir}/DDlEntryLevelPractitionerPop" "${intdir}/DDlMidLevelPractitionerPop" ///
	"${intdir}/DDlPrimaryPractitionerPop" "${intdir}/DDlExclude10JobsPop", ///
	 graphregion(color(white)) col(2) iscale(.7) ysize(9) graphregion(margin(zero))
	graph export "${plotdir}/figure_s3_BG_Medicaid_SUDT_Occupation.tif"  ,  replace	 width(2000)
	graph export "${plotdir}/figure_s3_BG_Medicaid_SUDT_Occupation.png"  ,  replace	 width(4000)

// distribution

clear
use "${finaldatadir}/AllpostSUDState2010_2018_compiled.dta",clear
drop if year ==2009

sum SUDPop
	twoway (histogram SUDPop if expansion2==1, color(sea)  freq ), ///
			 legend(off)	///
			 xlabel(0(25)150 ,nogrid notick) ///
			 ylabel( ,nogrid notick) ///
			 title("Expansion", size(3.5)) ///
			 ytitle("Frequency", size(4)) graphregion(color(white)) xtitle("Posts/100k residents")  saving(histogram1,replace)
	twoway (histogram SUDPop if expansion2==0, color(vermillion)  freq ), ///
			 legend(off)	///
			 xlabel(0(25)300 ,nogrid notick) ///
			 ylabel( ,nogrid notick) ///
			 title("Non-Expansion", size(3.5)) ///
			 ytitle("Frequency", size(4)) graphregion(color(white)) xtitle("Posts/100k residents")   saving(histogram2,replace)
	graph combine histogram1.gph histogram2.gph , col(1)	graphregion(color(white)) ///
				 title("Historgram of SUD-Related Vacancies", color(black)   size(3.5)) 
	graph export "${plotdir}/figure_s1_Histogram_SUDPop.tif",  replace  width(2000)
	graph export "${plotdir}/figure_s1_Histogram_SUDPop.png",  replace  width(4000)	

log close
exit
	
	

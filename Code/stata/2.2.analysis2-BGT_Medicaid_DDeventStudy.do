	***************************************************
	* Plots: adjusted by state FEs, year FEs          *
	***************************************************  
capture log close
log using "$logdir/EventStudys$S_DATE.log", replace

clear
matrix drop _all
set matsize 11000
clear mata
clear matrix
set maxvar 32767

// plot adjusted trends

use "${finaldatadir}/AllpostSUDState2010_2018_compiled.dta",clear
	drop if year==2009
// events
	gen medicaid_trend_year=year-2014 if expansion2==1
		// for mid-year implementation --if from July --> count for the next year
	replace medicaid_trend_year=year-2014  if state_code=="MI"  //MI expanded in April 2014
	replace medicaid_trend_year=year-2015  if state_code=="NH" //NH expanded in August 2014
	replace medicaid_trend_year=year-2015  if state_code=="PA" //PA expanded in Jan 2015 
	replace medicaid_trend_year=year-2015  if state_code=="IN" //IN expanded in Feb 2015
	replace medicaid_trend_year=year-2016  if state_code=="AK" //AK expanded in Sept 2015
	replace medicaid_trend_year=year-2016  if state_code=="MT" //MT expanded in Jan 2016 
	replace medicaid_trend_year=year-2017  if state_code=="LA" //LA expanded in July 2016

// treatment and control groups: expansion_post
	gen medicaid_event0=1 if medicaid_trend_year==0
	replace medicaid_event0=0 if medicaid_event0==.
	gen medicaid_event1=1 if medicaid_trend_year==1
	replace medicaid_event1=0 if medicaid_event1==.
	gen medicaid_event2=1 if medicaid_trend_year==2
	replace medicaid_event2=0 if medicaid_event2==.
	gen medicaid_event3=1 if medicaid_trend_year==3
	replace medicaid_event3=0 if medicaid_event3==.
	gen medicaid_event4=1 if medicaid_trend_year>=4 & medicaid_trend_year!=. 
	replace medicaid_event4=0 if medicaid_event4==.
	gen medicaid_event1_plus=1 if medicaid_trend_year>=1 & medicaid_trend_year!=. 
	replace medicaid_event1_plus=0 if medicaid_event1_plus==.
	gen medicaid_event0_plus=1 if medicaid_trend_year>=0 & medicaid_trend_year!=. 
	replace medicaid_event0_plus=0 if medicaid_event0_plus==.

	gen medicaid_event_1=1 if medicaid_trend_year==-1
	replace medicaid_event_1=0 if medicaid_event_1==.
	gen medicaid_event_2=1 if medicaid_trend_year==-2
	replace medicaid_event_2=0 if medicaid_event_2==.
	gen medicaid_event_3=1 if medicaid_trend_year==-3
	replace medicaid_event_3=0 if medicaid_event_3==.
	gen medicaid_event_4=1 if medicaid_trend_year<=-4 & medicaid_trend_year!=.
	replace medicaid_event_4=0 if medicaid_event_4==.
	
	gen zero=0	
	label var zero "-1"
	label var medicaid_event_1 "-1"
	label var medicaid_event_2 "-2"
	label var medicaid_event_3 "-3"
	label var medicaid_event_4 "{&le}-4"
	label var medicaid_event0 "0"
	label var medicaid_event1 "1"
	label var medicaid_event1_plus "{&ge}1"
	label var medicaid_event2 "2"
	label var medicaid_event3 "3"
	label var medicaid_event4 "4"
	
	foreach var in nonhealth health_except SUD ///
	 Outpatient Hospital Residential  {
		gen Any`var'=0
		replace Any`var'=1 if count_`var'!=0
		}
	foreach var in Counselor EntryLevelPractitioner Exclude10Jobs MidLevelPractitioner ///
	PrimaryPractitioner Psychologist SocialWorker Therapist  {
		gen Any`var'=0
		replace Any`var'=1 if `var'Pop!=0
					}
	
	save "${finaldatadir}/AllpostSUDState2010_2018_compiled_events.dta",replace

	
	
	
	
	
	use "${finaldatadir}/AllpostSUDState2010_2018_compiled_events.dta",clear
	xtset st_fips year
	
	
	reghdfe count_SUD expansion_post  ue lmedian_income prescribingrate ageadjustedrate ///
		   ,  absorb(st_fips year ) vce(cluster st_fips)
	gen include=e(sample)==1

	sum count_SUD
	dis r(sum)
	sum count_Hospital
	dis r(sum)
	sum count_Outpatient
	dis r(sum)
	sum count_Residential
	dis r(sum)	
	
	
 foreach var in SUD Outpatient Residential Hospital  Counselor EntryLevelPractitioner Exclude10Jobs MidLevelPractitioner ///
	PrimaryPractitioner Psychologist SocialWorker Therapist {
	sum Any`var'
	}
	

 foreach var in SUD Outpatient Residential Hospital  Counselor EntryLevelPractitioner Exclude10Jobs MidLevelPractitioner ///
	 Psychologist SocialWorker Therapist {
reghdfe l`var'Pop expansion_post ue lmedian_income prescribingrate ageadjustedrate   ///
	if include==1 ,  absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L1
        estadd ysumm		
reghdfe l`var'Pop medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4 ///
	ue lmedian_income prescribingrate ageadjustedrate   if include==1, absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'LES1	
nbreg count_`var' expansion_post statepop100k ue lmedian_income prescribingrate ageadjustedrate i.st_fips i.year  ///
	if include==1 ,  vce(cluster st_fips)
        eststo `var'N1
        estadd ysumm	
nbreg count_`var' medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4 ///
	statepop100k ue lmedian_income prescribingrate ageadjustedrate   i.st_fips i.year  ///
	if include==1 ,  vce(cluster st_fips)
        eststo `var'NES1
nbreg R`var'Pop expansion_post ue lmedian_income prescribingrate ageadjustedrate i.st_fips i.year  ///
	if include==1 ,  vce(cluster st_fips)
        eststo `var'R1
        estadd ysumm	
nbreg R`var'Pop medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4 ///
	 ue lmedian_income prescribingrate ageadjustedrate   i.st_fips i.year  ///
	if include==1 ,  vce(cluster st_fips)
        eststo `var'RES1	
	}

 foreach var in PrimaryPractitioner {
reghdfe l`var'Pop expansion_post ue lmedian_income prescribingrate ageadjustedrate   ///
	if include==1 ,  absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L1
        estadd ysumm		
reghdfe l`var'Pop medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4 ///
	ue lmedian_income prescribingrate ageadjustedrate   if include==1, absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'LES1	
	}


 foreach var in Psychologist {
reghdfe l`var'Pop expansion_post ue lmedian_income prescribingrate ageadjustedrate   ///
	if include==1 ,  absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L1
        estadd ysumm		
	
	}
	
  /// DD results :   

  coefplot SUDLES1,  omitted keep(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4) ///
	yline(0) title("B. SUDT Job Vacancy: Event Study Estimates", color(black) size(5)) ytitle("Estimated change",size(5))  xtitle("Years prior to/after expansion", size(5))  ///
	order(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1_plus)  ///
	vertical   msymbol(square) mfcolor(black)  levels(90 95)  ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(black bue) ) /// 
	xlabel(,labsize(medsmall)) ///
	graphregion(color(white)) saving("${intdir}/DD_OLS_lSUDPop", replace)
 
 
  coefplot ResidentialLES1,  omitted keep(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4) ///
	yline(0) title("Residential SUDT Job Vacancy: Event Study Estimates", color(black) size(4)) ytitle("Estimated change",size(5))  xtitle("Years prior to/after expansion", size(5))  ///
	order(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1_plus)  ///
	vertical   msymbol(square) mfcolor(black)  levels(90 95)  ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(black bue) ) /// 
	xlabel(,labsize(medsmall)) ///
	graphregion(color(white)) saving("${intdir}/DD_OLS_lResidentialPop", replace)
 	graph export "${plotdir}/figure_3_BG_Medicaid_lResidentialPop.tif" ,  replace	 width(2000)
	graph export "${plotdir}/figure_3_BG_Medicaid_lResidentialPop.png" ,  replace	 width(4000)	

 
  coefplot SUDNES1,  omitted keep(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4) ///
	yline(0) title("B. SUDT Job Vacancy: Event Study Estimates", color(black) size(5)) ytitle("Estimated change",size(5))  xtitle("Years prior to/after expansion", size(5))  ///
	order(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1_plus)  ///
	vertical   msymbol(square) mfcolor(black)  levels(90 95)  ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(black bue) ) /// 
	xlabel(,labsize(medsmall)) ///
	graphregion(color(white)) saving("${intdir}/DD_NB_count_SUD", replace)
 
 
   coefplot SUDRES1,  omitted keep(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1  ///
	medicaid_event2 medicaid_event3 medicaid_event4) ///
	yline(0) title("B. SUDT Job Vacancy: Event Study Estimates", color(black) size(5)) ytitle("Estimated change",size(5))  xtitle("Years prior to/after expansion", size(5))  ///
	order(medicaid_event_4 medicaid_event_3 medicaid_event_2 zero medicaid_event0 medicaid_event1_plus)  ///
	vertical   msymbol(square) mfcolor(black)  levels(90 95)  ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(black bue) ) /// 
	xlabel(,labsize(medsmall)) ///
	graphregion(color(white)) saving("${intdir}/DD_NB_RSUDPop", replace)
 
 
 
 	gr combine "${intdir}/A_DDlSUDPop.gph" "${intdir}/DD_OLS_lSUDPop.gph",  ///
	 graphregion(color(white)) col(2) iscale(.7273) ysize(3) graphregion(margin(zero))
	graph export "${plotdir}/figure_3_BG_Medicaid_SUDT.tif" ,  replace	 width(2000)
	graph export "${plotdir}/figure_3_BG_Medicaid_SUDT.png" ,  replace	 width(4000)	

	
 	
 
	sum PsychologistPop SocialWorkerPop  CounselorPop TherapistPop ///
	 EntryLevelPractitionerPop MidLevelPractitionerPop PrimaryPractitionerPop Exclude10JobsPop if include==1
	
  	esttab SUDL1 SUDN1 SUDR1  ///
	using "${tabledir}/table_s1_DD_DifferentMethod.tex",   ///
	keep(expansion_post  ue lmedian_income prescribingrate ageadjustedrate  statepop100k) ///
	order(expansion_post ue lmedian_income prescribingrate ageadjustedrate statepop100k ) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) label ///
	booktabs b(a2) ar2(a2) se(a2) eqlabels(none) alignment(S S) ///
	stats(ymean ysd N , fmt(%3.2f %3.2f %3.0f )  ///
	    layout("\multicolumn{1}{c}{@}"  "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
	    label("\hline Dep. Variable Mean" "Dep. Variable SD" "N" )) ///
	    f substitute(\_ _) ///
	    noline collabels(none) ///
	    nogaps compress nomtitles ///
	    replace	

	    
 

coefplot (SUDL1 )  (OutpatientL1 )  (ResidentialL1 )  (HospitalL1 )  (PsychologistL1 ) ///
	(SocialWorkerL1) ///
	(CounselorL1) ///
	(TherapistL1) ///
	(EntryLevelPractitionerL1) ///
	(MidLevelPractitionerL1) ///	
	(PrimaryPractitionerL1) (Exclude10JobsL1) ///
	,  keep(expansion_post  ) aseq swapnames  ///	
	coeflabels(SUDL1="All Professionals" ///
	OutpatientL1="Outpatient SUDT" ///
	ResidentialL1="Residential SUDT" ///
	HospitalL1="Hospital SUDT" ///	
	SocialWorkerL1="Social Workers" ///	
	PsychologistL1="Psychologists" ///
	CounselorL1="Counselors" ///
	TherapistL1="Therapists" ///
	EntryLevelPractitionerL1="Entry-Level Practitioners" ///
	MidLevelPractitionerL1="Mid-Level Practitioners"  /// 
	PrimaryPractitionerL1="Primary Practitioners" /// 
	Exclude10JobsL1="Other Professionals" ) /// 
	xline(0) xlabel(,angle(0) labsize(small) nogrid ) nooffset level(90 95) legend(off) ///
	ytitle("")  xtitle("Estimate coefficients",  color(black) )  ///
	 citop msymbol(square) ciopts(recast(rcap  lowerlimit upperlimit barposition ) lcolor(black black) ) ///
	 graphregion(color(white)) color(black ) saving("${intdir}/DD_OLS_LogCOUNT", replace)  
	graph export "${plotdir}/figure_4_BG_Medicaid_SUDT.tif" ,  replace	 width(2000)
	graph export "${plotdir}/figure_4_BG_Medicaid_SUDT.png" ,  replace	 width(4000)	
	    

	// robustness check
	// (1) exclude ME 

	// (1) exclude 5 early states: DC, DE, MA, NY, VT
		
	// (2) drop :  prescribingrate ageadjustedrate
	
	// NBREG model  - count model 

	// adjust for p-values (not very necessary)
	
	// leave-out analysis --> plot coefficient
	
	
	// lag DD 
	clear all 
	
	use "${finaldatadir}/AllpostSUDState2010_2018_compiled_events.dta",clear

	xtset st_fips year		
	reghdfe count_SUD expansion_post  ue lmedian_income prescribingrate ageadjustedrate ///
		   ,  absorb(st_fips year ) vce(cluster st_fips)
	gen include=e(sample)==1
		
		
 foreach var in SUD  {								
reghdfe l`var'Pop expansion_post ue lmedian_income prescribingrate ageadjustedrate   ///
	if include==1 , absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L1
        estadd ysumm
reghdfe l`var'Pop expansion_post ue lmedian_income prescribingrate ageadjustedrate   ///
	if include==1 & state_code!="ME" ,absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L2
        estadd ysumm	
reghdfe l`var'Pop expansion_post ue lmedian_income prescribingrate ageadjustedrate   ///
	if include==1 & state_code!="DC" & state_code!="DE" & state_code!="MA" & state_code!="NY" & state_code!="VT",absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L3
        estadd ysumm	
reghdfe l`var'Pop expansion_post ue lmedian_income  ///
	if include==1 , absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L4
        estadd ysumm		
reghdfe l`var'Pop Lexpansion_post ue lmedian_income prescribingrate ageadjustedrate  ///
	if include==1 , absorb(st_fips year ) vce(cluster st_fips)
        eststo `var'L5
        estadd ysumm	
	
	
  	esttab `var'L1 `var'L3 `var'L4 `var'L5   ///
	using "${tabledir}/table_s2_DD_`var'Robust.tex",   ///
	keep(expansion_post Lexpansion_post ue lmedian_income prescribingrate ageadjustedrate  ) ///
	order(expansion_post Lexpansion_post ue lmedian_income prescribingrate ageadjustedrate  ) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) label ///
	booktabs b(a2) ar2(a2) se(a2) eqlabels(none) alignment(S S) ///
	stats(ymean ysd N , fmt(%3.2f %3.2f %3.0f )  ///
	    layout("\multicolumn{1}{c}{@}"  "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
	    label("\hline Dep. Variable Mean" "Dep. Variable SD" "N" )) ///
	    f substitute(\_ _) ///
	    noline collabels(none) ///
	    nogaps compress nomtitles ///
	    replace		
		}
	
  /// DD results : Outpatient Residential Hospital  Counselor EntryLevelPractitioner Exclude10Jobs MidLevelPractitioner ///
	*PrimaryPractitioner Psychologist SocialWorker Therapist  
  	/// drop ME  
	
	

	    
	
	// leave out analysis
	
	
	use "${finaldatadir}/AllpostSUDState2010_2018_compiled_events.dta",clear
	sort state_code
	tab state_code
	xtset st_fips year
	
	local X  AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA ///
	MA ME MD MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY

	reghdfe count_SUD expansion_post  ue lmedian_income prescribingrate ageadjustedrate ///
	,  absorb(st_fips year ) vce(cluster st_fips)
	gen include=e(sample)==1
	

	 foreach x in `X'  {

	quiet reghdfe lSUDPop expansion_post ue lmedian_income prescribingrate ageadjustedrate   ///
	if include==1 & state_code!=`"`x'"' , absorb(st_fips year ) vce(cluster st_fips)
	eststo `x'
		estadd ysumm	
	}
	
	coefplot AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA ///
	MA ME MD MI MN  MO MS  ///
	,   keep(expansion_post  ) aseq swapnames  ///	
	xline(0) xlabel(,angle(0) labsize(3.5) nogrid ) nooffset level(95) legend(off) ///
	ytitle(Dropped state)  xtitle("",  color(black) )  ///
	 citop msymbol(square) ciopts(recast(rcap  lowerlimit upperlimit barposition ) lcolor(black black) ) ///
	  graphregion(color(white)) color(black) saving("${intdir}/leave_one_out1", replace) 

	  coefplot MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY ///
	,   keep(expansion_post  ) aseq swapnames  ///	
	xline(0) xlabel(,angle(0) labsize(3.5) nogrid ) nooffset level(95) legend(off) ///
	ytitle("")  xtitle("",  color(black) )  ///
	 citop msymbol(square) ciopts(recast(rcap  lowerlimit upperlimit barposition ) lcolor(black black) ) ///
	  graphregion(color(white)) color(black) saving("${intdir}/leave_one_out2", replace) 


  	gr combine "${intdir}/leave_one_out1.gph" "${intdir}/leave_one_out2.gph",  ///
	 graphregion(color(white)) col(2) iscale(1) ysize(3) graphregion(margin(zero))
	graph export "${plotdir}/figure_6_BG_Medicaid_SUDPop_leave_one_out.tif" ,  replace	 width(2000)
	graph export "${plotdir}/figure_6_BG_Medicaid_SUDPop_leave_one_out.png" ,  replace	 width(4000)	

	

 
log close
exit

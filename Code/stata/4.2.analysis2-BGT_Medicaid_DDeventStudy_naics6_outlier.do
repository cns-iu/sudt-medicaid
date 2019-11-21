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

use "${finaldatadir}/AllpostSUDState2010_2018_compiled_naics6_outlier.dta",clear
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
	
	save "${finaldatadir}/AllpostSUDState2010_2018_compiled_events_naics6_outlier.dta",replace

	
	
	
	
	
	use "${finaldatadir}/AllpostSUDState2010_2018_compiled_events_naics6_outlier.dta",clear
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

	
  /// DD results :       


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
	graph export "${plotdir}/figure_4_BG_Medicaid_SUDT_naics6_outlier.tif" ,  replace	 width(2000)
	graph export "${plotdir}/figure_4_BG_Medicaid_SUDT_naics6_outlier.png" ,  replace	 width(4000)	
	    
	
 
log close
exit

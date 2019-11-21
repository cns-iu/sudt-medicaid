	***************************************************
	* Read BG data                                    *
	***************************************************    
capture log close
	
log using "$logdir/BGdata$S_DATE.log", replace

// Converting csv files to BG county stata files
	import delimited "/Box/thdnguye/SUDT_DataSet/BGT Extract NAICS4/naics4 original/jobs-sector-62-non-SUDT-count-year.csv",  clear	
	ren count count_health_except
	save "${intdir}/count_health_except2007_2019.dta",replace

	import delimited "${datadir}/BG/bg-industry-non-healthcare-naics-county-state-2007-2019.csv",  clear
	ren count count_nonhealth
	save "${intdir}/count_nonhealth2007_2019.dta",replace
	
	import delimited "/Box/thdnguye/SUDT_DataSet/BGT Extract NAICS4/naics4 hospital + sub naics6 residential and outpatient/Job-Occupation/Data/naics4-subnaics6-state-year-naics4-naics6-jobcount-without-providenceJuly2013.csv",  clear
	ren count count_SUD
	sum count_SUD
	dis r(sum)
	save "${intdir}/count_SUD2007_2019.dta",replace
	
	// occupations from nationwise for 3 SUD industries, 2010-2018	
	clear
	import delimited "/Box/thdnguye/SUDT_DataSet/BGT Extract NAICS4/naics4 hospital + sub naics6 residential and outpatient/Job-Occupation/Data/naics4-subnaics6-socname-year-naics4-state-jobcount-without-providenceJuly2013.csv",  clear
	ren state state_name
	ren counts COM
	sort state_name socname year
	tab socname

	sum COM if strpos(lower(socname), "na")
	gen  soc_name="Exclude10Jobs"	

	replace soc_name="PrimaryPractitioner" if strpos(lower(socname), "general practitioner") ///
	| strpos(lower(socname), "treating practitioner") |socname=="Physicians and Surgeons, All Other"

	replace soc_name="MidLevelPractitioner" if ( strpos(lower(socname), "physician assistants") ///
	| strpos(lower(socname), "nurse practitioners") | socname=="Registered Nurses"| ///
	strpos(lower(socname), "clinical laboratory technicians") | strpos(lower(socname), "clinical laboratory technologist") ///
	| strpos(lower(socname), "pharmacy technician") | strpos(lower(socname), "cardiovascular technologists") | socname=="Licensed Practical and Licensed Vocational Nurses" | strpos(lower(socname), "nurses") ) ///
	 & strpos(lower(socname), "assistant") ==0& strpos(lower(socname), "aides") ==0

	replace soc_name="Psychologist" if ( strpos(lower(socname), "psychiatry")|strpos(lower(socname), "psychiatrist") ///
	| strpos(lower(socname), "psychologist") ) & strpos(lower(socname), "assistant") ==0& strpos(lower(socname), "aides") ==0
	
	replace soc_name="Counselor" if strpos(lower(socname), "counselors")

	replace soc_name="SocialWorker" if strpos(lower(socname), "social worker")
	
	replace soc_name="Therapist" if strpos(lower(socname), "therapist") ///
	& strpos(lower(socname), "assistant") ==0& strpos(lower(socname), "aides") ==0

	replace soc_name="EntryLevelPractitioner" if strpos(lower(socname), "aides") ///
	| strpos(lower(socname), "medical assistant")| strpos(lower(socname), "nursing assistant") ///
	|  strpos(lower(socname), "therapy assistant")|  strpos(lower(socname), "therapist assistant") ///
	| socname=="Social and Human Service Assistants"| socname=="Residential Advisors" ///
	| socname=="technician" & strpos(lower(socname), "clinical laboratory technicians")==0 ///
	| socname=="childcare workers" | socname=="medical secretaries" | socname=="support workers"
		
	sum COM if soc_name=="MidLevelPractitioner"
	dis r(sum)
	sum COM if soc_name=="PrimaryPractitioner"
	dis r(sum)
	sum COM if soc_name=="EntryLevelPractitioner"
	dis r(sum)
	sum COM if soc_name=="SocialWorker"
	dis r(sum)
	sum COM if soc_name=="Therapist"
	dis r(sum)
	sum COM if soc_name=="Counselor"
	dis r(sum)
	sum COM if soc_name=="Exclude10Jobs"
	dis r(sum)
	sum COM 
	dis r(sum)
	
	tab soc_name
	
	tostring year, replace
	gen state_year = state_name + "_" + year
	collapse (sum) COM, by(state_year soc_name)
	reshape wide COM@, i(state_year) j(soc_name) string
	split state_year, p("_")
	ren state_year1 state_name
	ren state_year2 year
	destring year, replace
	sort state_name year
	drop state_year 
	replace state_name=lower(itrim(state_name))	
	sort state_name year
	
	foreach var in Counselor EntryLevelPractitioner Exclude10Jobs MidLevelPractitioner ///
	PrimaryPractitioner Psychologist SocialWorker Therapist  {
	 ren COM`var' `var'
	 }
	
	sum 
	drop if state_name=="na"|state_name=="NA"
	save "${intdir}/StatePanelCOMTop19Jobs.dta",replace


// reading 3 treatment code data --> generage state-level data [not exclude ]
	foreach var in health_except nonhealth SUD {
	use "${intdir}/count_`var'2007_2019.dta",clear
	keep if year >=2009 & year<2019	
		ren state state_name
		replace state_name=lower(itrim(state_name))				
		collapse (sum) count_`var', by (state_name year )
		sum count_`var'
		dis r(sum)
	sort state_name year
	save "${intdir}/count_`var'State2010_2018.dta",replace
		}
		
		
	use "${intdir}/count_SUD2007_2019.dta",clear
	keep if year >=2009 & year<2019
	keep state year  count_SUD naics4

	gen count_Outpatient = count_SUD if naics4==6214
	gen count_Hospital = count_SUD if naics==6222
	gen count_Residential = count_SUD if naics4==6232
	ren state state_name
	replace state_name=lower(itrim(state_name))					
	collapse (sum) count_Outpatient count_Hospital count_Residential  count_SUD , by (state_name year )
		sum count_Outpatient
		dis r(sum)
		sum count_Hospital
		dis r(sum)
		sum count_Residential
		dis r(sum)	
	sort state_name year	
	// adjust for Maine data
	sum count_Outpatient count_Hospital count_Resident count_SUD if state_name=="maine" & year==2013
	*replace count_Outpatient=143 if state_name=="maine" & year==2013
	*replace count_SUD=144 if state_name=="maine" & year==2013
	sum count_Outpatient count_Hospital count_Resident count_SUD if state_name=="maine" & year==2013
	 
	save "${intdir}/postSUDState2010_2018.dta",replace
		
	
	***************************************************
	* Compiling data                                    *
	***************************************************    
	
	use "${intdir}/count_nonhealthState2010_2018.dta",clear
	merge 1:1 state_name year using "${intdir}/postSUDState2010_2018.dta", ///
	nogen keepusing(count_Outpatient count_Hospital count_Residential count_SUD ) 
	merge 1:1 state_name year using "${intdir}/count_health_exceptState2010_2018.dta", ///
	nogen keepusing(count_health_except) 
	sort state_name year
	codebook state_name year
	drop if year<2009 | year>2018
	merge 1:1 state_name year using "${intdir}/StatePanelCOMTop19Jobs.dta",	nogen  keep (1 3)	
	sort state_name year
	codebook state_name year
	drop if year<2009 | year>2018
	
	merge 1:1 state_name year using  "${intdir}/state_year_data2009_2017.dta", keep (2 3) nogen
	merge 1:1 state_name year using  "${intdir}/state_population_year2010_2018.dta", keep (1 3) nogen
	
	foreach var in nonhealth SUD Outpatient Hospital Residential health_except {
	replace count_`var'=0 if count_`var'==.
	label var count_`var' "Postings-`var'"
	gen `var'Pop=count_`var'/statepop*100000
	sum,detail
	}
	
	foreach var in Counselor EntryLevelPractitioner Exclude10Jobs MidLevelPractitioner ///
	PrimaryPractitioner Psychologist SocialWorker Therapist {
	replace `var'=0 if `var'==.
	label var `var' "`var'"
	gen `var'Pop=`var'/statepop*100000
	ren `var' count_`var'
	sum,detail
	}
	
// Medicaid expansion 

	gen expansion4=.

	label var expansion4 "0 is no expansion, 1 is full expansion, 2 is mild expansion, 3 is substantial expansion"
	local control AL AK FL GA ID IN KS LA MI MS ME MO MT NE NH NC OK PA SC SD TN TX UT VA WY 
	foreach x in `control' { 
	replace expansion4=0 if state_code==`"`x'"'
	      }
	      
	local treatment AZ AR CO IL IA KY MD NV NM NJ ND OH OR RI WV  WA 
	foreach x in `treatment' { 
	replace expansion4=1 if state_code==`"`x'"'
	       }      
	local mild DE DC MA NY VT
	foreach x in `mild' {
	replace expansion4=2 if state_code==`"`x'"'
	       }
	local medium CA CT HI MN WI
	foreach x in `medium' {
	replace expansion4=3 if state_code==`"`x'"'
	       }
	//Account for mid-year expansions
	replace expansion4=1 if state_code=="MI"  //MI expanded in April 2014
	replace expansion4=1 if state_code=="NH"  //NH expanded in August 2014
	replace expansion4=1 if state_code=="PA"  //PA expanded in Jan 2015 
	replace expansion4=1 if state_code=="IN" //IN expanded in Feb 2015
	replace expansion4=1 if state_code=="AK"  //AK expanded in Sept 2015
	replace expansion4=1 if state_code=="MT" //MT expanded in Jan 2016 
	replace expansion4=1 if state_code=="LA" //LA expanded in July 2016
	*Maine's Medicaid expansion is approved but not yet implemented, so we will consider ME a non-expansion state.

	//3 category expansion info
	gen expansion3=expansion4
	label var expansion3 "0 is no expansion, 1 is full expansion, 2 is mild/substantial expansion"
	recode expansion3 3=2

	//2 category expansion info
	gen expansion2=expansion4
	label var expansion2 "0 is no expansion, 1 is any expansion"
	recode expansion2 3=1 2=1
	label var expansion2 "Expansion"
	gen post=year>=2014
	label var post "Post-2014"
		     
	// medicaid expansion - time varying
	xtset st_fips year
	gen expansion_post=post*expansion2
	gen Lexpansion_post=l.expansion_post
	
	drop if year==2009
	tab expansion_post Lexpansion_post
		label var expansion_post "Expansion$\times$Post-2014"
		label var Lexpansion_post "LaggedExpansion$\times$Post-2014"
	
	replace expansion_post=0 if state_code=="MI"&year<2014  //MI expanded in April 2014
		replace expansion_post=(12-4+1)/12 if state_code=="MI"&year==2014  //MI expanded in April 2014	
	replace expansion_post=0 if state_code=="NH"&year<2014  //NH expanded in August 2014
		replace expansion_post=(12-8+1)/12 if state_code=="NH"&year==2014  //NH expanded in August 2014
	replace expansion_post=0 if state_code=="PA"&year<2015  //PA expanded in Jan 2015 
	replace expansion_post=0 if state_code=="IN"&year<2015  //IN expanded in Feb 2015
		replace expansion_post=(12-2+1)/12 if state_code=="IN"&year==2015
	replace expansion_post=0 if state_code=="AK"&year<2015  //AK expanded in Sept 2015
		replace expansion_post=(12-9+1)/12 if state_code=="IN"&year==2015
	replace expansion_post=0 if state_code=="MT"&year<2016 //MT expanded in Jan 2016 
	replace expansion_post=0 if state_code=="LA"&year<2016 //LA expanded in July 2016
		replace expansion_post=(12-7+1)/12 if state_code=="LA"&year==2016
	

	tab expansion2 expansion_post
	foreach var in nonhealthPop SUDPop OutpatientPop HospitalPop ///
	ResidentialPop health_exceptPop  ///
	Counselor EntryLevelPractitioner Exclude10Jobs MidLevelPractitioner ///
	PrimaryPractitioner Psychologist SocialWorker Therapist ///
	CounselorPop EntryLevelPractitionerPop Exclude10JobsPop MidLevelPractitionerPop ///
	PrimaryPractitionerPop PsychologistPop SocialWorkerPop TherapistPop {
	gen l`var'=log(`var'+.001)
		}

// create panel data for regression analyses
	codebook state_code year st_fips 
	codebook median_income prescribingrate ageadjustedrate pov_rate_all_ages ue
	
	histogram count_SUD	

	xtset st_fips year
	gen lmedian_income=log(median_income)
	gen statepop100k =statepop/100000	
	label var lmedian_income "Median income, logged"
	label var statepop100k "State populations, 100k"	
	label var prescribingrate "Opioid prescribing rates"	
	label var ageadjustedrate "Drug poisoning death rates"	
	label var pov_rate_all_ages "Poverty rates, \%"	
	label var ue "Unemployment rates, \%"	
	
	sum CounselorPop EntryLevelPractitionerPop Exclude10JobsPop MidLevelPractitionerPop ///
	PrimaryPractitionerPop PsychologistPop SocialWorkerPop TherapistPop SUDPop,detail
	
	foreach var in SUDPop  OutpatientPop HospitalPop ///
	ResidentialPop CounselorPop EntryLevelPractitionerPop Exclude10JobsPop MidLevelPractitionerPop ///
	PrimaryPractitionerPop PsychologistPop SocialWorkerPop TherapistPop {
	gen `var'100=`var'*100
	gen R`var'=round(`var'100)
*	replace R`var'=1 if `var'<1 &  `var'>0 &  `var'!=.
	sum R`var',detail
	}
	
	tab RMidLevelPractitionerPop
	tab REntryLevelPractitionerPop
	tab RSUDPop
	sum SUDPop,detail
	
	 
// a cut-off value for outliers (exceed percentile 99th), were set to percentile 99
	foreach var in CounselorPop EntryLevelPractitionerPop Exclude10JobsPop MidLevelPractitionerPop ///
	PrimaryPractitionerPop PsychologistPop SocialWorkerPop TherapistPop SUDPop {
	egen p99`var'=pctile(`var'),p(99)
	list state_code year if `var'>p99`var'
	egen p90`var'=pctile(`var'),p(90)
	list state_code year if `var'>p90`var'	
	 }
	foreach var in CounselorPop EntryLevelPractitionerPop Exclude10JobsPop MidLevelPractitionerPop ///
	PrimaryPractitionerPop PsychologistPop SocialWorkerPop TherapistPop SUDPop {
	gen `var'9= `var' 	
		replace `var'9= p99`var' if `var'>p99`var' & `var'!=.
	gen `var'5= `var' 	
		replace `var'5= p90`var' if `var'>p90`var' & `var'!=. 	
	 }
	histogram RSUDPop
	sum SUDPop9 SUDPop5 SUDPop,detail
	
save  "${finaldatadir}/AllpostSUDState2010_2018_compiled_naics6_outlier.dta",replace
		


log close
exit

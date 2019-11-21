////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
// Replication code for: 
// 	Hiring in opioid addictions treatment workforce during the first five years of Medicaid expansion

// By: Nguyen (thdnguye@indiana.edu), Scrivner, Simon, Middaugh, Taska, and Borner 

// Citation: Insert citation here. TBD
// Paper DOI: TBD

// To cite this code or data please use the Zenodo DOI below.
// Code/Repository DOI: 

// Version: May 2019

// File: BG_allsteps.do

// Description: This file runs all code needed to replicate our paper

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

// Version of stata
version 15

// Close any open log files
capture log close

// Clear Memory
clear all

// Set Date
global date = subinstr("$S_DATE", " ", "-", .)

// Set your file paths.

global basedir "/N/dc2/scratch/thdnguye/PlosOneBG"   // Root folder directory that contains the subfolders for constructing the dataset and estimation
global intdir "${basedir}/intermediate_results" // Path for temp folder
global datadir "${basedir}/RawData"  // Path for raw data
global finaldatadir "${basedir}/DataForAnalysis"  // Path for data used in analysis
global sourcedir "${basedir}/Scripts" // Path for running the scripts to create tables and figures
global plotdir "${basedir}/Figures"  // Path for tables/figures output
global tabledir "${basedir}/Tables" // Path for tables/figures output
global logdir "${basedir}/Logs" // Path for logs


/* Start log */
capture log close

cd "${basedir}"

// Specify Screen Width for log files
set linesize 255

// Set font type
graph set window fontface "Times New Roman"

// Allow the screen to move without having to click more
set more off

// Drop everything in mata
matrix drop _all

// Install Stata Packages
local install_stata_packages 0

// Install Packages if needed, if not, make a note of this. This should be a comprehensive list of all additional packages needed to run the code.
if `install_stata_packages' {
	ssc install carryforward, replace
	ssc install estout, replace	
	ssc install reghdfe, replace
	ssc install blindschemes, replace
	ssc install coefplot, replace
	ssc install statastates, replace 
	ssc install ftools, replace
	ssc install shp2dta, replace
	ssc install spmap, replace
	ssc install sumup, replace
	
	ssc install distinct, replace
	ssc install unique, replace
	ssc install statastates, replace
	net get statastates.dta, replace
	ssc install binscatter, replace
}
else  {
	di "All packages up-to-date"
}


// Specify Screen Width for log files
set linesize 255

// Set font type
graph set window fontface "Times New Roman"
////////////////////////////////////////////////////////////////////////
/* DATASET CONSTRUCTION */
cd "/N/dc2/scratch/thdnguye/PlosOneBG" 

// Build intermediate files
do "$sourcedir/1.1.state_control_data.do"
// Combine files into a panel dataset
do "$sourcedir/1.2.create_BG_data.do"

////////////////////////////////////////////////////////////////////////
/* DATA ANALYSIS */
do "$sourcedir/2.1.analysis1-BGT_Medicaid_plots.do"
do "$sourcedir/2.2.analysis2-BGT_Medicaid_DDeventStudy.do"

/* DATA ANALYSIS: usinng NAIC4 filter - overpresented data  */
do "$sourcedir/3.1.create_BG_data_naics4.do"
do "$sourcedir/3.2.analysis2-BGT_Medicaid_DDeventStudy_naics4.do"

/* DATA ANALYSIS: usinng NAIC6 filter - exclude outlier  */
do "$sourcedir/4.1.create_BG_data_naics6_outlier.do"
do "$sourcedir/4.2.analysis2-BGT_Medicaid_DDeventStudy_naics6_outlier.do"



////////////////////////////////////////////////////////////////////////
/* PROVENANCE OF TABLES AND FIGURES IN PLOS ONE PAPER */

//Figures 1 and 2 are created MANUALLY in ... using ... 

//Figure 3 is created automatically in 2.1.analysis1-BGT_Medicaid_plots.do & 2.2.analysis2-BGT_Medicaid_DDeventStudy
	*Figures/figure_3_BG_Medicaid_SUDT.tif

//Figure 4 is created automatically in "$sourcedir/2.2.analysis2-BGT_Medicaid_DDeventStudy.do"
	*Figures/figure_4_BG_Medicaid_SUDT.tif

//Supplementary Table 1 is created automatically in  2.2.analysis2-BGT_Medicaid_DDeventStudy and exported to tex
	*We manually added in results of means (logged y) using the log file
	
//Supplementary Figures 1, 2 & 3 are created  in 2.1.analysis1-BGT_Medicaid_plots.do
	*Figures/figure_s1_Histogram_SUDPop.tif
	*Figures/figure_s2_BG_Medicaid_Healthcare.tif
	*Figures/figure_s3_BG_Medicaid_SUDT_Occupation.tif	


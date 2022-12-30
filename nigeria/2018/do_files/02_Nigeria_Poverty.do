******************************************************************************
*	Purpose: Obtain consumption aggregates and replicate poverty rates from WB
*	Author: Manuel Cardona
*   Last edit: Sep 26, 2021
******************************************************************************
set more off
clear all

global root "C:\Users\Manuel Cardona Arias\Box Sync\IPA_Programs_PPI\07 PPI Development\Nigeria\2018\03 Data\01 Raw\LSS\Household"
global clean "C:\Users\Manuel Cardona Arias\Box Sync\IPA_Programs_PPI\07 PPI Development\Nigeria\2018\03 Data\02 Clean"
global do "C:\Users\Manuel Cardona Arias\Box Sync\IPA_Programs_PPI\07 PPI Development\Nigeria\2018\04 Do Files"
global temp "C:\Users\Manuel Cardona Arias\Box Sync\IPA_Programs_PPI\07 PPI Development\Nigeria\2018\03 Data\03 Temp"

*Consumption Aggregates
use "$root/totcons.dta", clear
keep hhid hhsize wt_final popw reg_def totcons_pc totcons_adj zone sector

*Individual weights
gen ind_wgt=wt_final*hhsize
label var ind_wgt "Individual sampling weights"

	*Get CPI and PPP conversion factors
	gen cpi_factor_11=(267.512/110.84) //Survey year CPI divided by 2011 CPI found here https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=NG
	gen cpi_factor_05=(267.512/61.389) //Survey year CPI divided by 2005 CPI found here https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=NG
	gen ppp_factor_11=83.583 //2011 ppp conversion factors, found here (change country): https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=NG
	gen ppp_factor_05=53.32 //2005 ppp conversion factors, found here (change country): https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=NG
		label var cpi_factor_11 "Consumper Price Index 2016 / Consumer Price Index 2011"
		label var cpi_factor_05 "Consumper Price Index 2016 / Consumer Price Index 2005"
		label var ppp_factor_11 "2011 PPP Conversion Factor for Nigeria"
		label var ppp_factor_05 "2005 PPP Conversion Factor for Nigeria"

*National Poverty Lines
*NPL: 137,430 naira per year 
gen povline=137430
gen poor_npl1=(totcons_adj<povline)
sum poor_npl1 [w=ind_wgt] //This calculation uses sub national poverty lines.
						//WB estimate for this poverty line is 40.1%, very similar to what we got.
label var poor_npl1 "Annual consumption per capita is below the National Poverty Line"						
gen povline_150npl1=povline*1.5
label var povline_150npl1 "150% National Poverty Line"
gen poor_150npl1=(totcons_adj<povline_150npl1)
label var poor_150npl1 "Annual consumption per capita is below the 150% National Poverty Line"
gen povline_200npl1=povline*2
label var povline_200npl1 "200% National Poverty Line"
gen poor_200npl1=(totcons_adj<povline_200npl1)
label var poor_200npl1 "Annual consumption per capita is below the 200% National Poverty Line"

*International Poverty Lines 2011 - Lower-middle income countries
gen povline_2011_100 = 1.00*ppp_factor_11*cpi_factor_11 //1 USD a day
gen poor_2011_100 = ((totcons_adj/365) < povline_2011_100) //1 USD a day
gen povline_2011_190 = 1.90*ppp_factor_11*cpi_factor_11  // 1.90 USD a day
gen poor_2011_190 = ((totcons_adj/365) < povline_2011_190) // 1.90 USD a day
gen povline_2011_320 = 3.20*ppp_factor_11*cpi_factor_11 // 3.20 USD a day
gen poor_2011_320 = ((totcons_adj/365) < povline_2011_320) // 3.20 USD a day
gen povline_2011_550 = 5.50*ppp_factor_11*cpi_factor_11 // 5.50 USD a day
gen poor_2011_550 = ((totcons_adj/365) < povline_2011_550) // 5.50 USD a day
gen povline_2011_800 = 8.00*ppp_factor_11*cpi_factor_11 // 8 USD a day
gen poor_2011_800 = ((totcons_adj/365) < povline_2011_800) // 8 USD a day
gen povline_2011_1100 = 11.00*ppp_factor_11*cpi_factor_11 // 11 USD a day
gen poor_2011_1100 = ((totcons_adj/365) < povline_2011_1100) // 11 USD a day
gen povline_2011_1500 = 15.00*ppp_factor_11*cpi_factor_11 // 15 USD a day
gen poor_2011_1500 = ((totcons_adj/365) < povline_2011_1500) // 15 USD a day
gen povline_2011_2170 = 21.70*ppp_factor_11*cpi_factor_11 // 21.70 USD a day
gen poor_2011_2170 = ((totcons_adj/365) < povline_2011_2170) // 21.70 USD a day
		su poor_2011* [weight = ind_wgt] // These estimates almost match: https://data.worldbank.org/indicator/SI.POV.UMIC?locations=NG
label var poor_2011_100 "$1.00 a day (2011 PPP) poverty line: HH is below this line"
label var poor_2011_190 "$1.90 a day (2011 PPP) poverty line: HH is below this line"
label var poor_2011_320 "$3.20 a day (2011 PPP) poverty line: HH is below this line"
label var poor_2011_550 "$5.50 a day (2011 PPP) poverty line: HH is below this line"
label var poor_2011_800 "$8.00 a day (2011 PPP) poverty line: HH is below this line"
label var poor_2011_1100 "$11.00 a day (2011 PPP) poverty line: HH is below this line"
label var poor_2011_1500 "$15.00 a day (2011 PPP) poverty line: HH is below this line"
label var poor_2011_2170 "$21.70 a day (2011 PPP) poverty line: HH is below this line"

*International pvoerty lines (2005) - Lower-middle income countries 
gen povline_2005_125 = 1.25*ppp_factor_05*cpi_factor_05 // 1.25 USD a day
gen poor_2005_125 = ((totcons_adj/365) < povline_2005_125) // 1.25 USD a day
gen povline_2005_250 = 2.50*ppp_factor_05*cpi_factor_05 // 2.50 USD a day
gen poor_2005_250 = ((totcons_adj/365) < povline_2005_250) // 2.50 USD a day
gen povline_2005_500 = 5.00*ppp_factor_05*cpi_factor_05 // 5.00 USD a day
gen poor_2005_500 = ((totcons_adj/365) < povline_2005_500) // 5.00 USD a day
	su poor_2005* [weight = ind_wgt] //No benchmark to compare it to
label var poor_2005_125 "$1.25 a day (2005 PPP) poverty line: HH is below this line"
label var poor_2005_250 "$2.50 a day (2005 PPP) poverty line: HH is below this line"
label var poor_2005_500 "$5.00 a day (2005 PPP) poverty line: HH is below this line"

*Divide hh by consumption quintiles
xtile con_quint = totcons_adj [w=wt_final], nq(5) //Consumption quintiles
egen relative20 = min(totcons_adj) if con_quint==2 //Minimum consumption for 2nd quintile - Missings for all except 2nd quintile
egen povline_relative_20 = max(relative20) //Generate a variable = relative20 but for all observations
gen poor_bottom_20 = (totcons_adj<povline_relative_20) //Generate a dummy for the bottom quintile
egen relative40 = min(totcons_adj) if con_quint ==3 //Minimum consumption for 3rd quintile - Missings for all except 2nd quintile
egen povline_relative_40 = max(relative40) //Generate a variable = relative40 but for all observations
gen poor_bottom_40 = (totcons_adj < povline_relative_40) //Generate a dummy for the second quintile
egen relative60 = min(totcons_adj) if con_quint ==4 //Minimum consumption for 4th quintile - Missings for all except 2nd quintile
egen povline_relative_60 = max(relative60)  //Generate a variable = relative60 but for all observations
gen poor_bottom_60 = (totcons_adj < povline_relative_60) //Generate a dummy for the third quintile
egen relative80 = min(totcons_adj) if con_quint ==5 //Minimum consumption for 5th quintile - Missings for all except 2nd quintile
egen povline_relative_80 = max(relative80)  //Generate a variable = relative80 but for all observations
gen poor_bottom_80 = (totcons_adj < povline_relative_80) //Generate a dummy for the fourth quintile
	su poor_bottom* [weight = wt_final] //No benchmark to compare it to	
label var poor_bottom_20 "20th Percentile Poverty Line - Lowest 20% of the consumption distribution" 
label var poor_bottom_40 "40th Percentile Poverty Line - Lowest 40% of the consumption distribution" 
label var poor_bottom_60 "60th Percentile Poverty Line - Lowest 60% of the consumption distribution" 
label var poor_bottom_80 "80th Percentile Poverty Line - Lowest 80% of the consumption distribution" 

drop popw reg_def totcons_pc totcons_adj povline* con_quint relative*

* Urban indicator
gen urban=(sector==1)
label define urb 0 "Rural" 1 "Urban"
label values urban urb
label var urban "Urban"
drop sector

* Zone
label define zo	1 "North Central"	///
				2 "North East"		///
				3 "North West"		///
				4 "South East"		///
				5 "South South"		///
				6 "South West"
label values zone zo

save "$clean/NLSS_Nigeria_2019_poverty.dta", replace

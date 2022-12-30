********************************************************************
*	Purpose: Select relevant indicators to generate a PPI for Nigeria
*	Author: Manuel Cardona
********************************************************************
set more off
clear all

global root "/Users/manuelarias/Library/CloudStorage/Box-Box/IPA_Programs_PPI/07 PPI Development/Nigeria/2018/03 Data/01 Raw/LSS/Household"
global clean "/Users/manuelarias/Library/CloudStorage/Box-Box/IPA_Programs_PPI/07 PPI Development/Nigeria/2018/03 Data/02 Clean"
global do "/Users/manuelarias/Library/CloudStorage/Box-Box/IPA_Programs_PPI/07 PPI Development/Nigeria/2018/04 Do Files"
global temp "/Users/manuelarias/Library/CloudStorage/Box-Box/IPA_Programs_PPI/07 PPI Development/Nigeria/2018/03 Data/03 Temp"

* Household Roster
use "$root/sect1_roster.dta", clear
unique hhid // 116,320 individuals, from 22,123 households
keep hhid indiv s01q03 //Mainly to identify the head of household

* EDUCATION SECTION
merge 1:1 hhid indiv using "$root/sect2_education.dta"
drop _merge
keep hhid indiv s01q03 s02q04 s02q04b s02q05 s02q07

	*Variables at the household level
	
	* Household Size
	bysort hhid: gen hhsize=_N
	label var hhsize "Household Size"
	fre hhsize
	
	* Literacy status of the Head of the Household
	fre s02q04
	gen literacy=(s02q04==1 | s02q04b==1) if !mi(s02q04)
	
	* Has the Head of the Household ever attended school
	fre s02q05
	gen hhead_attend=(s02q05==1) if !mi(s02q05)
	
	* Highest educational level achieved
	fre s02q07, mis
	replace s02q07=0 if s02q07==. //Missing values are for individuals that never attended school
									//or are 3 years old or below.
	bysort hhid: egen hh_max_ed=max(s02q07)
	
* Keep only one observation per household (Household head)
fre s01q03, mis
keep if s01q03==1
keep hhid hhsize literacy hhead_attend s02q07 hh_max_ed
order hhid hhsize literacy hhead_attend s02q07 hh_max_ed

* Label variables
label define yesno 0 "No" 1 "Yes"
ren literacy hhead_literacy 
ren s02q07 hhead_max_ed 
label var hhead_literacy "Is the Head of HH able to read and write in English or any other local language"
label var hhead_attend "Has the Head of HH ever attended school?"
label var hhead_max_ed "Highest educational qualification by the Head of Household"
label var hh_max_ed "Highest educational qualification by anyone in the household"
label values hhead_literacy yesno
label values hhead_attend yesno


* LABOUR SECTION
merge 1:m hhid using "$root/sect4a1_labour.dta", keepusing(hhid indiv s04aq04 s04aq06 s04aq09)
drop _merge 

	* Does any member of the household work in [...]?
	fre s04aq04 s04aq06 s04aq09
	foreach job of varlist s04aq04 s04aq06 s04aq09 {
	 gen yes_`job'=(`job'==1)
	 bysort hhid: egen any_`job'=max(yes_`job')
	 drop yes_`job' `job'
	 label values any_`job' yesno
	}
	
	ren (any_s04aq04 any_s04aq06 any_s04aq09) (any_wage any_ownagri any_nfe)
	label var any_wage "In the past 7 days, did any HH member work in a wage job?"
	label var any_ownagri "In the past 7 days, did any HH member work in a own agriculture?"
	label var any_nfe "In the past 7 days, did any HH member work in own nonfarm enterprise?"
	
keep if indiv==1
drop indiv

save "$temp/Temp.dta", replace

* Food consumption
use "$root/sect6b_food_cons.dta", clear
keep hhid item_cd s06bq01
ren (s06bq01 item_cd) (consumed item)
recode consumed (2=0)
label values consumed yesno
save "$temp/temp_food.dta", replace
collapse (mean) consumed, by(item)
gen food=consumed
drop consumed
keep if food>=.1 & food<=.9
merge 1:m item using "$temp/temp_food.dta"
keep if _merge==3
drop food _merge
reshape wide consumed, i(hhid) j(item)
foreach var in consumed10-consumed153{
	recode `var' (2=0)
	label define yesno 0 "No" 1 "Yes"
	label values `var' yesno
	}
	label var consumed10 "Sorghum"
	label var consumed11 "Millet"
		ren consumed11 consumed011

	gen consumed13_14=(consumed13==1 | consumed14==1)
	label var consumed13_14 "Rice"
	drop consumed13 consumed14
	
	label var consumed16 "Maize flour"
	label var consumed17 "Yam flour"
	label var consumed18 "Cassava flour"

	gen consumed20_22=(consumed20==1 | consumed22==1)
	label var consumed20_22 "Maize"
	drop consumed20 consumed22
	
	label var consumed25 "Bread"
	label var consumed27 "Buns/Pofpof/Donuts"
	label var consumed28 "Biscuits"
	label var consumed30 "Cassava - roots"
	label var consumed31 "Yam - roots"
	
	gen consumed32_33=(consumed32==1 | consumed33==1)
	label var consumed32_33 "Gari (white or yellow)"
	drop consumed32 consumed33
	
	label var consumed34 "Cocoyam"
	label var consumed35 "Plantains"
	label var consumed36 "Sweet potatoes"
	
	gen consumed41_42=(consumed41==1 | consumed42==1)
	label var consumed41_42 "Beans (brown or white)"
	drop consumed41 consumed42

	gen consumed43_44=(consumed43==1 | consumed44==1)
	label var consumed43_44 "Groundnuts (Shelled or unshelled)"
	drop consumed43 consumed44
	
	label var consumed46 "Coconut"
	label var consumed47 "Kola nut"
	label var consumed52 "Groundnuts oil"
	label var consumed60 "Bananas"
	label var consumed61 "Orange/tangerine"
	label var consumed62 "Mangoes"
	label var consumed64 "Pineapples"
	label var consumed67 "Pawpaw"
	label var consumed68 "Watermelon"
	label var consumed70 "Tomatoes"
	label var consumed71 "Tomato puree"
	label var consumed73 "Garden eggs/egg plant"
	
	gen consumed74_75=(consumed74==1 | consumed75==1)
	label var consumed74_75 "Okra (fresh or dried)"
	drop consumed74 consumed75
	
	gen consumed76_77=(consumed76==1 | consumed77==1)
	label var consumed76_77 "Pepper (fresh or dried)"
	drop consumed76 consumed77
	
	label var consumed78 "Leaves (Cocoyam, Spinach, etc.)"
	label var consumed80 "Chicken"
	label var consumed83 "Eggs"
	label var consumed90 "Beef"
	label var consumed93 "Goat"
	
	gen consumed100_103=(consumed100==1 | consumed101==1 | consumed102==1 | consumed103==1)
	label var consumed100_103 "Fish (fresh, frozen, smoked, or dried)"
	drop consumed100-consumed103
	
	label var consumed105 "Seafood"
	label var consumed111 "Milk"
	label var consumed113 "Milk tinned"
	label var consumed121 "Chocolate drinks"
	label var consumed122 "Tea"
	label var consumed130 "Sugar"
	label var consumed142 "Unground Ugbono"
	label var consumed144 "Ground pepper"
	label var consumed145 "Melon"
	label var consumed147 "Mellon (ground)"
	
	drop consumed148

	label var consumed151 "Sachet water"
	label var consumed152 "Malt drinks"
	label var consumed153 "Soft drinks"
	
merge 1:1 hhid using "$temp/Temp.dta"
drop _merge
order hhid hhsize-hh_max_ed
save "$temp/Temp.dta", replace	


* Non-food expenditures (7-days recall period)
use "$root/sect07_7day.dta", clear

* Non-food expenditures (30-days recall period)
use "$root/sect07_30day.dta", clear
	keep hhid s07q03 item_cd
	ren (s07q03 item_cd) (purchased item)
	recode purchased (2=0)
	label values purchased yesno
	save "$temp/temp_purchases.dta", replace
	collapse (mean) purchased, by(item)
	gen goods=purchased
	drop purchased
	keep if goods>=.1 & goods<=.9
	merge 1:m item using "$temp/temp_purchases.dta"
	keep if _merge==3
	drop goods _merge
	reshape wide purchased, i(hhid) j(item)
	foreach var in purchased201-purchased236{
		recode `var' (2=0)
		label define yesno 0 "No" 1 "Yes"
		label values `var' yesno
		}
		label var purchased201 "Kerosene"
		label var purchased203 "Gas (for lishting/cooking)"
		label var purchased205 "Electricity vouchers"
		label var purchased207 "Firewood"
		label var purchased209 "Petrol"
		label var purchased212 "Lubricants (oil, grease, etc.)"
		label var purchased213 "Light bulbs/globes"
		label var purchased214 "Water"
			drop purchased214
		label var purchased216 "Toilet paper"
		label var purchased217 "Insecticides, disinfectant and cleaners"
			drop purchased217
		label var purchased219 "Personal care goods (razor blades, cosmetics)"
			drop purchased219
		label var purchased220 "Service of beauty salon"
		label var purchased221 "Service of barber"
			drop purchased220-purchased221
		label var purchased225 "Recharge cards"
			drop purchased225
		label var purchased234 "Batteries"
		label var purchased236 "Jewellery"
			drop purchased236
merge 1:1 hhid using "$temp/Temp.dta"
drop _merge
save "$temp/Temp.dta", replace

* Non-food expenditures (12-months recall period)
use "$root/sect07_12month.dta", clear
	keep hhid s07q05 item_cd
	ren (s07q05 item_cd) (spent item)
	recode spent (2=0)
	label values spent yesno
	save "$temp/temp_spent.dta", replace
	collapse (mean) spent, by(item)
	gen goods=spent
	drop spent
	keep if goods>=.1 & goods<=.9
	merge 1:m item using "$temp/temp_spent.dta"
	keep if _merge==3
	drop goods _merge
	reshape wide spent, i(hhid) j(item)
	foreach var in spent301-spent356{
		recode `var' (2=0)
		label define yesno 0 "No" 1 "Yes"
		label values `var' yesno
		}
		label var spent302 "Baby nappies"
		
		gen spent301_310=(spent301==1 | spent303==1 | spent304==1 | spent305==1 | spent306==1 | spent308==1 | spent310==1)
		label var spent301_310 "Clothes and dresses (infant, children and adult)"
		drop spent301 spent303-spent310
		
		label var spent313 "Repairs of clothing"
			drop spent313
		label var spent314 "Tailoring charges"
			drop spent314
		label var spent315 "Ankara"
		
		gen spent322_325=(spent322==1 | spent323==1 | spent324==1 | spent325==1)
		label var spent322_325 "Shoes, sandals, other footwear"
		drop spent322-spent325
		
		label var spent326 "Repair of footwear"
			drop spent326
		label var spent328 "Bowls, glassware, plates, silverware"
		label var spent329 "Cooking utensils"
		label var spent330 "Cleaning utensils"
		label var spent337 "Torch/flashlight"
		label var spent338 "Umbrella"
		label var spent343 "Bed sheets, bed cover, blankets"
		label var spent344 "Pilow"
		label var spent345 "Curtains and linnens"
		label var spent346 "Carpet and floor covering"
		label var spent350 "Cell phone hand set"
		label var spent354 "Donations to church"
			drop spent354
		label var spent355 "Health expenditures"
			drop spent355
		label var spent356 "Pharmaceutical products"
merge 1:1 hhid using "$temp/Temp.dta"
drop _merge
save "$temp/Temp.dta", replace

* Non-food expenditures (30-days recall period)
use "$root/sect07_30day.dta", clear
	keep hhid s07q03 item_cd
	ren (s07q03 item_cd) (buy item)
	recode buy (2=0)
	label values buy yesno
	save "$temp/temp_buy.dta", replace
	collapse (mean) buy, by(item)
	gen goods=buy
	drop buy
	keep if goods>=.1 & goods<=.9
	merge 1:m item using "$temp/temp_buy.dta"
	keep if _merge==3
	drop goods _merge
	reshape wide buy, i(hhid) j(item)
	foreach var in buy201-buy236{
		recode `var' (2=0)
		label define yesno 0 "No" 1 "Yes"
		label values `var' yesno
		}
		label var buy201 "Kerosene" 
		label var buy203 "Gas (for lighting/cooking)"
		label var buy205 "Electricity"
		label var buy207 "Firewood"
		label var buy209 "Petrol"
		label var buy212 "Lubricants (oil, grease, etc.)"
		label var buy213 "Light bulbs/globes"
		label var buy214 "Water"
			drop buy214 //Not enough documentation/definition
		label var buy216 "Toilet paper"
		label var buy217 "Insecticides, disinfectant and cleaners"
		label var buy219 "Personal care goods (razor blades, cosmetics)"
		label var buy220 "Service of beauty salon"
			drop buy220
		label var buy221 "Service of barber"
			drop buy221
		label var buy225 "Recharge cards"
		label var buy234 "Batteries (small radio type)"
		label var buy236 "Jewellery"
			drop buy236
	
merge 1:1 hhid using "$temp/Temp.dta"
drop _merge
order hhid hhsize-hh_max_ed consumed* purchased* spent* buy*
save "$temp/Temp.dta", replace

* Asset ownership
use "$root/sect10_assets.dta", clear
	keep hhid s10q01 asset_cd
	ren (s10q01 asset_cd) (asset item)
	recode asset (2=0)
	label values asset yesno
	save "$temp/temp_asset.dta", replace
	collapse (mean) asset, by(item)
	gen goods=asset
	drop asset
	keep if goods>=.1 & goods<=.9
	merge 1:m item using "$temp/temp_asset.dta"
	keep if _merge==3
	drop goods _merge
	reshape wide asset, i(hhid) j(item)
	foreach var in asset301-asset3322 {
		recode `var' (2=0)
		label define yesno 0 "No" 1 "Yes"
		label values `var' yesno
		}
		label var asset301 "3/4 piece sofa set" 
		label var asset302 "Chairs"
		label var asset303 "Table"
		label var asset305 "Bed"
		label var asset306 "Mat"
		label var asset311 "Stove (Kerosene)"
		label var asset312 "Fridge"
		label var asset318 "Motorbike"
		label var asset320 "Generator"
		label var asset321 "Fan"
		label var asset322 "Radio"
			drop asset322
		label var asset326 "Iron"
		label var asset327 "TV Set"
			drop asset327
		label var asset329 "DVD Player"
			drop asset329
		label var asset330 "Satellite Dish"
		label var asset3021 "Plastic chairs"
		label var asset3321 "Smart phones"
			drop asset3321
		label var asset3322 "Regular mobile phone"
			drop asset3322
merge 1:1 hhid using "$temp/Temp.dta"
drop _merge
order hhid hhsize-hh_max_ed consumed* purchased* spent* buy* asset*
save "$temp/Temp.dta", replace

* Housing
use "$root/sect14_housing.dta", clear
	keep hhid s14q09 s14q10 s14q11 s14q12 s14q13 s14q14 s14q27 s14q32 s14q40 s14q43 s14q44 s14q46
	
	*Main construction material of the outer walls
	fre s14q09
	ren s14q09 hh_walls
	
	*Main construction material of the roof
	fre s14q10
	ren s14q10 hh_roof
	
	*Main construction  material of the floor
	fre s14q11
	ren s14q11 hh_floor
	
	* How many separate rooms does the HH occupy and use for sleeping
	fre s14q12
	ren s14q12 hh_roomssleep
	
	* What type of cookstove is your household's primary cookstove
	fre s14q13
	ren s14q13 hh_cookstove
	
	* Where did you normally cook with the cookstove?
	fre s14q14
	ren s14q14 hh_cookplace
	replace hh_cookplace=9 if hh_cookplace==. //Nobody in the HH cooks
	
	* Main source of drinking water during the [rainy/dry] season
	fre s14q27
	ren s14q27 hh_drinkrainy
	
	fre s14q32 
	replace s14q32=hh_drinkrainy if s14q32==. //Same as in the rainy season
	ren s14q32 hh_drinkdry
	
	* Type of toilet facility the HH uses
	fre s14q40
	ren s14q40 hh_toilet
	
	* Where is the toilet facility located?
	fre s14q43
	ren s14q43 hh_toiletplace
	
	* Is the toilet shared with others who are not members of the HH?
	fre s14q44
	ren s14q44 hh_toiletshared
	
	* What kind of refuse collection is used by the HH?
	fre s14q46
	ren s14q46 hh_refuse
	
merge 1:1 hhid using "$temp/Temp.dta"
drop _merge
order hhid hhsize-hh_max_ed consumed* purchased* spent* buy* asset* hh_walls-hh_refuse
save "$temp/Temp.dta", replace

* Agriculture
use "$root/sect4a1_labour.dta", clear
	keep hhid indiv s04aq06
        sort hhid indiv
    
    	* Anybody in the household works in agriculture
    	replace s04aq06=0 if s04aq06==2
    	bysort hhid: gen a_work=sum(s04aq06)
    	bysort hhid: egen ag_work=max(a_work)
    	label var ag_work "At least one member of the HH works in agriculture"
    	label define a_w 0 "No HH member works in agriculture" 1 "At least one member of the HH works in agriculture"
    	label values ag_work a_w
    	replace ag_work=1 if ag_work>=1
    	drop a_work s04aq06 indiv
    	bysort hhid: keep if _n==1
    	
        * Merge with proxy data
        merge 1:m hhid using "$root/sect19a_land.dta", keepusing (hhid s19q00)
        drop if _merge!=3
        drop _merge 
        sort hhid
    
    	* Does the HH own or holds use rights for any parcel of land?
    	fre s19q00
    	gen ag_hold_plot=(s19q00==1)
    	label var ag_hold_plot "The HH own or holds use rights for any parcel of land"
    	label define h_plot 0 "The HH does NOT own/holds rights for any land" 1 "The HH owns/hols rights for any land"
    	label values ag_hold_plot h_plot
    	drop s19q00
    	
        * Merge with proxy data
        merge 1:1 hhid using "$root/sect18_agriculture.dta", keepusing(hhid s18q01 s18q02 s18q09 s18q10f s18q10g s18q11 s18q12 s18q13 s18q20)
        keep if _merge==3
        drop _merge
        sort hhid
    
    		* The HH has access or owns land used for crop cultivation
    		fre s18q01
    		gen ag_own_land=(s18q01==1) if !mi(s18q01)
    		label var ag_own_land "The HH owns or has access to land used for crop cultivation"
    		label define o_l 0 "HH does not own land used for crop cultivation" 1 "HH owns land used for crop cultivation"
    		label values ag_own_land o_l
    		
    		* The HH cultivated any crops in the current season
    		fre s18q02
    		gen ag_cult_crops=(s18q02==1) if !mi(s18q02)
    		label var ag_cult_crops "The HH cultivated any crops in the current season"
    		label define c_c 0 "The HH did not cultivate any crops" 1 "The HH cultivated crops"
    		label values ag_cult_crops c_c
    
    		
    		* Did your household hire any person to work on any plot?
    		fre s18q09
    		gen ag_hire_plot=(s18q09==1) if !mi(s18q09)
    		label var ag_hire_plot "The HH hired any person to work on any plot"
    		label define h_p 0 "The HH did NOT hire any person" 1 "The HH hired at least 1 person"
    		label values ag_hire_plot h_p
    		
    		* Did the HH úse any tractor?
    		fre s18q10f
    		gen ag_use_tractor=(s18q10f==1) if !mi(s18q10f)
    		label var ag_use_tractor "The HH used a tractor in any plot"
    		label define u_t 0 "The HH did NOT use a tractor" 1 "The HH used a tractor"
    		label values ag_use_tractor u_t
    		
    		* Did the HH use any plough?
    		fre s18q10g
    		gen ag_use_plough=(s18q10g==1) if !mi(s18q10g)
    		label var ag_use_plough "The HH used a plough in any plot"
    		label define u_p 0 "The HH did NOT use a plough" 1 "The HH used a plough"
    		label values ag_use_plough u_p
    		
    		* Was crop production the main activity of your HH in the current year?
    		fre s18q11
    		gen ag_crop_prod=(s18q11==1) if !mi(s18q11)
    		label var ag_crop_prod "Crop production was the main activity of the HH"
    		label define c_p 0 "Crop production was NOT the main activity of the HH" 1 "Crop production was the main activity of the HH"
    		label values ag_crop_prod c_p
    		
    		* Was crop production the main source of income of the HH in the current year?
    		fre s18q12
    		gen ag_crop_income=(s18q11==1) 
    		label var ag_crop_income "Crop production was the main source of income of the HH"
    		label define c_i 0 "Crop production was NOT the main source of income" 1 "Crop production was the main source of income"
    		label values ag_crop_income c_i
    		
    		* The HH owned any ag_livestock in the past 12 months
    		fre s18q13
    		gen ag_livestock=(s18q13==1) 
    		label var ag_livestock "HH owned any ag_livestock in the past 12 months"
    		label define liv 0 "HH did not own any ag_livestock" 1 "HH owned any ag_livestock"
    		label values ag_livestock liv
    		
    		* The HH cultivated any crops in the current season
    		gen ag_cult_livestock=ag_cult_crops
                    replace ag_cult_livestock=1 if ag_livestock==1
    		label var ag_cult_livestock "HH cultivated crops or owned livestock"
    		label define c_c 0 "No" 1 "Yes", replace
    		label values ag_cult_livestock c_c

keep hhid ag_*
merge 1:1 hhid using "$temp/Temp.dta"
keep if _merge==3
drop _merge
order hhid hhsize-hh_max_ed consumed* purchased* spent* buy* asset* hh_walls-hh_refuse ag_*
save "$temp/Temp.dta", replace

* Water and power
    use "$root/sect14_housing.dta", clear
    keep hhid s14q19 s14q20__1 s14q20__2 s14q20__3 s14q20__4 s14q20__5 s14q20__6 s14q20__7 s14q20__8 s14q20_os s14q21 s14q27 s14q27_os s14q29
    unique hhid //Information for 22,121 different households

    * Does the HH have access to grid electricity?
	gen po_grid=(s14q20__1==1 | s14q20__2==1)
	label var po_grid "HH has access to grid electricity"
	label define yesno 0 "No" 1 "Yes"
	label values po_grid yesno
	
	* Does the HH have access to grid electricity and its their main source for lighting?
	replace s14q21=1 if s14q21==. & s14q20__1==1 & s14q20__2==2 & s14q20__3==2 & s14q20__4==2 & s14q20__5==2 & s14q20__6==2 & s14q20__7==2 & s14q20__8==2 
	replace s14q21=2 if s14q21==. & s14q20__1==2 & s14q20__2==1 & s14q20__3==2 & s14q20__4==2 & s14q20__5==2 & s14q20__6==2 & s14q20__7==2 & s14q20__8==2 
	replace s14q21=3 if s14q21==. & s14q20__1==2 & s14q20__2==2 & s14q20__3==1 & s14q20__4==2 & s14q20__5==2 & s14q20__6==2 & s14q20__7==2 & s14q20__8==2 
	replace s14q21=4 if s14q21==. & s14q20__1==2 & s14q20__2==2 & s14q20__3==2 & s14q20__4==1 & s14q20__5==2 & s14q20__6==2 & s14q20__7==2 & s14q20__8==2 
	replace s14q21=5 if s14q21==. & s14q20__1==2 & s14q20__2==2 & s14q20__3==2 & s14q20__4==2 & s14q20__5==1 & s14q20__6==2 & s14q20__7==2 & s14q20__8==2 
	replace s14q21=6 if s14q21==. & s14q20__1==2 & s14q20__2==2 & s14q20__3==2 & s14q20__4==2 & s14q20__5==2 & s14q20__6==1 & s14q20__7==2 & s14q20__8==2 
	replace s14q21=7 if s14q21==. & s14q20__1==2 & s14q20__2==2 & s14q20__3==2 & s14q20__4==2 & s14q20__5==2 & s14q20__6==2 & s14q20__7==1 & s14q20__8==2 
	replace s14q21=8 if s14q21==. & s14q20__1==2 & s14q20__2==2 & s14q20__3==2 & s14q20__4==2 & s14q20__5==2 & s14q20__6==2 & s14q20__7==2 & s14q20__8==1

	gen po_elect=.
	replace po_elect=0 if s14q19==2
	replace po_elect=1 if s14q19==1 & s14q21<=2
	replace po_elect=2 if s14q19==1 & s14q21>2 & s14q21!=.
	label define po_el 0 "No electricity in the HH" 1 "Grid electricity is the main source of electricity" 2 "Other type is the main source of electricity"
	label values po_elect po_el
	label var po_elect "Is grid electricity the main source of the HH?"
	
*************************
*** Sub-sector: Water ***
*************************

	* Does the HH have a direct connection to potable water?
	gen wa_piped=.
	replace wa_piped=1 if s14q27<=2
	replace wa_piped=2 if s14q27==3 | s14q27==4
	replace wa_piped=0 if wa_piped==.
	label define w_p 0 "No, other source" 1 "Yes, piped water into dwelling or yard/plot" 2 "Yes, piped water to public space"
	label values wa_piped w_p
	label var wa_piped "The´HH uses piped water as their main source for drinking"

keep hhid po_grid po_elect wa_piped
merge 1:1 hhid using "$temp/Temp.dta"
keep if _merge==3
drop _merge
order hhid hhsize-hh_max_ed consumed* purchased* spent* buy* asset* hh_walls-hh_refuse ag_* po_grid po_elect wa_piped
save "$temp/Temp.dta", replace
save "$clean/LSS_2018_Nigeria.dta", replace


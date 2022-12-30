********************************************************************
*	Purpose: Create dummy variables for Nigeria PPI                *
*	Author: Manuel Cardona                                         *
*   Created: November 1st, 2021									   *
*   STATA 15.1													   *
********************************************************************

set more off
clear all

global dta "/Users/manuelarias/Library/CloudStorage/Box-Box/IPA_Programs_PPI/07 PPI Development/Nigeria/2018/03 Data/01 Raw/LSS/Household"
global clean "/Users/manuelarias/Library/CloudStorage/Box-Box/IPA_Programs_PPI/07 PPI Development/Nigeria/2018/03 Data/02 Clean"

*Personal global (may change the path)
global path "/Users/manuelarias/Library/CloudStorage/Box-Box/IPA_Programs_PPI/07 PPI Development/Nigeria/2018"
	*No need to change
	global root "$path/03 Data/01 Raw/LSS/Household"
	global clean "$path/03 Data/02 Clean"
	global fig "$path/05 Figures"

*************To customize:*****************
///////////////////////////////////////////
global odb "LSS_2018_Nigeria.dta"
global masterdb "MASTER_LSS18_Nigeria.dta"
global ppidb "PPI_Nigeria_2018.dta"
global codebook "Codebook_Nigeria_2018.xls"
global qkey "Nigeria18_QuestionKEY.csv"
///////////////////////////////////////////

******************************************
******************************************
************PPI - Indicators**************
******************************************
******************************************
u "$clean/$odb", clear

***************************************
***  Merge with poverty indicators  ***
***************************************
merge 1:1 hhid using "$clean/NLSS_Nigeria_2019_poverty.dta"
keep if _merge==3
drop _merge
drop cpi* ppp*
order hhid wt_final ind_wgt urban poor_* zone hhsize

	* Subnational indicator
	tab zone, sum(poor_npl1)
	
* Household size
tab hhsize, sum(poor_npl1)
gen hhsize_c=hhsize
replace hhsize=1 if hhsize_c<=3
replace hhsize=2 if hhsize_c>3 & hhsize_c<=6
replace hhsize=3 if hhsize_c>6
label define sizes 1 "3 or less" 2 "4-6" 3 "More than 6"
label values hhsize sizes
drop hhsize_c

	* Literacy status of the head of the HH
	tab hhead_literacy, sum(poor_npl1)
	
* Has the head of the HH ever attended school?
tab hhead_attend, sum(poor_npl1)

	*Highest educational level complted by the head of the hh
	tab hhead_max_ed, sum(poor_npl1)
	gen hhead_max_c=hhead_max_ed
	replace hhead_max_ed=0 if hhead_max_c<=3
	replace hhead_max_ed=1 if hhead_max_c>3 & hhead_max_c<=26
	replace hhead_max_ed=2 if hhead_max_c>26 & hhead_max_c!=51 & hhead_max_c!=52
	replace hhead_max_ed=3 if hhead_max_c==51 | hhead_max_c==52
	label define edu	0 "None, Nursery, Pre-nursery"							///
						1 "Primary, Junior secondary, Senior secondary"			///
						2 "Some higher level"									///
						3 "Quaranic/Integrated quaranic"
	label values hhead_max_ed edu
	drop hhead_max_c
	
*Highest educational level completed by anyone in the HH
	tab hh_max_ed, sum(poor_npl1)
	gen hh_max_c=hh_max_ed
	replace hh_max_ed=0 if hh_max_c<=3
	replace hh_max_ed=1 if hh_max_c>3 & hh_max_c<=26
	replace hh_max_ed=2 if hh_max_c>26 & hh_max_c!=51 & hh_max_c!=52
	replace hh_max_ed=3 if hh_max_c==51 | hh_max_c==52
	label values hh_max_ed edu
	drop hh_max_c
	
* Main construction material of the HH walls
tab hh_walls, sum(poor_npl1)
gen hh_walls_c=hh_walls
replace hh_walls=0 if hh_walls_c<=4 | hh_walls_c==6 | hh_walls_c==9
replace hh_walls=1 if hh_walls_c==5 | hh_walls_c==7 | hh_walls_c==8
label define wall	0 "Mud, Stone, Unburnt bricks, Burnt bricks, Wood or bamboo, Other" ///
					1 "Cement or concrete, Iron sheets, Cardboard"
label values hh_walls wall
drop hh_walls_c

	*Main construction material of the HH roof
	tab hh_roof, sum(poor_npl1)
	gen hh_roof_c=hh_roof
	replace hh_roof=0 if inlist(hh_roof_c, 1, 3, 7)
	replace hh_roof=1 if inlist(hh_roof_c, 2, 4, 5, 10, 11)
	replace hh_roof=2 if inlist(hh_roof_c, 6, 8, 9)
	label define roof	0 "Thatch, Clay tiles, Mud"														///
						1 "Corrugated iron sheets, Concrete/Cement, Plastic sheet, Zinc sheet, Other"	///
						2 "Asbestos sheet, Long/short span sheets, Step tiles"
	label values hh_roof roof
	drop hh_roof_c
	
* Main construction material of the HH floor
tab hh_floor, sum(poor_npl1)
gen hh_floor_c=hh_floor
replace hh_floor=0 if 	inlist(hh_floor_c, 1, 2)
replace hh_floor=1 if 	inlist(hh_floor_c, 3, 4, 8)
replace hh_floor=2 if 	inlist(hh_floor_c, 5, 6, 7)
label define floor	0 "Sand/Dirt/Straw, Smoothed mud"		///
					1 "Smooth cement/concrete, Wood, Other"	///
					2 "Tile, Terazo, Marble"
label values hh_floor floor
drop hh_floor_c

	* Number of rooms used for sleeping
	tab hh_roomssleep, sum(poor_npl1)
	drop hh_rooms
	
* Type of cookstove
tab hh_cookstove, sum(poor_npl1)
gen hh_cookstove_c=hh_cookstove
replace hh_cookstove=0 if hh_cookstove_c==1
replace hh_cookstove=1 if hh_cookstove_c!=1
label define stove 0 "3-stone/Open fire" 1 "Other type/No oner in the HH cooks"
label values hh_cookstove stove
drop hh_cookstove_c
drop hh_cookplace
	
	* Main source of drinking water during the rainy season
	tab hh_drinkrainy, sum(poor_npl1)
	gen hh_drinkrainy_c=hh_drinkrainy
	replace hh_drinkrainy=0 if inlist(hh_drinkrainy_c, 4, 7, 9, 13)
	replace hh_drinkrainy=1 if inlist(hh_drinkrainy_c, 2, 3, 5, 6, 8, 10, 11, 12, 16, 17)
	replace hh_drinkrainy=2 if inlist(hh_drinkrainy_c, 1, 14, 15)
	label define rainy	0 "Public tap/standpipe, Unprotected dug well, Unprotected spring, Surface water"	///
						1 "Piped into yard/plot, Piped to neighbor, Tube well/borehole, Protected dug well, Protected spring, Rain water collection, Tanker truk, small tank/drum, Water kiosk, Other"	///
						2 "Piped into dwelling, Bottled water, Sachet water"
	label values hh_drinkrainy rainy
	drop hh_drinkrainy_c
	
* Main source of drinking water during the dry season
tab hh_drinkdry, sum(poor_npl1)
drop hh_drinkdry

	* Type of toilet
	tab hh_toilet, sum(poor_npl1)
	gen hh_toilet_c=hh_toilet
	replace hh_toilet=0 if inlist(hh_toilet_c, 7, 8, 9, 12, 13)
	replace hh_toilet=1 if inlist(hh_toilet_c, 3, 4, 5, 6, 10, 11)
	replace hh_toilet=2 if inlist(hh_toilet_c, 1, 2)
	label define toilet	0 "Pit latrine with slab, Pit latrine without slab, Composting toilet, No facilities, Bush, Field, Other"			///
						1 "Flush to pit latrine, Flush to open drain, Flush to somewhere else, VIP, Hanging toilet/Hanging latrine, Bucket"	///
						2 "Flush to piped sewage system, Fliush to septic tank"
	label values hh_toilet toilet
	drop hh_toilet_c
	
* Toilet place
tab hh_toiletplace, sum(poor_npl1)
drop hh_toiletplace //Not enough variance

	*Toilet shared
	tab hh_toiletshared, sum(poor_npl1)
	recode hh_toiletshared (2=0)
	label values hh_toiletshared yesno
	drop hh_toiletshared //People sharing have lower poverty rate
	
* Kind of refuse collection system
tab hh_refuse, sum(poor_npl1)
gen hh_refuse_c=hh_refuse
replace hh_refuse=0 if inlist(hh_refuse_c, 4, 5, 8)
replace hh_refuse=1 if inlist(hh_refuse_c, 1, 2, 3, 6, 7)
label define ref	0 "Disposal without compound, Unauthorized refuse heap, Disposal in the bush"	///
					1 "HH bin collected by the gov/private firm, Govt bin or shed, Disposal in a river/stream, Other"
label values hh_refuse ref
drop hh_refuse_c

	* Agricultural questions
	drop ag_cult_crops ag_hire_plot ag_use_tractor ag_use_plough ag_crop_prod ag_crop_income ag_cult_livestock
	drop asset3021
	
	foreach asset of varlist asset303 asset305 asset306 asset311 asset312 asset318 asset320 asset321 asset326 asset330 {
		replace `asset'=0 if `asset'==.a
	}
	

*Urban/Rural
//keep if urban==1
drop buy*

save "$clean/$masterdb", replace

		************************************************
		************************************************
		*************Arrange for custom PPI*************	After changing the globals: this code should run without any further changes
		************************************************
		************************************************
		u "$clean/$masterdb", clear
		set more off
		
		*************To customize:*****************
		///////////////////////////////////////////
		global vlist "zone hhsize hhead_literacy hhead_attend hhead_max_ed hh_max_ed consumed10 consumed011 consumed16 consumed17 consumed18 consumed25 consumed27 consumed28 consumed30 consumed31 consumed34 consumed35 consumed36 consumed46 consumed47 consumed52 consumed60 consumed61 consumed62 consumed64 consumed67 consumed68 consumed70 consumed71 consumed73 consumed78 consumed80 consumed83 consumed90 consumed93 consumed105 consumed111 consumed113 consumed121 consumed122 consumed130 consumed142 consumed144 consumed145 consumed147 consumed151 consumed152 consumed153 consumed13_14 consumed20_22 consumed32_33 consumed41_42 consumed43_44 consumed74_75 consumed76_77 consumed100_103 purchased201 purchased203 purchased205 purchased207 purchased209 purchased212 purchased213 purchased216 purchased234 spent302 spent315 spent328 spent329 spent330 spent337 spent338 spent343 spent344 spent345 spent346 spent350 spent356 spent301_310 spent322_325 asset301 asset302 asset303 asset305 asset306 asset311 asset312 asset318 asset320 asset321 asset326 asset330 hh_walls hh_roof hh_floor hh_cookstove hh_drinkrainy hh_toilet hh_refuse ag_work ag_hold_plot ag_own_land ag_livestock po_grid po_elect wa_piped any_wage any_ownagri any_nfe"
		*global vlist "zone hhsize hhead_literacy hhead_attend hhead_max_ed hh_max_ed asset301 asset302 asset303 asset305 asset306 asset311 asset312 asset318 asset320 asset321 asset326 asset330 hh_walls hh_roof hh_floor hh_cookstove hh_drinkrainy hh_toilet hh_refuse ag_work ag_hold_plot ag_own_land ag_livestock po_grid po_elect wa_piped" 
		global poor poor_npl1 //Change only if we don't want to train our model with the National Poverty Line
		global advars "hhid wt_final urban poor_npl1 poor_150npl1 poor_200npl1 poor_2011_100 poor_2011_190 poor_2011_320 poor_2011_550 poor_2011_800 poor_2011_1100 poor_2011_1500 poor_2011_2170 poor_2005_125 poor_2005_250 poor_2005_500 poor_bottom_20 poor_bottom_40 poor_bottom_60 poor_bottom_80" //All variables that are useful in the DB, but we don't want in the CSV key file
		global tobe_dropped "ind_wgt"
		///////////////////////////////////////////
		
			local to_drop = " "
			local count = 1
			gen name = ""
			gen orig_name = ""
			gen label = ""
			gen value = ""
			
		*We plug in all the variables we want to dummify: it creates dummies for each category and drops the one with the highest poverty rate.
		foreach var of varlist $vlist{
			bysort `var': egen mean = mean($poor)  // Poverty rate by category of the variable
			quietly levelsof `var', local(levels)      // Captures all the levels/categories for each variable
			foreach i of local levels {				   // Loop through all the levels
				gen `var'`i'= (`var'==`i')			   // Generates a dummy variable for each level
					*Keep variable names, labels and values for them to be used later
					while (name[`count']!=""){			//Everytime a new variable is looped over the DB re-sorts itself, bc of this we need to make sure that the obs in name that we will replace with the variable name/label/value is in blank. If not, we change the obs.
						local count = `count' + 1		//If the observation that we will replace has a value already, we will change the local so we replace it in an additional obs
						display "While loop replaced count with `count'"
					}
					quietly: replace name = "`var'`i'" in `count' //Var name in observation #`count' is replaced with the variable name
					local x : variable label `var' //Variable label is stored
					quietly: replace label = "`x'" in `count' //Var label in observation #`count' is replaced with the variable label
					quietly: replace value = "`i'" in `count' //Var value in observation #`count' is replaced with the value of that category
					quietly: replace orig_name ="`var'" in `count' //Var orig_name in observation #`count' is replaced with the name of the original variable that created this one
				quietly: su mean					   // Summary stats for the poverty rate of each category variable
				global max `: di %4.3f r(max)'         // Keep in a global (max) the maximum poverty rate for a particular category/level
				quietly su $poor if `var'==`i'     // Summarize the poverty rate for this category/level
				global max2 `: di %4.3f r(mean)'	   // Store the mean poverty rate from this category/level
				if $max == $max2 {					   // If the poverty rate from this category (max2) is the same as the highest poverty rate for any category (max), the code goes ahead and drops that category
					display "Will drop `var'`i'"		   // It displays the category that was dropped
					local to_drop = ("`var'`i'" + " " + "`to_drop'")
				 }
				 local count = `count' + 1
			}
			drop mean `var'                            // Drops variable mean (will be used next time the loop begins) and the original variable that was split into different categories
		}
		drop `to_drop' //Drops all variables that had the highest poverty rates
		display "Variables dropped: `to_drop'" //Lists all the variables that were dropped
		
		*******Create a list of names with labels and values; export it to another DB*******
		preserve
		drop if name==""
		sort name value
		keep name orig_name label value
		save "$clean\PPI_labels.dta",  replace //Save the variable names with it's labels
		restore
		drop name label value orig_name
		
		*******Order DB*******
		order $advars
		drop $tobe_dropped //Drop questions that will not be used by the algorithm: usually MPI, WB, HDDS, WI, among others.
		
		********Drop all variables with low prevalence*******
 		*foreach v of var item* asset* food* { //For all items, food or assets
		*	quietly: su `v' //Summarize 
		*	if (r(mean)<0.1)  { //Drop if less than 10% of hh have them
		*		drop `v' //Drop
		*		display "Dropped `v'" 	//Display dropped
		*	}		
		*}
		
		*******Drop all missing values*******
		*mdesc         //Check for missing values in each variable
 		foreach v of var * { 
			drop if missing(`v') //Drop all observations that have any missing values 
		}
		
saveold "$clean/$ppidb", replace version(12)

				************************************************
				************************************************
				*******Arrange for question key CSV file******** After changing the globals: this code should run without any further changes
				************************************************
				************************************************
				u "$clean/$ppidb", clear
				
				*************To customize:*****************
				///////////////////////////////////////////
				global obs_start = 22 //This is the observation where questions that were split into different categories begin
				global obs_na = 21 //Observations such as poverty rates, weights and urban/rural are not supposed to be included. 
								  //This sets the number of obs that should be dropped before the we output the qkey file
				global minus = 1 //This shouldn't be changed unless one var has more than 10 categories. If this is true, change it to 3.
				///////////////////////////////////////////
					
				*Generate CSV file that numbers every variable and groups the dummies by original variable (all region dummies will be assigned the same number)
					gen varname = ""
					local i = 1  									//Local that equals 1
				foreach var of varlist * {						//Loop that goes through all variables		
					replace varname = "`var'" in `i'			//For observation "i", replace with the name of each variable on the list
					local i = `i' + 1							//Change the local by adding 1: therefore, we will replace next variable name in the following observation
				}
				drop in 1/$obs_na 
				replace varname = "" if varname == "varname"	//Since varname is a variable, we delete it
				
				*Generate another variable that takes away last two characters of our variable names
				generate varname2=substr(varname,1, strlen(varname)-$minus) //Make sure to change the numbers in each case
				replace varname2= varname if varname2=="" //Remove obs with varname
				drop if varname=="" //Keep only the number of obs = to number of variables
				gen a = 1 if varname2!=varname2[_n-1]  //We tag obs if past varname is not the same as the new one
				gen unique_var_number = _n if a==1 //We make a count variable for each case in which we have a variable genre for the first time
				replace unique_var_number = unique_var_number[_n-1] if unique_var_number==. //Replace all missings with a number that is the same for each var genre
				
				*Unique_var_name has some jumps (e.g. from 60 to 69). We don't want this to happen. So we wil fix it (e.g. so after 60 goes 61).
				local i = 1
				levelsof unique_var_number, local(levels)  //Store all the levels of unique_var_number   
				foreach lev of local levels {			//Loop through all those levels	   
					replace unique_var_number = `i' if unique_var_number == `lev'  //Replace each level with the local i; which will go continuously 1 by 1. 
					local i = `i' + 1	//We add 1 every time we are finished with one level
				 }
				
				rename (unique_var_number varname) (unique_q_number variable_name)
				keep  variable_name unique_q_number
				order unique_q_number
				export delimited using "$clean/$qkey",  replace

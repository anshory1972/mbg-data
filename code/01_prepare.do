*==============================================================================
* 01_prepare.do
*
* Builds one person-level file with everything the MBG tables need:
* who belongs to each MBG target group, the breakdown variables, and the
* answers to the MBG module (Blok XI) as simple 0/1 or numeric variables.
*
* Reads : $DATA/ssn202509_mod_ind.dta    (persons, Susenas September 2025)
*         $DATA/ssn202509_kp_blok43.dta  (household expenditure per capita)
* Writes: work/mbg_module.dta
*
* Run it from 00_run_all.do, which sets $DATA.
*==============================================================================

version 19
clear all
set more off
capture log close
log using "log/01_prepare.log", replace text


*------------------------------------------------------------------------------
* 1. Read the persons file: survey design, breakdowns and Blok XI
*------------------------------------------------------------------------------

use URUT PSU STRATA FWT M101 M105 M405 M407 M504 ///
    M1101-M1113B using "$DATA/ssn202509_mod_ind.dta", clear


*------------------------------------------------------------------------------
* 2. Expenditure quintile
*    Persons are ranked by household expenditure per capita (KAPITA, all
*    spending, as BPS uses for poverty), weighted by the person weight.
*    The cut points are national: quintile 1 is the poorest 20 per cent of
*    all people in Indonesia.
*------------------------------------------------------------------------------

merge m:1 URUT using "$DATA/ssn202509_kp_blok43.dta", ///
    keepusing(KAPITA) assert(match) nogenerate

xtile quintile = KAPITA [pweight = FWT], nquantiles(5)
label define quintile 1 "Q1 (poorest 20%)" 2 "Q2" 3 "Q3" 4 "Q4" ///
                      5 "Q5 (richest 20%)"
label values quintile quintile
label variable quintile "Expenditure quintile"


*------------------------------------------------------------------------------
* 3. Breakdown variables
*------------------------------------------------------------------------------

* urban or rural (always the column of every table)
generate byte urban = (M105 == 1)
label define urban 1 "Urban" 0 "Rural"
label values urban urban

label variable urban "Area"

* province, with the province names from the BPS file
generate int province = M101
local names : value label M101
label values province `names'
label variable province "Province"

* sex
generate byte sex = M405
label define sex 1 "Male" 2 "Female"
label values sex sex
label variable sex "Sex"

* school level, from the level the child is attending (M504)
generate byte level = .
replace level = 1 if inrange(M504, 1, 5)     // primary: Paket A, SDLB, SD, MI, PDF Ula
replace level = 2 if inrange(M504, 6, 10)    // junior secondary: Paket B, SMPLB, SMP, MTs, PDF Wustha
replace level = 3 if inrange(M504, 11, 17)   // senior secondary: Paket C, SMLB, SMA, MA, SMK, MAK, PDF Ulya
label define level 1 "Primary" 2 "Junior secondary" 3 "Senior secondary"
label values level level
label variable level "School level"

* a constant, so every table also has a row for the whole country
generate byte all = 1
label define all 1 "Indonesia"
label values all all


*------------------------------------------------------------------------------
* 4. Target groups (questions 1101-1105) and the populations of the tables
*    MBG covers school children from primary to senior secondary. The survey
*    marks every enrolled person as a school child (1104), including
*    university students, so the school group keeps levels 1-3 only.
*------------------------------------------------------------------------------

generate byte pop_school   = (M1104 == 1 & !missing(level))
generate byte pop_under5   = (M1105 == 1)
generate byte pop_pregnant = (M1102 == 1)
generate byte pop_breastf  = (M1103 == 1)

* received MBG in the last week (1106: 1 yes, 5 no)
generate byte received = .
replace received = 1 if M1106 == 1
replace received = 0 if M1106 == 5
label variable received "Received MBG in the last week"

* B3: pregnant women, breastfeeding mothers and children under five together
generate byte pop_b3      = (pop_pregnant | pop_breastf | pop_under5)
* all target groups: school children and B3
generate byte pop_targets = (pop_school | pop_b3)

* recipients, for the tables about the meals
generate byte rec_school = (pop_school == 1 & received == 1)
generate byte rec_all    = (received == 1)

* MBG receipt as a breakdown (columns of the comparison tables)
generate byte mbg = received
label define mbg 1 "Recipients" 0 "Non-recipients"
label values mbg mbg
label variable mbg "MBG receipt"


*------------------------------------------------------------------------------
* 5. Answers of recipients, as 0/1 variables (one per answer category)
*------------------------------------------------------------------------------

* 1107: month in 2025 when the person first received MBG
generate byte m01 = (M1107 == 1) if !missing(M1107)
generate byte m02 = (M1107 == 2) if !missing(M1107)
generate byte m03 = (M1107 == 3) if !missing(M1107)
generate byte m04 = (M1107 == 4) if !missing(M1107)
generate byte m05 = (M1107 == 5) if !missing(M1107)
generate byte m06 = (M1107 == 6) if !missing(M1107)
generate byte m07 = (M1107 == 7) if !missing(M1107)
generate byte m08 = (M1107 == 8) if !missing(M1107)
generate byte m09 = (M1107 == 9) if !missing(M1107)
label variable m01 "Started in January"
label variable m02 "Started in February"
label variable m03 "Started in March"
label variable m04 "Started in April"
label variable m05 "Started in May"
label variable m06 "Started in June"
label variable m07 "Started in July"
label variable m08 "Started in August"
label variable m09 "Started in September"

* 1107 in four groups, for the province table (single months are too few
* people per province)
generate byte mg1 = inrange(M1107, 1, 6) if !missing(M1107)
generate byte mg2 = (M1107 == 7) if !missing(M1107)
generate byte mg3 = (M1107 == 8) if !missing(M1107)
generate byte mg4 = (M1107 == 9) if !missing(M1107)
label variable mg1 "Started January to June"
label variable mg2 "Started in July"
label variable mg3 "Started in August"
label variable mg4 "Started in September"

* 1108: days with MBG meals in the last week
generate byte days = M1108
label variable days "Days with MBG meals in the last week (mean)"
generate byte d1 = (M1108 == 1) if !missing(M1108)
generate byte d2 = (M1108 == 2) if !missing(M1108)
generate byte d3 = (M1108 == 3) if !missing(M1108)
generate byte d4 = (M1108 == 4) if !missing(M1108)
generate byte d5 = (M1108 == 5) if !missing(M1108)
generate byte d6 = (M1108 == 6) if !missing(M1108)
label variable d1 "1 day"
label variable d2 "2 days"
label variable d3 "3 days"
label variable d4 "4 days"
label variable d5 "5 days"
label variable d6 "6 days"

* 1109: foods in the MBG meals in the last week (ticked = letter A-J)
generate byte f_rice    = (M1109A == "A") if received == 1
generate byte f_meat    = (M1109B == "B") if received == 1
generate byte f_fish    = (M1109C == "C") if received == 1
generate byte f_chicken = (M1109D == "D") if received == 1
generate byte f_egg     = (M1109E == "E") if received == 1
generate byte f_tofu    = (M1109F == "F") if received == 1
generate byte f_veg     = (M1109G == "G") if received == 1
generate byte f_milk    = (M1109H == "H") if received == 1
generate byte f_fruit   = (M1109I == "I") if received == 1
generate byte f_other   = (M1109J == "J") if received == 1
label variable f_rice    "Rice"
label variable f_meat    "Meat"
label variable f_fish    "Fish"
label variable f_chicken "Chicken"
label variable f_egg     "Egg"
label variable f_tofu    "Tofu or tempe"
label variable f_veg     "Vegetables"
label variable f_milk    "Milk"
label variable f_fruit   "Fruit"
label variable f_other   "Other food"

* number of the nine named foods received (rice to fruit; "other" not counted)
generate byte nfoods = f_rice + f_meat + f_fish + f_chicken + f_egg + ///
                       f_tofu + f_veg + f_milk + f_fruit
label variable nfoods "Number of the nine named foods received (mean)"

* 1110: quality of the meals in the last week
generate byte q1 = (M1110 == 1) if !missing(M1110)
generate byte q2 = (M1110 == 2) if !missing(M1110)
generate byte q3 = (M1110 == 3) if !missing(M1110)
generate byte q4 = (M1110 == 4) if !missing(M1110)
label variable q1 "Not good"
label variable q2 "Not very good"    // kurang baik
label variable q3 "Good"
label variable q4 "Very good"

* 1113A: MBG makes the child more eager to learn
generate byte a1 = (M1113A == 1) if !missing(M1113A)
generate byte a2 = (M1113A == 2) if !missing(M1113A)
generate byte a3 = (M1113A == 3) if !missing(M1113A)
generate byte a4 = (M1113A == 4) if !missing(M1113A)
label variable a1 "More eager to learn: disagree"
label variable a2 "More eager to learn: somewhat disagree"
label variable a3 "More eager to learn: agree"
label variable a4 "More eager to learn: strongly agree"

* 1113B: MBG means the child does not feel hungry during lessons
generate byte b1 = (M1113B == 1) if !missing(M1113B)
generate byte b2 = (M1113B == 2) if !missing(M1113B)
generate byte b3 = (M1113B == 3) if !missing(M1113B)
generate byte b4 = (M1113B == 4) if !missing(M1113B)
label variable b1 "Not hungry in class: disagree"
label variable b2 "Not hungry in class: somewhat disagree"
label variable b3 "Not hungry in class: agree"
label variable b4 "Not hungry in class: strongly agree"


* 1113 as "agrees": setuju (3) or sangat setuju (4)
generate byte agreeA = inlist(M1113A, 3, 4) if !missing(M1113A)
generate byte agreeB = inlist(M1113B, 3, 4) if !missing(M1113B)
label variable agreeA "Agrees: more eager to learn"
label variable agreeB "Agrees: not hungry in class"

* breakdowns for the meals: quality (1110), complete menu (1109), days (1108)
generate byte quality = M1110
label define quality 1 "Not good" 2 "Not very good" 3 "Good" 4 "Very good"
label values quality quality
label variable quality "Rated quality of the meals"

* complete menu: rice, an animal protein (meat, fish, chicken or egg),
* vegetables and fruit
generate byte complete = (f_rice & (f_meat | f_fish | f_chicken | f_egg) & f_veg & f_fruit) if received == 1
label define complete 1 "Complete menu" 0 "Menu not complete"
label values complete complete
label variable complete "Menu: rice, animal protein, vegetables and fruit"

generate byte mealdays = 1 if inlist(M1108, 1, 2)
replace       mealdays = 2 if inlist(M1108, 3, 4)
replace       mealdays = 3 if inrange(M1108, 5, 7)
label define mealdays 1 "1-2 days" 2 "3-4 days" 3 "5-6 days"
label values mealdays mealdays
label variable mealdays "Days with MBG meals in the last week"


*------------------------------------------------------------------------------
* 6. School absence (1112), for the comparison of recipients and non-recipients
*------------------------------------------------------------------------------

* 1112: days absent from school in the last week (not school holidays)
generate byte absdays = M1112
label variable absdays "Days absent from school (mean)"
generate byte absent1 = (M1112 >= 1) if !missing(M1112)
label variable absent1 "Absent at least 1 day"



*------------------------------------------------------------------------------
* 7. Survey design and save
*    Each stratum lies within one province and PSU codes are unique
*    nationally, so the design can be declared directly.
*------------------------------------------------------------------------------

svyset PSU [pweight = FWT], strata(STRATA) singleunit(centered)

drop M1101-M1113B M101 M105 M405 M504
compress
save "work/mbg_module.dta", replace

* checks: group sizes and recipients
tabulate pop_school received
tabulate pop_under5 received
tabulate pop_pregnant received
tabulate pop_breastf received

log close

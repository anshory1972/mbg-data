*==============================================================================
* 02_tables.do
*
* Computes the MBG tables from work/mbg_module.dta and writes them as CSV
* files in output/. Every table is one -mbgtable- call (see mbgtable.do).
* All tables are weighted with the person weight and use the survey design
* (strata and PSU) for the confidence intervals.
*
* Writes: output/T1_coverage.csv ... output/T9_meal_frequency.csv
*         output/all_tables.csv (all tables in one file)
*==============================================================================

version 19
clear all
set more off
capture log close
log using "log/02_tables.log", replace text

run "do/mbgtable.do"
use "work/mbg_module.dta", clear

* the results file that -mbgtable- adds rows to
* (text widths are generous so that no label is cut off)
postfile mbgpost str4 table str100 title str100 population str40 question ///
    str60 breakdown str60 category str5 area str30 split str30 split_category ///
    str12 outcome str70 outcome_label str7 statistic ///
    double(n_persons n_answered n_households n_yes ///
    weighted_persons weighted_yes estimate ci_low ci_high rse_pct) str10 flag ///
    using "work/results.dta", replace

local SCHOOL "School children, primary to senior secondary"
local B3     "Pregnant women, breastfeeding mothers and children under five (B3)"
local ALLT   "All target groups (school children and B3)"


*------------------------------------------------------------------------------
* T1. Coverage: share of each target group that received MBG in the last week
*     Questions 1102-1106
*------------------------------------------------------------------------------

local ttl "Share receiving MBG in the last week"

mbgtable received, table(T1) title("`ttl'") population(pop_targets) poplabel("`ALLT'") ///
    by(all quintile) stat(percent) question("1102-1106")

mbgtable received, table(T1) title("`ttl'") population(pop_school) poplabel("`SCHOOL'") ///
    by(all quintile level sex province) stat(percent) question("1104, 1106")

mbgtable received, table(T1) title("`ttl'") population(pop_b3) poplabel("`B3'") ///
    by(all quintile) stat(percent) question("1102, 1103, 1105, 1106")

mbgtable received, table(T1) title("`ttl'") population(pop_under5) poplabel("Children under five") ///
    by(all quintile) stat(percent) question("1105, 1106")

mbgtable received, table(T1) title("`ttl'") population(pop_pregnant) poplabel("Pregnant women") ///
    by(all quintile) stat(percent) question("1102, 1106")

mbgtable received, table(T1) title("`ttl'") population(pop_breastf) ///
    poplabel("Breastfeeding mothers of children 0-23 months") ///
    by(all quintile) stat(percent) question("1103, 1106")


*------------------------------------------------------------------------------
* T2. Number of people in the target groups, and number receiving MBG
*     (weighted totals). For comparison with the number reported by BGN.
*------------------------------------------------------------------------------

local ttl "Number of people receiving MBG in the last week"

mbgtable received, table(T2) title("`ttl'") population(pop_targets) poplabel("`ALLT'") ///
    by(all quintile) stat(total) question("1102-1106")

mbgtable received, table(T2) title("`ttl'") population(pop_school) poplabel("`SCHOOL'") ///
    by(all quintile province) stat(total) question("1104, 1106")

mbgtable received, table(T2) title("`ttl'") population(pop_b3) poplabel("`B3'") ///
    by(all quintile) stat(total) question("1102, 1103, 1105, 1106")

mbgtable received, table(T2) title("`ttl'") population(pop_under5) poplabel("Children under five") ///
    by(all quintile) stat(total) question("1105, 1106")

mbgtable received, table(T2) title("`ttl'") population(pop_pregnant) poplabel("Pregnant women") ///
    by(all quintile) stat(total) question("1102, 1106")

mbgtable received, table(T2) title("`ttl'") population(pop_breastf) ///
    poplabel("Breastfeeding mothers of children 0-23 months") ///
    by(all quintile) stat(total) question("1103, 1106")


*------------------------------------------------------------------------------
* T3. Month in 2025 when recipients first received MBG (question 1107)
*------------------------------------------------------------------------------

local ttl "Month in 2025 when MBG was first received"

mbgtable m01-m09, table(T3) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all quintile) stat(percent) question("1107")

* by province, with the months in four groups (single months are too thin)
mbgtable mg1-mg4, table(T3) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all quintile province) stat(percent) question("1107")

mbgtable m01-m09, table(T3) title("`ttl'") population(rec_all) ///
    poplabel("All people receiving MBG") ///
    by(all quintile) stat(percent) question("1107")


*------------------------------------------------------------------------------
* T4. Days with MBG meals in the last week (question 1108)
*------------------------------------------------------------------------------

local ttl "Days with MBG meals in the last week"

mbgtable days, table(T4) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all quintile level province) stat(mean) question("1108")

mbgtable d1-d6, table(T4) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all quintile level) stat(percent) question("1108")

mbgtable days, table(T4) title("`ttl'") population(rec_all) ///
    poplabel("All people receiving MBG") ///
    by(all quintile) stat(mean) question("1108")


*------------------------------------------------------------------------------
* T5. Foods in the MBG meals in the last week (question 1109)
*------------------------------------------------------------------------------

local ttl "Foods in the MBG meals in the last week"
local foods f_rice f_meat f_fish f_chicken f_egg f_tofu f_veg f_milk f_fruit f_other

mbgtable `foods', table(T5) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all quintile province) stat(percent) question("1109")

mbgtable nfoods, table(T5) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all quintile province) stat(mean) question("1109")

mbgtable `foods', table(T5) title("`ttl'") population(rec_all) ///
    poplabel("All people receiving MBG") ///
    by(all quintile) stat(percent) question("1109")


*------------------------------------------------------------------------------
* T6. Quality of the MBG meals in the last week (question 1110)
*------------------------------------------------------------------------------

local ttl "Quality of the MBG meals in the last week"

mbgtable q1-q4, table(T6) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all quintile level province) stat(percent) question("1110")

mbgtable q1-q4, table(T6) title("`ttl'") population(rec_all) ///
    poplabel("All people receiving MBG") ///
    by(all quintile) stat(percent) question("1110")


*------------------------------------------------------------------------------
* T7. School children's views of MBG (question 1113, asked of recipients)
*------------------------------------------------------------------------------

mbgtable a1-a4, table(T7) title("Children's views: MBG makes me more eager to learn") ///
    population(rec_school) poplabel("School children receiving MBG") ///
    by(all quintile level) stat(percent) question("1113A")

mbgtable b1-b4, table(T7) title("Children's views: with MBG I am not hungry in class") ///
    population(rec_school) poplabel("School children receiving MBG") ///
    by(all quintile level) stat(percent) question("1113B")

* share who agree (agree or strongly agree), by meal quality and complete menu
mbgtable agreeA agreeB, table(T7) title("Children's views by meal quality and menu") ///
    population(rec_school) poplabel("School children receiving MBG") ///
    by(all quintile quality complete) stat(percent) question("1113, 1110, 1109")


*------------------------------------------------------------------------------
* T8. School absence, recipients and non-recipients (question 1112)
*     A comparison, not an effect of MBG.
*------------------------------------------------------------------------------

local ttl "School absence in the last week"

mbgtable absdays, table(T8) title("`ttl'") population(pop_school) poplabel("`SCHOOL'") ///
    by(all quintile level) split(mbg) stat(mean) question("1112, 1106")

mbgtable absent1, table(T8) title("`ttl'") population(pop_school) poplabel("`SCHOOL'") ///
    by(all quintile level) split(mbg) stat(percent) question("1112, 1106")

* recipients only, by days with MBG meals
mbgtable absdays, table(T8) title("`ttl'") population(rec_school) ///
    poplabel("School children receiving MBG") ///
    by(all mealdays quintile) stat(mean) question("1112, 1108")


*------------------------------------------------------------------------------
* T9. Eating staples and protein often enough (Blok VII: 702, 704, 705),
*     recipients and non-recipients. A comparison, not an effect of MBG.
*------------------------------------------------------------------------------

local ttl "Eating staple food and protein often enough in the last week"

mbgtable staple plantp animalp, table(T9) title("`ttl'") population(pop_school) ///
    poplabel("`SCHOOL'") by(all quintile) split(mbg) stat(percent) question("702, 704, 705")

mbgtable staple plantp animalp, table(T9) title("`ttl'") population(pop_b3) ///
    poplabel("`B3'") by(all quintile) split(mbg) stat(percent) question("702, 704, 705")

mbgtable staple plantp animalp, table(T9) title("`ttl'") population(pop_targets) ///
    poplabel("`ALLT'") by(all quintile) split(mbg) stat(percent) question("702, 704, 705")

mbgtable staple plantp animalp, table(T9) title("`ttl'") population(pop_asked) ///
    poplabel("Everyone asked about MBG (target groups, including university students)") ///
    by(all quintile) split(mbg) stat(percent) question("702, 704, 705")


postclose mbgpost


*------------------------------------------------------------------------------
* Write the CSV files
*------------------------------------------------------------------------------

use "work/results.dta", clear

* rounding: percent to 2 decimals, mean to 3 decimals, totals to whole people
replace estimate = round(estimate, 0.01)  if statistic == "percent"
replace ci_low   = round(ci_low, 0.01)    if statistic == "percent"
replace ci_high  = round(ci_high, 0.01)   if statistic == "percent"
replace estimate = round(estimate, 0.001) if statistic == "mean"
replace ci_low   = round(ci_low, 0.001)   if statistic == "mean"
replace ci_high  = round(ci_high, 0.001)  if statistic == "mean"
replace estimate = round(estimate)        if statistic == "total"
replace ci_low   = round(ci_low)          if statistic == "total"
replace ci_high  = round(ci_high)         if statistic == "total"
replace weighted_persons = round(weighted_persons)
replace weighted_yes     = round(weighted_yes)
replace rse_pct          = round(rse_pct, 0.1)
* %g prints numbers without trailing zeros: 24.1, 4.51, 13606479
format estimate ci_low ci_high %15.10g
format weighted_persons weighted_yes n_* %15.0f
format rse_pct %8.4g

generate source = "BPS, Susenas September 2025, questionnaire VSEN25.M. Weighted."
generate version = "$VERSION"

export delimited using "output/all_tables.csv", replace datafmt

local names T1 "coverage" T2 "recipients" T3 "start_month" T4 "days" ///
            T5 "foods" T6 "quality" T7 "children_views" T8 "absence" ///
            T9 "meal_frequency"
forvalues i = 1/9 {
    local n : word `=2*`i'' of `names'
    preserve
    keep if table == "T`i'"
    export delimited using "output/T`i'_`n'.csv", replace datafmt
    restore
}

* summary of the cell rules
tabulate table flag, missing

log close

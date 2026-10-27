# MBG tables, Susenas September 2025

Tables from the MBG questions (Blok XI, questions 1101-1113) of the September
2025 Susenas, and from the meal-frequency questions (Blok VII, 702, 704, 705),
for a public web page on the MBG free meals programme. Only tables are
produced. No survey record leaves the computer that runs the code.

Web page: https://anshory1972.github.io/mbg-data/ (beta)

## How to run

1. Open `do/00_run_all.do` in Stata 19.
2. Set the two folders at the top: this project, and the folder with the Susenas files.
3. Run it. It takes about 15 minutes.
4. Then run `python build_web.py` to rebuild the web page data.

| File | What it does |
|---|---|
| `do/00_run_all.do` | Sets the folders and the cell rules, and runs the files below |
| `do/01_prepare.do` | Builds one person file: target groups, breakdowns, answers as 0/1 variables |
| `do/mbgtable.do` | The command `mbgtable`, which computes one table. Read its header for details |
| `do/02_tables.do` | One `mbgtable` call per table. Writes the CSV files |
| `build_web.py` | Turns the CSV files into `web/data.json` and copies the downloads and the code |

Data read: `ssn202509_mod_ind.dta` (persons) and `ssn202509_kp_blok43.dta`
(household expenditure per capita, for the quintiles and deciles).

## Tables

| File | Table | Questions |
|---|---|---|
| `T1_coverage.csv` | Share of each target group receiving MBG in the last week | 1102-1106 |
| `T2_recipients.csv` | Number of people in the target groups and number receiving MBG (weighted) | 1102-1106 |
| `T3_start_month.csv` | Month in 2025 when MBG was first received | 1107 |
| `T4_days.csv` | Days with MBG meals in the last week | 1108 |
| `T5_foods.csv` | Foods in the meals, and number of the nine named foods | 1109 |
| `T6_quality.csv` | Rated quality of the meals | 1110 |
| `T7_children_views.csv` | More eager to learn; not hungry in class; share who agree by meal quality and complete menu | 1113, 1110, 1109 |
| `T8_absence.csv` | Days absent and share absent at least one day, recipients and non-recipients | 1112, 1106, 1108 |
| `T9_meal_frequency.csv` | Ate staple food, plant protein and animal protein often enough, recipients and non-recipients | 702, 704, 705 |
| `T10_value.csv` | Value of MBG meals at programme cost: % of household spending, rupiah per household per month, recipients per household (households with recipients) | 1102-1108, 505 |

Every table is given for Indonesia as a whole (`area` = Total) and for urban and
rural areas. T8 and T9 are comparisons of recipients and non-recipients. They do
not show an effect of MBG. `all_tables.csv` has all tables in one file.

## Definitions

- **School children:** enrolled in primary, junior secondary or senior secondary
  school, including Paket A-C, special schools and pesantren equivalents. The survey
  also marks university students as school children (1104). They are left out,
  because MBG does not cover them, except in the T9 group "Everyone asked about MBG".
- **B3:** pregnant women, breastfeeding mothers of children 0-23 months, and
  children under five.
- **Expenditure quintiles and deciles:** people are ranked by household expenditure
  per capita (all spending, as BPS uses for poverty), weighted by the person weight.
  The cut points are national.
- **Agrees (T7):** answer 3 (setuju) or 4 (sangat setuju).
- **Complete menu (T7):** rice, an animal protein (meat, fish, chicken or egg),
  vegetables and fruit.
- **Value of MBG (T10):** cost per portion Rp 8,000 for children under five and
  primary grades 1-3 (grade from question 505), Rp 10,000 for pregnant and
  breastfeeding women, primary grades 4-6, junior and senior secondary. Monthly
  value = days with meals in the last week x cost x 4.33 weeks, summed per
  household. The % of spending is a ratio of weighted totals. T10 is computed on
  a household file with the household weight WERT; household deciles are formed
  from all households, weighted by WEIND.
- **Weights and design:** all other estimates use the person weight. Confidence
  intervals use the survey design: strata and PSU.

## Columns of the CSV files

| Column | Meaning |
|---|---|
| `table`, `title` | Table number and title |
| `population` | The people the table is about |
| `question` | Question number(s) in questionnaire VSEN25.M |
| `breakdown`, `category` | Rows, for example: Expenditure decile, D1 (poorest 10%) |
| `area` | Total, Urban or Rural |
| `split`, `split_category` | Columns of T8 and T9: MBG receipt (Recipients, Non-recipients, All) |
| `outcome`, `outcome_label` | The answer shown, for example f_egg, Egg |
| `statistic` | percent, mean, or total |
| `n_persons` | People in the cell, unweighted |
| `n_answered` | Of these, people who answered the question |
| `n_households` | Households these people live in |
| `n_yes` | People with this answer, unweighted (percent and total tables) |
| `weighted_persons` | People in the cell, weighted: an estimate for Indonesia |
| `weighted_yes` | People with this answer, weighted |
| `estimate` | Percent (2 decimals), mean (3 decimals) or total |
| `ci_low`, `ci_high` | 95% confidence interval. For percents it is computed on the logit scale, so it stays between 0 and 100 |
| `rse_pct` | Relative standard error: standard error divided by the estimate, in % |
| `flag` | `hidden`: fewer than 30 people answered (30 with the answer, for totals); no estimate and no answer counts are shown. `unreliable`: RSE above 50%. `caution`: RSE above 25% |
| `unit` | `persons`, or `households` for T10 (the counts are then households) |
| `source`, `version` | Source line and the date the tables were made |

The cell rules are set at the top of `do/00_run_all.do`.

*==============================================================================
* mbgtable.do
*
* Defines the command -mbgtable-, which computes one table and adds its rows
* to the results file. 02_tables.do runs this file once and then calls
* -mbgtable- for each table.
*
* For every breakdown category (for example decile 1), for the whole country,
* urban areas and rural areas, and, if split() is given, for every group of
* the split variable (for example recipients and non-recipients), it computes:
*
*   n_persons         people in the cell (unweighted)
*   n_answered        of these, people who answered the question
*   n_households      households these people live in
*   n_yes             people with the answer (percent and total tables)
*   weighted_persons  people in the cell, weighted (estimate for Indonesia)
*   weighted_yes      people with the answer, weighted
*   estimate          percent, mean or total
*   ci_low, ci_high   95% confidence interval, from the survey design
*   rse_pct           relative standard error = standard error / estimate, in %
*   flag              "hidden"     fewer than $MIN_N people answered (fewer
*                                  than $MIN_N with the answer, for totals).
*                                  No estimate and no answer counts are shown.
*                     "unreliable" rse_pct above $RSE_UNRELIABLE
*                     "caution"    rse_pct above $RSE_CAUTION
*
* Usage:
*   mbgtable varlist, table() title() population() poplabel() by() ///
*                     stat() question() [split()]
*
*   varlist     the answer variables. They must be answered by the same people
*               (one svy command is run for all of them).
*   table       short name, for example T1
*   title       title of the table
*   population  0/1 variable marking the people the table is about
*   poplabel    description of those people
*   by          breakdown variables (rows), for example: all decile province
*   split       optional second breakdown (columns), for example: mbg
*   stat        percent (0/1 answers), mean, or total (weighted number of 1s)
*   question    question number(s) in the questionnaire VSEN25.M
*
* The results file must be open as postfile -mbgpost- (02_tables.do does this).
*==============================================================================

capture program drop mbgtable
program define mbgtable
    syntax varlist, TABle(string) TITle(string) POPulation(varname) ///
        POPLabel(string) BY(varlist) STAT(string) QUEStion(string) ///
        [SPLit(varname)]

    * the three areas: whole country, urban, rural
    local area_names `" "Total" "Urban" "Rural" "'
    local area_if    `" "1" "urban == 1" "urban == 0" "'

    * groups of the split variable; "all" (code -1) means the whole group
    local split_name ""
    local split_codes "-1"
    if "`split'" != "" {
        local split_name : variable label `split'
        quietly levelsof `split' if `population' == 1, local(sc)
        local split_codes "-1 `sc'"
    }

    foreach b of local by {
        local blabel : variable label `b'
        if "`b'" == "all" local blabel "Indonesia"

        quietly levelsof `b' if `population' == 1, local(categories)
        foreach c of local categories {
            local clabel : label (`b') `c'

            forvalues a = 1/3 {
                local aname : word `a' of `area_names'
                local acond : word `a' of `area_if'

                foreach s of local split_codes {
                    local scond "1"
                    local slabel ""
                    if "`split'" != "" {
                        local slabel "All"
                        if `s' != -1 {
                            local scond "`split' == `s'"
                            local slabel : label (`split') `s'
                        }
                    }

                    * the cell: people in the population, category, area, group
                    tempvar cell hh
                    quietly generate byte `cell' = (`population' == 1 & `b' == `c' & `acond' & `scond')

                    quietly count if `cell'
                    local n_persons = r(N)
                    if `n_persons' == 0 {
                        drop `cell'
                        continue
                    }

                    quietly egen byte `hh' = tag(URUT) if `cell'
                    quietly count if `hh' == 1
                    local n_households = r(N)

                    quietly summarize FWT if `cell'
                    local w_persons = r(sum)

                    * survey estimates for all answer variables at once
                    if "`stat'" == "total" {
                        capture quietly svy, subpop(`cell'): total `varlist'
                    }
                    else {
                        capture quietly svy, subpop(`cell'): mean `varlist'
                    }
                    local svy_ok = (_rc == 0)
                    local df = cond(`svy_ok', e(df_r), .)
                    local t = invttail(`df', 0.025)

                    foreach y of local varlist {
                        local ylabel : variable label `y'

                        quietly count if `cell' & !missing(`y')
                        local n_answered = r(N)

                        local n_yes = .
                        local w_yes = .
                        if "`stat'" != "mean" {
                            quietly count if `cell' & `y' == 1
                            local n_yes = r(N)
                            quietly summarize FWT if `cell' & `y' == 1
                            local w_yes = r(sum)
                        }

                        local est = .
                        local lo  = .
                        local hi  = .
                        local rse = .
                        if `svy_ok' {
                            local b_ = _b[`y']
                            local se = _se[`y']
                            if "`stat'" == "percent" {
                                * confidence interval on the logit scale, as
                                * Stata's -proportion- does, so it stays
                                * between 0 and 100
                                if `b_' > 0 & `b_' < 1 {
                                    local sl = `se' / (`b_' * (1 - `b_'))
                                    local lo = 100 * invlogit(logit(`b_') - `t' * `sl')
                                    local hi = 100 * invlogit(logit(`b_') + `t' * `sl')
                                }
                                local est = 100 * `b_'
                            }
                            else {
                                local est = `b_'
                                local lo  = `b_' - `t' * `se'
                                local hi  = `b_' + `t' * `se'
                            }
                            local rse = cond(`b_' > 0, 100 * `se' / `b_', .)
                        }

                        * cell rules
                        local flag ""
                        if `rse' > $RSE_CAUTION    & !missing(`rse') local flag "caution"
                        if `rse' > $RSE_UNRELIABLE & !missing(`rse') local flag "unreliable"
                        local base = cond("`stat'" == "total", `n_yes', `n_answered')
                        if `base' < $MIN_N {
                            local flag "hidden"
                            local est = .
                            local lo  = .
                            local hi  = .
                            local rse = .
                            local n_yes = .
                            local w_yes = .
                        }

                        post mbgpost ("`table'") ("`title'") ("`poplabel'") ///
                            ("`question'") ("`blabel'") ("`clabel'") ("`aname'") ///
                            ("`split_name'") ("`slabel'") ///
                            ("`y'") ("`ylabel'") ("`stat'") ///
                            (`n_persons') (`n_answered') (`n_households') (`n_yes') ///
                            (`w_persons') (`w_yes') (`est') (`lo') (`hi') (`rse') ///
                            ("`flag'")
                    }
                    drop `cell' `hh'
                }
            }
        }
    }
    display as text "  `table' done: `title' (`poplabel')"
end

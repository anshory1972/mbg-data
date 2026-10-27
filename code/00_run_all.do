*==============================================================================
* 00_run_all.do
*
* MBG module tables, Susenas September 2025.
* Set the two folders below, then run this file. It takes a few minutes.
*==============================================================================

version 19
clear all

* folder of this project (the one that contains do/, log/, work/, output/)
cd "E:/mbg-tables"

* folder with the Susenas September 2025 files (BPS licence, not shared)
global DATA "E:/mbg-absence/data"

* cell rules
global MIN_N           30   // hide cells with fewer than 30 people answering
global RSE_CAUTION     25   // mark "caution": relative standard error above 25%
global RSE_UNRELIABLE  50   // mark "unreliable": relative standard error above 50%

* version stamp written into every CSV row
global VERSION "`c(current_date)'"

do "do/01_prepare.do"
do "do/02_tables.do"

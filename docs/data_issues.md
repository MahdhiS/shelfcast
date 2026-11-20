# Data issues

Every data-quality problem found, its impact, and how it is handled.
Found during profiling ([notebook](../notebooks/01_profiling.ipynb)); column meanings are in the [data dictionary](data_dictionary.md).

**Status:** Decided (handling agreed) · Proposed (to be confirmed) · Open (decision pending) · Noted (no action needed)

When a decided issue is implemented, the **Handled in** column names the dbt model, test or script that deals with it.

---

## holidays_events.csv

| ID | Issue | Evidence | Impact | Handling | Status | Handled in |
|---|---|---|---|---|---|---|
| DI-01 | Several rows can share a date and place | 7 date + place pairs (bridge + additional day; earthquake event + another event; Guayaquil 2016-07-24) | Joining sales to holidays would duplicate sales rows (join fan-out) | Squash to one row per date per place, with flags (`is_holiday`, `is_bridge`, …), before joining | Decided | |
| DI-02 | A transferred holiday's official date is a normal working day | 12 `transferred = True` rows, each paired with a `type = Transfer` row | Flagging the official date as a holiday marks working days as holidays | Treat the `Transfer` date as the holiday and the official date as a normal day | Decided | |
| DI-03 | Bridge days and make-up Work Days | 5 Bridge days (Mon/Fri) paired with 5 Work Days (Saturdays) | A bridge behaves like a holiday; a work day is a Saturday people work | Separate flags for bridge and work day | Decided | |
| DI-04 | Inconsistent descriptions | 2 Transfer rows (Cuenca 2017-04-13, Ibarra 2017-09-29) lack the "Traslado" prefix | Rows can't be paired by description text | Pair by place and holiday name, not by description | Noted | |
| DI-05 | Unexplained transfer | Fundación de Guayaquil moved from Monday 2016-07-25 to Sunday 2016-07-24 | Small, one local holiday | Keep as recorded | Noted | |

## oil.csv

| ID | Issue | Evidence | Impact | Handling | Status | Handled in |
|---|---|---|---|---|---|---|
| DI-06 | No rows on weekends | Mon–Fri only, 243–244 rows each | No price for Saturdays and Sundays | Fill with the last known price | Decided | |
| DI-07 | Null prices on US market holidays | 43 nulls: 42 on NYSE holidays, 1 unexplained (2017-07-03) | Gaps on those dates | Fill with the last known price | Decided | |
| DI-08 | Extends past the sales data | Runs to 2017-08-31; sales end 2017-08-15 | Those 16 days are unused. Risk of leakage if future prices are used as features | Features use only prices from before the forecast date | Decided | |

## transactions.csv

| ID | Issue | Evidence | Impact | Handling | Status | Handled in |
|---|---|---|---|---|---|---|
| DI-09 | Missing stores in early January 2016 | 2016-01-02: 36 stores, 2016-01-03: none, 2016-01-04: 14; train has normal sales (~100k rows a day) on those days | Transaction counts look artificially low | Treat as missing, not as low | Decided | |
| DI-10 | Whole days missing | Christmas 2013–2016 and 2016-01-01 (stores closed) | No transactions on those days | Expected: stores closed | Noted | |

## train.csv

| ID | Issue | Evidence | Impact | Handling | Status | Handled in |
|---|---|---|---|---|---|---|
| DI-11 | Zero-sales days have no row | Official; only 34% of the 367M possible store × item × day rows exist | A missing row can mean zero sales, a store not open yet, or an item not on sale yet | Fill with 0 only inside each store-item's active period | Open (week 2) | |
| DI-12 | Stores opened during the period | 8 stores opened after 2013; store 52 on 2017-04-20 (118 days of history) | Rows before opening aren't zero sales; store 52 has little history | No zero-filling before a store's first day; expect weaker forecasts for store 52 | Decided | |
| DI-13 | Promotions not recorded before 2014-04-01 | `onpromotion` empty for 100% of rows before that date and none after (21.66M rows, 17.3%) | Empty means unknown, not "no promotion" | Start the training window on 2014-04-01 (still 3.4 years and three Christmases) | Proposed | |
| DI-14 | Negative sales (returns) | 7,795 rows | Demand can't be negative | Count negatives as 0 for the forecast | Proposed | |
| DI-15 | Extreme values | Max 89,440 (store 39, MEATS item 1976284, sold on only 25 days); min −15,372 (store 18, BEVERAGES item 1166474, 3 days after a 9,025 spike; item normally ~10 a day) | Distorts training | Cap or flag | Open (week 2) | |
| DI-16 | Fractional sales mean kilograms | 8.19M rows (6.5%), all in weighed families (PRODUCE, MEATS, POULTRY, …) | One overall error figure mixes kilograms with pieces | Report accuracy per family as well as overall | Decided | |
| DI-17 | Christmas missing every year | No rows on 2013–2016-12-25 | Stores closed | Expected | Noted | |

## stores.csv and items.csv

| ID | Issue | Evidence | Impact | Handling | Status | Handled in |
|---|---|---|---|---|---|---|
| DI-18 | Undocumented codes | Store `type` (A–E) and `cluster` (1–17) have no official meaning; item `class` is a code with no name | Can't be interpreted | Use as plain labels | Noted | |
| DI-19 | Family name contains commas | `LIQUOR,WINE,BEER` | Awkward in SQL and file exports | Clean family names into a tidy format in staging | Decided | |
| DI-20 | Catalogue items never sold | 64 of 4,100 items have no sales | Nothing to forecast for them | Exclude from the forecasting list | Noted | |
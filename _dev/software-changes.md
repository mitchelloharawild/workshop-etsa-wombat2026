# Software changes to incorporate

Reviewed 2026-11-24, for the workshop on 2026-11-30.

## Target versions

Materials target the **development versions**, which will be on CRAN shortly.
Built from local source on 2026-11-24:

| Package | CRAN (2026-11-24) | Source used | Unreleased features used |
|---|---|---|---|
| mixtime | 0.5.0 | `main` | none needed beyond 0.5.0 |
| ggtime | 1.1.1 | `main` (1.1.1.9000) | `stat_summary_time()`, `geom_time_line()` slopes at transitions, `guide_axis_mixtime()` |
| feasts | 0.5.0 | `main` | cyclical seasonal peaks, shift times in index class, mixtime duration ACF lags |

Slides needing the new releases ("CRAN blockers"):

* `stat_summary_time()`: mixed granularities (session 1), weekly aggregation
  (session 2), and `labs.R`. These error on ggtime 1.1.1.
* Seasonal peaks, and level shifts (session 1). These run on feasts 0.5.0, but
  show integers rather than times.

ggtime's `guide_axis_mixtime()` is the default axis guide of mixtime scales. All
plots were re-rendered with it, without code changes.

## mixtime

| Change | Version | Workshop use |
|---|---|---|
| `yearmonth()`, `yearquarter()`, `yearweek()`, `year()`, `date()`, `datetime()` linear time | ≤0.3 | Replace tsibble/lubridate equivalents as index classes |
| `mixtime()` infers the chronon of `Date`/`POSIXct` from its spacing | 0.4.0 | Sub-daily indices: `mixtime(Time)` gives 30 minutes / 1 hour. `datetime()` gives 1 *second*, so a tsibble index becomes full of gaps |
| Text parsing is strict and chronon-specific | 0.3.0 | `yearquarter("1998-01-01")` errors: use `yearquarter(date(x))` |
| Durations: `years(1L)`, `weeks(1L)`, `days(1L)`, ... | – | Replace `"1 year"` strings in ggtime `period`, `time_breaks`, `time_loops` |
| Cyclical time (`day_of_week()`, `month_of_year()`, ...); comparisons; `new_cyclical_time_fn()` | 0.3–0.5 | Replace `wday()`/`month(label = TRUE)`; weekday/weekend split |
| Underspecified cyclical time, `day_of_week(6L)` is Saturday | 0.5.0 | Safe comparison: `day_of_week(x) < day_of_week(6L)` |
| `time_is_complete_at()` | 0.3.0 | Replaces counting rows (`n >= 2 * 24 * 7 - 2`) to find partial aggregates |
| Indeterminate conversions error, e.g. `yearmonth(yearweek(x))` | 0.4 → 0.5 | Teach as mixed-granularity safety; **breaks annual looping of weeks over a Gregorian year** |
| Time zones at every granularity; DST-aware arithmetic (`hours(24L)` ≠ `days(1L)`), `tz_transitions()` | 0.4.0 | New time zone slide |
| `time_components()`, `time_compose()`, `time_parse()` | 0.3–0.5 | Mention / labels |
| Month ends clamp: 31 Jan + `months(1L)` = 28 Feb | 0.4.0 | Arithmetic slide |
| Format strings `{lin(year)}`, `{cyc(hour, day)}` | 0.3.0 | `time_labels` |

## ggtime

| Change | Version | Workshop use |
|---|---|---|
| Graphics helpers moved from feasts/fabletools | 0.2 | Attach via fpp3 (or `library(ggtime)`) |
| `geom_time_line()` | 1.0.0 | Replaces `geom_line()` for time |
| `scale_x_mixtime()` (`time_breaks`, `time_labels`, `time_chronon`) | 1.0.0 | Axis control, mixed granularity, local vs absolute time |
| `coord_loop()` | 1.0.0 | Replaces month/group factor construction of season plots; works with `coord_radial()` |
| `coord_calendar()` | 1.0.0 | Replaces `sugrrants::facet_calendar()`; drop sugrrants |
| `gg_season()` drawn with `coord_loop()` (Dec→Jan is connected) | 1.1.0 | Explain helper as grammar |
| `period` accepts mixtime durations | 1.1.0 | `period = years(1L)` throughout |
| `gg_subseries()`, `gg_lag()` built from mixtime | 1.1.0 | Subseries; new lag plot slide |
| `geom_candlestick()` / `stat_ohlc()` | 1.1.0 | Out of scope (financial) |
| `stat_summary_time()` | dev | Aggregate in the plot, incomplete granules are `NA` |
| Calendar-aware default breaks | 1.1.1 | Free improvement |

## feasts

* Graphics are soft deprecated in favour of ggtime (0.5.0): describe feasts as
  decomposition, autocorrelation and feature extraction only.
* `STL()`, `ACF()` and `feat_stl()` work with mixtime indices, with no API change.
* `feat_stl()` seasonal peaks and troughs are cyclical time (dev): new slides.
* `shift_*_max()` return the time of the shift (dev): new slide.
* `ACF()` lags are mixtime durations (dev): noted on the ACF slide.

## Required fixes found by rendering

* The existing seasons deck **fails to render**: `gg_season(period = "1 year")`
  of weekly data is an indeterminate conversion. Use
  `period = years(1L, calendar = cal_isoweek)`.
* Load mixtime *after* fpp3, since it masks tsibble and lubridate functions.
* mixtime can't be compared with tsibble `yearquarter()` (etc.): convert fpp3
  datasets once, up front.
* `coord_calendar()` of Gregorian time uses 7 day rows from the epoch (a
  Thursday): use `rows = weeks(1L)` for Monday starts.

## Upstream issues worked around

1. `time_is_complete_at()` wrongly flags the day/week in which DST starts as
   incomplete for tz-aware sub-daily data (2012-10-07, 2013-10-06, 2014-10-05 in
   `vic_elec`). `stat_summary_time()` inherits this, drawing false gaps for
   weekly or monthly summaries of `vic_elec`. Workaround: aggregate to days first.
2. Cyclical time compared with a bare integer is off from its labels:
   `month_of_year(x) <= 4L` includes May, `day_of_week(x) >= 6L` is true on 5 of
   7 days. Workaround: `month_of_year(4L)`, `day_of_week(6L)`.
3. Looped plots warn "NAs produced by integer overflow" (from `S7::S7_dispatch() * y@n`), although ggtime 1.1.1
   NEWS lists this as fixed. Harmless in output; hidden by revealjs defaults.
4. `geom_time_line()` joins across removed weekends in half-hourly data
   despite documented gap handling. Workaround: `group = 1` with colour.
5. Mixed days and months on one scale errors (irregular cardinality); days with
   weeks, and quarters with years, work.
6. Cyclical time isn't supported on positions scales (by design), and
   `facet_wrap(vars(day_of_week(x)))` of time zoned time errors ("`scale_id` must
   not contain any NA"). Workaround: facet/colour by `format()`.
7. `coord_loop()` break labels count in units of the break:
   `time_breaks = hours(6L)` labels h01, h02, h03. Workaround: set `time_labels`.
8. A `geom_tile()` calendar of a whole year adds an empty column.

## Project library (renv)

`renv::restore()` installs the development versions used for the slides:

* mixtime: `mitchelloharawild/mixtime@9dd8364`
* feasts: `tidyverts/feasts@a8b4e23`
* ggtime: `mitchelloharawild/ggtime@373e848`

mixtime's uncommitted `as.numeric()` fix isn't included. mixtime bugs are
reported in `mixtime/_dev/bugs/`.

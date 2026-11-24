# Interactive explainers to incorporate

Reviewed 2026-11-24, for the workshop on 2026-11-30 (3 hours of content).
Source: `../workshop-f4sg-africast/materials/` ("AFRICAST" below). Explainers
1–6 are in the slides, with polls in the `wombat2026` room; 7–10 are not started.
The sections below are the plan they were made from.

## Recommendation

Use a graphic where **the idea is a transformation of time** (looping,
splitting, lagging, laying out), and a static plot otherwise. In order:

| # | Explainer | Deck | Tool | Effort | Class time |
|---|---|---|---|---|---|
| 1 | Time plot → season plot | seasons | morph, reuse | small | 2 min |
| 2 | Time plot → subseries plot | seasons | morph, reuse | small | 2 min |
| 3 | Time plot → lag plots → ACF | patterns | morph, reuse | small | 3 min |
| 4 | Seasonal or cyclical? | patterns | live polls, reuse | small | 0 (replaces show of hands) |
| 5 | STL windows | patterns | webR slider, reuse | small | 3 min |
| 6 | What if the loop is the wrong length? | seasons | slider, **new** | medium | 2 min |
| 7 | Time plot → calendar plot | seasons | morph, **new** | medium | 2 min |
| 8 | Feature explorer | patterns | linked plots, **new** | medium | 3 min |
| 9 | Absolute ↔ local time | seasons | morph, **new** | medium | 1 min |
| 10 | Aggregation and incomplete periods | patterns | morph, **new** | medium | 1 min |

**For 30 November: do 1–5**, about 10 minutes of class time. Add 6 if there is
time, as it best supports `coord_loop()`. Leave 7–10 for later deliveries.

## Tools in AFRICAST

| Tool | Files | How it works | Needs network |
|---|---|---|---|
| **Morphs** | `R/morph/` | R exports the first and last ggplots as SVG with their data; JavaScript animates between them, stepped by reveal.js fragments. End frames match the static plots | no |
| **webR sliders** | `webr_slider()` in `setup.R`, `webr-slider.js` | Slider values are passed to an R function run in the browser; drawn with Observable Plot | yes: webR, d3 and Plot from CDNs. The initial plot also needs d3 and Plot |
| **CRPS slider** | `crps-slider.js` | As above, calculated in JavaScript without webR | d3 and Plot |
| **Live polls** | `_extensions/seandavi/live-questions` | `.poll`, `.likert` and `.wordcloud` divs, answered by QR code | yes: `poll.nectric.com.au` |

Not useful here: the `roll` morph (cross-validation) and CRPS sliders
(forecasting). The `horizon` morph is unused in AFRICAST, and horizon plots are
outside this workshop.

## What works with mixtime

Checked by running the scenes on this repo's renv versions (mixtime `9dd8364`,
feasts `a8b4e23`, local ggtime), with svglite from a temporary library. The
middle and last steps were viewed in Chrome for Gas, Scripts and daily demand
where ticked as "viewed".

| Scene | Data | Result |
|---|---|---|
| season | quarterly Gas, monthly Scripts | works (viewed) |
| season | daily demand | **silently wrong** (viewed): no lines, as it loops over a year |
| season, subseries | `season_year` of `STL(log(Gas))` | builds, not viewed |
| subseries | quarterly Gas | works (viewed) |
| subseries | monthly Scripts | **silently wrong** (viewed): Jan–Sep lines missing |
| acf | monthly Scripts, `pause_lag = 12` | works (viewed) |
| acf | quarterly Gas or Beer, `pause_lag = 4` | builds, not viewed |
| acf | default `pause_lag` | **errors** |
| roll | tsibble integer index | builds, not viewed |

Not tested: the scenes inside these letterbox decks, stepping with fragments,
webR sliders, and polls.

### Fixes needed

1. **acf**: the default `pause_lag` uses `tsibble::guess_frequency()`, which has
   no mixtime method. Always set `pause_lag` (4 for quarters, 12 for months).
2. **subseries**: each season's line starts `0.12` later than the last, so
   `1 - (nSeasons - 1) * 0.12` is negative for 10 or more seasons. This fix
   restored all 12 months in the last step:

   ```js
   const st = Math.min(0.12, 0.6 / (nSeasons - 1));
   const reveal = ease(clamp((join - k * st) / (1 - (nSeasons - 1) * st)));
   ```

3. **season**: add a `period` argument passed to `gg_season()`, so it can loop
   over `weeks(1L)` or `days(1L)`. Periods are identified by line colour, so
   check this still works when there are many.

Fix 2 also applies to AFRICAST, if it is ever used with monthly data.

## Incorporating the reused explainers

### 1. Season plot (seasons deck)

* **Place**: after the "Visualising seasonality" answer slide, which has
  `coord_loop(time_loops = years(1L))`, and before "Your turn: describe the
  shape". Not before the exercise: the last step is its answer.
* **Data**: `pbs_scripts`, as in the surrounding slides.
* **Steps**:
  1. A time plot: time is linear.
  2. Each month belongs to a year. Split the line between years.
  3. Loop each year back to the start, stacking them.
  4. The season plot. December still connects to the next January.
* Say "loop" rather than AFRICAST's "move", to match `coord_loop()`.
* **Then cut**: the wordier "Why loop time?" bullets can be shortened, as step 4
  shows the December to January connection.

### 2. Subseries plot (seasons deck)

* **Place**: replaces the "Remap the aesthetics" → "Facet by season" reveal as
  the explanation. Keep the facet code as the slide after it.
* **Data**: `season_year` of `STL(log(Gas))`, matching those slides:

  ```r
  gas_season <- aus_production |>
    model(STL(log(Gas))) |>
    components() |>
    as_tsibble() |>
    select(Quarter, season_year)
  subseries_morph(gas_season, season_year, id = "gas-subseries")
  ```
* Monthly Scripts could be used for the "Changing seasonality" answer, after fix 2.

### 3. ACF (patterns deck)

* **Place**: move "Lag plots" *before* "ACF plots", and put the morph between
  them. The lag plot is the explanation of each bar.
* **Data**: quarterly Beer from 1992, with `pause_lag = 4`. Its lag 2 is
  negative and lag 4 positive, which AFRICAST's captions already explain. Gas
  and Scripts have strong trends, so all of their autocorrelations are positive.
* Follow with the existing Scripts ACF: trend *and* seasonality. Keep the note
  that lags are durations; the morph reads its unit ("quarter") from mixtime.
* 9 steps is long: merge lag 3 into the lag 4 step if time is short.

### 4. Polls (both decks)

| Slide | Poll | Answer |
|---|---|---|
| "Hi, who are you?" | Hands up list as a multiple choice poll | – |
| Seasonal or cyclical? (×4: deaths, lynx, bricks, amazon) | Seasonal / Cyclical / Both / Neither | Seasonal, Cyclical, Both, Neither |
| Additive or multiplicative? (retail) | Additive / Multiplicative | Multiplicative |
| "Describe the shape" (Scripts) | Which month has the fewest scripts? | February |

* Reveal results after discussion (`results: hidden`), so early votes don't lead
  others.
* Without the server questions become static lists, so slides survive network
  failure.
* Use a session name that isn't reused between workshops.
* Keep the `quiz-teachr` questions in `exercises.qmd` for self-paced practice.

### 5. STL windows (patterns deck)

* **Place**: "Fine-tuning decomposition", which only links to fpp3. The default
  decomposition before it stays as `STL(Trips)` code.
* **Data**: log of total retail turnover. It continues the multiplicative example,
  and has a changing seasonal pattern to over- or under-smooth.
* Reuse AFRICAST's chunk with `s_window` and `t_window`. `fn` must be **base R
  only** (`stats::stl()`), and `as.Date()` of mixtime months and quarters gives
  the start of the period, as the slider needs.
* Show the matching feasts code under it:
  `STL(log(Turnover) ~ trend(window = 21) + season(window = 13))`.
* Suggested prompt: "make the trend follow the seasonality".
* The Box-Cox slider could go with "Other transformations", but `log()` is all
  that this workshop uses. Skip it.

## New explainers

### 6. Loop length (seasons deck)

After "The seasonal period". A slider sets the loop length of Scripts from 1 to
36 months, and the lines align only at multiples of 12. Looping regular months
is modular arithmetic, so use JavaScript as `crps-slider.js` does, without webR.
Mark 6, 12 and 24 months and display the code for the current value:
`coord_loop(time_loops = months(12L))`.

Prompt: "Why does 24 months also work? What about 6?"

### 7. Calendar plot (seasons deck)

Before the calendar plot code, showing `coord_calendar()` as looping in two
directions. Use two months of `vic_elec`:

1. Time plot, with holidays coloured.
2. Cut into weeks, and stack them as rows.
3. Split the weeks into month columns.

The last frame should be drawn by `coord_calendar(rows = weeks(1L), ...)`.
`morph_plot_parts()` assumes one panel with linear x, so check what
`coord_calendar()` exposes first; this is the main risk.

This could also replace the four "Victorian electricity demand" videos. They go
month → day → half hour → one month of 2014, but play on their own: as a morph
the presenter controls each step, and it would use the deck's data directly.

### 8. Feature explorer (patterns deck)

After "Plotting features", replacing "most seasonal" and "most trendy" if it
works well. Hover or click a point of trend vs seasonal strength, and its series
is drawn beside it. Include the peak quarter in the label, to lead into "When is
the peak season?".

Export features and series from R as JSON (about 180 KB for `Trips`), drawn with
d3. Crosstalk and plotly are easier, but don't use ggtime's plots or style.
Works well self-paced, so also add it to `exercises.qmd`.

### 9. Absolute ↔ local time (seasons deck)

A morph between the two existing DST plots: the repeated hour slides back, and
becomes the dashed transition. Both slides already exist and need no new
concept, so this is polish.

### 10. Incomplete periods (patterns deck)

On "Temporal aggregation": quarters are grouped into years and collapse to their
mean, while 2010 (two quarters) drops out. This shows what
`time_is_complete_at()` and `stat_summary_time()` do. Use quarterly Gas, not
half-hourly `vic_elec`, which hits the DST bug in `mixtime/_dev/bugs/`.

## Technical setup

1. **Files**: copy `R/morph/` to `slides/R/morph/`, shared by both decks.
   `morph_widget()` reads `R/morph` relative to the rendered deck, so change its
   path to `../R/morph`. Put `webr_slider()` in `slides/R/webr-slider.R`
   rather than copying `setup.R`, which also sets AFRICAST's theme.
2. **Packages**: `svglite` and `systemfonts` aren't in this repo's renv. Run
   `renv::install("svglite")` (installs systemfonts) and `renv::snapshot()`.
3. **Font**: `morph_font_setup()` finds or downloads Fira Sans. These decks use
   the default ggplot2 font, so make it a no-op and don't set a font.
4. **Colours**: `webr-slider.js` and `crps-slider.js` hard code AFRICAST's sage
   and slate. Change `INK`, `GRID` and `MINOR` to suit ggplot2's grey theme. Copy
   the `.webr-slider` styles from `theme.scss` into `theme.css`; they use SCSS
   nesting and variables, so compile them first.
5. **Layout**: the morph figure is 860px wide plus captions, so doesn't fit the
   60% column. Use a full width slide without a side image, as the "Seasonal or
   Cyclical?" slides do:

   ````markdown
   ## {}

   ### How looping works

   ::::: {.morph-slide}

   ```{r}
   #| label: scripts-loop
   #| cache: false
   #| output: asis
   season_morph(pbs_scripts, Scripts, id = "scripts-loop",
     alt = "A time plot of monthly scripts looped into a season plot.")
   ```

   :::: {.morph-captions}
   ::: {.morph-step}
   Time is linear.
   :::
   ::: {.morph-step .fragment .fade-in-then-out}
   Each month belongs to a year.
   :::
   ::: {.morph-step .fragment .fade-in-then-out}
   Loop each year back to the start.
   :::
   ::: {.morph-step .fragment .fade-in-then-out}
   December connects to January.
   :::
   ::::

   :::::
   ````

   The number of captions must match the scene: season 4, subseries 5, acf 9.
   Don't use `.fragment-remove` on these slides.
6. **Caching**: use `cache: false` for these chunks. Changes to the scene files
   don't invalidate knitr's cache.
7. **Network**: the venue's WiFi may be unreliable.
   Copy d3 and Plot into `slides/libs/`. webR can remain on its CDN: without it,
   the initial plot is still shown.
8. **Publishing**: add the scripts and libraries to `resources` in `_quarto.yml`.
9. **Polls**: copy the extension to the top level `_extensions/` and add its
   filter after `custom-callouts`. It needs Quarto 1.9 (1.10.18 is installed).
10. **Accessibility**: set `alt` for every morph. They respect reduced motion;
    caption text must make sense without the animation.

Check each slide at the first, middle and *last* step, forwards and backwards.
Both broken scenes above ran without an error, so a successful render isn't
enough.

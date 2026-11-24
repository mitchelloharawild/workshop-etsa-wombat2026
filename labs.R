# Solutions to the workshop exercises, in the order of the slides.
# Run each section with Ctrl/Cmd + Enter; the Setup must be run first.

# Setup ----
library(fpp3)
library(mixtime) # Load last

# Use mixtime for the time index of each dataset
tourism <- tourism |>
  mutate(Quarter = yearquarter(Quarter))
aus_production <- aus_production |>
  mutate(Quarter = yearquarter(Quarter))
PBS <- PBS |>
  mutate(Month = yearmonth(Month))
aus_retail <- aus_retail |>
  mutate(Month = yearmonth(Month))
vic_elec <- vic_elec |>
  mutate(Time = mixtime(Time))
pedestrian <- pedestrian |>
  mutate(Date_Time = mixtime(Date_Time))


# Session 1: Time series data and patterns ----

# Exercise 1: Index, key and measured variables ----
# index: Date_Time
# key: Sensor
# measured: Count


# Exercise 2: Our first tsibble ----
accommodation <- read.csv(
  "https://workshop.nectric.com.au/wombat2026/data/aus_accommodation.csv"
)

# The index is Date, and the key is State.
# Date is read as text, so parse it first.
accommodation |>
  as_tibble() |>
  mutate(Date = as.Date(Date)) |>
  as_tsibble(index = Date, key = State)


# Demo: Time arithmetic ----
yearmonth("2026 Nov") + 0:2
date("2026-01-31") + months(1L)
date("2026-12-25") - date("2026-11-30")

# Demo: Linear and cyclical time ----
today <- date("2026-11-30")
yearmonth(today)
month_of_year(today)
day_of_week(today)
# Is it a weekday? (Saturday is day 6)
day_of_week(today) < day_of_week(6L)

# Demo: Mixing granularities ----
c(year(2026L), yearmonth("2026 Nov"), date("2026-11-30"))
year(yearmonth("2026 Nov"))
# Weeks can span two months, so this is an error
try(yearmonth(yearweek(date("2026-11-30"))))

# Exercise 3: Using the appropriate time class ----
accommodation |>
  as_tibble() |>
  mutate(Date = yearquarter(date(Date))) |>
  as_tsibble(index = Date, key = State)


# Exercise 4: Manipulating time series data ----
tourism |>
  # Only tourists to Victoria
  filter(State == "Victoria") |>
  # Calculate total Trips
  summarise(Total_Trips = sum(Trips))

# Demo: Grouping across time ----
tourism |>
  # Calculate annual totals
  index_by(Year = year(Quarter)) |>
  summarise(Total_Trips = sum(Trips), avg_trips = mean(Trips))


# Exercise 5: Visualising time series ----
vic_tourism <- tourism |>
  filter(State == "Victoria") |>
  summarise(Trips = sum(Trips))
vic_tourism |>
  autoplot(Trips)
# Describe: a strong seasonal pattern (peaking in Q1, and lowest in Q2/Q3),
# with a slight trend and no clear cycles.


# Exercise 6: STL decomposition ----
a10 <- PBS |>
  filter(ATC2 == "A10") |>
  summarise(Cost = sum(Cost) / 1e6)
# The seasonal pattern grows with the trend: log() makes it additive
a10_dcmp <- a10 |>
  model(STL(log(Cost))) |>
  components()

# Plot the components
a10_dcmp |>
  autoplot()

# Plot the seasonally adjusted data
as_tsibble(a10_dcmp) |>
  autoplot(exp(season_adjust)) +
  labs(y = "Cost ($ millions)")


# Exercise 7: The most seasonal series ----
tourism |>
  features(Trips, feat_stl) |>
  slice_max(seasonal_strength_year, n = 3) |>
  inner_join(x = tourism, y = _, by = join_by(Region, State, Purpose)) |>
  ggplot(aes(x = Quarter, y = Trips)) +
  geom_time_line() +
  facet_grid(vars(Region, State, Purpose), scales = "free_y")

# Extension: the strongest trends
tourism |>
  features(Trips, feat_stl) |>
  slice_max(trend_strength, n = 3) |>
  inner_join(x = tourism, y = _, by = join_by(Region, State, Purpose)) |>
  ggplot(aes(x = Quarter, y = Trips)) +
  geom_time_line() +
  facet_grid(vars(Region, State, Purpose), scales = "free_y")

# Demo: Peak quarter of each series, as cyclical time ----
tourism |>
  features(Trips, feat_stl) |>
  count(Purpose, seasonal_peak_year)


# Session 2: Seasonality and calendars ----

pbs_scripts <- PBS |>
  summarise(Scripts = sum(Scripts))

# Exercise 8: Looping time ----
pbs_scripts |>
  ggplot(aes(x = Month, y = Scripts)) +
  geom_time_line() +
  coord_loop(time_loops = years(1L))


# Exercise 9: Describing seasonality ----
# Scripts peak in December and are lowest in February.
# They rise through the year (with a dip in winter), and fall away after
# the December peak.
# Check the shape with a season plot:
pbs_scripts |>
  gg_season(Scripts, period = years(1L))


# Exercise 10: Seasonality in gas production ----
aus_production |>
  autoplot(Gas)

aus_production |>
  gg_season(Gas, period = years(1L))
# Production peaks in Q3, with a trough in Q1.

# Demo: A log scale shows the early seasonality ----
aus_production |>
  gg_season(Gas, period = years(1L)) +
  scale_y_log10()

# Demo: Decomposing gas production ----
gas_dcmp <- aus_production |>
  model(STL(log(Gas))) |>
  components()
gas_dcmp |>
  autoplot()
gas_dcmp |>
  gg_season(season_year)
gas_dcmp |>
  gg_subseries(season_year)


# Exercise 11: Changing seasonality ----
pbs_scripts |>
  autoplot(Scripts)

# View the seasonality
pbs_scripts |>
  gg_season(Scripts)

pbs_scripts_dcmp <- pbs_scripts |>
  model(STL(Scripts)) |>
  components()
# View the changes in seasonality
pbs_scripts_dcmp |>
  gg_season(season_year)
pbs_scripts_dcmp |>
  gg_subseries(season_year, period = years(1L))
# December is dropping rapidly, with scripts redistributed to Oct, Nov, Jan.


# Demo: Temporal aggregation ----
vic_elec |>
  index_by(Week = yearweek(Time)) |>
  summarise(Demand = sum(Demand)) |>
  autoplot(Demand)

# Weekly aggregation, using only complete weeks
# (aggregate to days first, as half-hours drop the weeks of daylight saving)
vic_daily <- vic_elec |>
  index_by(Day = date(Time)) |>
  summarise(Demand = sum(Demand))
vic_weekly <- vic_daily |>
  filter(time_is_complete_at(Day, cal_isoweek$week)) |>
  index_by(Week = yearweek(Day)) |>
  summarise(Demand = sum(Demand))
vic_weekly |>
  autoplot(Demand)
vic_weekly |>
  gg_season(Demand, period = years(1L, calendar = cal_isoweek))

# Aggregate within the plot
vic_daily |>
  ggplot(aes(x = Day, y = Demand)) +
  geom_time_line(colour = "grey60") +
  stat_summary_time(
    granule = weeks(1L), fun = mean,
    colour = "steelblue", linewidth = 1
  )

# Demo: Pedestrians by week ----
pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  autoplot(Count)

pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  index_by(Day = date(Date_Time)) |>
  summarise(Count = sum(Count)) |>
  filter(time_is_complete_at(Day, cal_isoweek$week)) |>
  index_by(Week = yearweek(Day)) |>
  summarise(Count = sum(Count)) |>
  gg_season(Count, period = years(1L, calendar = cal_isoweek))

# Demo: Temperature and demand by weekday ----
vic_elec |>
  ggplot(aes(
    y = Demand, x = Temperature,
    colour = day_of_week(Time) < day_of_week(6L)
  )) +
  geom_point(alpha = 0.1) +
  theme_minimal()


# Exercise 12: Weekly seasonality in pedestrians ----
pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  index_by(Day = date(Date_Time)) |>
  summarise(Count = sum(Count)) |>
  gg_season(Count, period = weeks(1L))


# Demo: Time zones ----
x <- datetime("2026-04-05 01:30:00", tz = "Australia/Melbourne")
x + hours(1:2)
# A day isn't always 24 hours!
x + days(1L)
x + hours(24L)


# Demo: Absolute and local time ----
dst <- vic_elec |>
  filter(
    date(Time) >= date("2012-03-31"),
    date(Time) <= date("2012-04-02")
  )
# Sub-daily time is shown in absolute time
dst |>
  ggplot(aes(x = Time, y = Demand)) +
  geom_time_line() +
  scale_x_mixtime(time_breaks = days(1L))

# Use tz = NA for local time: changes are dashed
dst |>
  ggplot(aes(x = Time, y = Demand)) +
  geom_time_line() +
  scale_x_mixtime(
    time_breaks = days(1L),
    time_chronon = cal_gregorian$minute(30L, tz = NA)
  )


# Demo: Calendar plot of electricity demand ----
vic_elec |>
  filter(yearmonth(Time) <= yearmonth("2012 Apr")) |>
  ggplot(aes(x = Time, y = Demand, colour = Holiday, group = 1)) +
  geom_time_line() +
  coord_calendar(rows = weeks(1L), cols = months(2L)) +
  scale_y_continuous(breaks = NULL) +
  theme(legend.position = "bottom")


# Exercise 13: Calendar plot of pedestrians ----
pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  filter(yearmonth(Date_Time) <= yearmonth("2015 Apr")) |>
  ggplot(aes(x = Date_Time, y = Count)) +
  geom_time_line() +
  coord_calendar(rows = weeks(1L), cols = months(2L)) +
  scale_y_continuous(breaks = NULL) +
  labs(x = "Time", y = "Pedestrian count")
# Holidays (e.g. Easter and Anzac Day) have much lower counts.


# Exercise 14: Seasonal decomposition of pedestrians ----
ped_dcmp <- pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  fill_gaps(Count = 0) |>
  model(STL(Count)) |>
  components()
ped_dcmp |>
  autoplot()
ped_dcmp |>
  gg_season(season_year, period = years(1L))
ped_dcmp |>
  gg_season(season_week, period = weeks(1L))
# The weekly pattern interacts with the daily pattern, so this model
# doesn't work well here.

# Demo: Decomposing multiple seasonalities ----
dcmp <- vic_elec |>
  model(STL(
    log(Demand) ~ season(period = "year") +
      season(period = "week") +
      season(period = "day")
  )) |>
  components()
dcmp |>
  autoplot()
dcmp |>
  gg_season(season_year, period = years(1L))
dcmp |>
  gg_season(season_week, period = weeks(1L))
dcmp |>
  gg_season(season_day, period = days(1L)) +
  scale_x_mixtime(
    time_breaks = hours(6L),
    time_labels = "{cyc(hour, day)}h"
  )
# Specific combinations of seasonal patterns
dcmp |>
  gg_season(season_day + season_week, period = weeks(1L))


# Exercise 15: Exploring many series ----
# Which strongly seasonal series peak in Q2?
tourism |>
  features(Trips, feat_stl) |>
  filter(
    seasonal_strength_year > 0.6,
    format(seasonal_peak_year) == "Q2"
  ) |>
  select(Region, Purpose, seasonal_peak_year)

tourism |>
  filter(Region == "Blue Mountains") |>
  filter(Purpose == "Holiday") |>
  model(STL(Trips)) |>
  components() |>
  gg_subseries(season_year, period = years(1L))
# The Q2 peak is growing since 2010, while Q4 is weakening.

library(fpp3)
library(mixtime)

# Use mixtime for the time index of each dataset
tourism <- tourism |> mutate(Quarter = yearquarter(Quarter))
aus_production <- aus_production |> mutate(Quarter = yearquarter(Quarter))
PBS <- PBS |> mutate(Month = yearmonth(Month))
vic_elec <- vic_elec |> mutate(Time = mixtime(Time))
pedestrian <- pedestrian |> mutate(Date_Time = mixtime(Date_Time))

tourism |>
  filter(Quarter == yearquarter("1998 Q1"))

library(fpp3)
accommodation <- read.csv(
  "https://workshop.nectric.com.au/wombat2026/data/aus_accommodation.csv"
)

as_tibble(accommodation) |>
  mutate(Date = yearquarter(date(Date))) |>
  as_tsibble(
    index = Date,
    key = c(State)
  )

.leap.seconds


tourism |>
  # Only tourists to Victoria
  filter(State == "Victoria") |>
  # Calculate total Trips
  summarise(Total_Trips = sum(Trips), avg_trips = mean(Trips))


tourism |>
  # Calculate annual totals
  index_by(Year = year(Quarter)) |>
  # Calculate total Trips
  summarise(Total_Trips = sum(Trips), avg_trips = mean(Trips))

tourism |>
  features(Trips, feat_stl) |>
  slice_max(trend_strength, n = 3) |>
  inner_join(x = tourism, y = _, by = join_by(Region, State, Purpose)) |>
  ggplot(aes(x = Quarter, y = Trips)) + geom_time_line() +
  facet_grid(vars(Region, State, Purpose), scales = "free_y")

# Peak quarter of each series, as cyclical time
tourism |>
  features(Trips, feat_stl) |>
  count(Purpose, seasonal_peak_year)

?features_by_tag

pbs_scripts <- PBS |>
  summarise(Scripts = sum(Scripts))
pbs_scripts |>
  ggplot(aes(x = Month, y = Scripts)) +
  geom_time_line() +
  coord_loop(time_loops = years(1L))

pbs_scripts |>
  gg_season(Scripts, period = years(1L))

aus_production |>
  autoplot(Gas)

# gg_season()

aus_production |>
  gg_season(Gas, period = years(1L)) +
  scale_y_log10()

aus_production |>
  model(STL(log(Gas))) |>
  components() |>
  autoplot()


aus_production |>
  model(STL(log(Gas))) |>
  components() |>
  gg_season(season_year)

aus_production |>
  model(STL(log(Gas))) |>
  components() |>
  gg_subseries(season_year)

pbs_scripts <- PBS |>
  summarise(Scripts = sum(Scripts))
pbs_scripts |>
  autoplot(Scripts)
# View the seasonality
pbs_scripts |>
  gg_season(Scripts)
# View the changes in seasonality
pbs_scripts |>
  gg_subseries(Scripts)
pbs_scripts |>
  model(STL(Scripts)) |>
  components() |>
  gg_season(season_year)
pbs_scripts |>
  model(STL(Scripts)) |>
  components() |>
  gg_subseries(season_year)

vic_elec |>
  ggplot(aes(y = Demand, x = Temperature,
             colour = day_of_week(Time) < day_of_week(6L))) +
  geom_point(alpha = 0.1) +
  theme_minimal()

pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  index_by(Day = date(Date_Time)) |>
  summarise(Count = sum(Count)) |>
  gg_season(Count, period = weeks(1L))

pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  # index_by(Day = date(Date_Time)) |>
  # summarise(Count = sum(Count)) |>
  fill_gaps() |>
  gg_season(Count, period = weeks(1L))

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
ped_dcmp |>
  gg_season(season_day, period = days(1L))
ped_dcmp |>
  gg_season(season_day + season_week, period = weeks(1L))


ped_dcmp <- pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  fill_gaps(Count = 0) |>
  model(STL(Count ~ season(period = "year") + season(period = "week"))) |>
  components()

ped_dcmp |>
  as_tsibble() |>
  mutate(Weekday = day_of_week(Date_Time) < day_of_week(6L)) |>
  ggplot(aes(x = Date_Time, y = season_week, colour = Weekday, group = 1)) +
  geom_time_line(alpha = 0.1) +
  coord_loop(time_loops = days(1L)) +
  scale_x_mixtime(time_breaks = hours(6L), time_labels = "{cyc(hour, day)}h")

# Weekly aggregation, using only complete weeks
vic_weekly <- vic_elec |>
  index_by(Day = date(Time)) |>
  summarise(Demand = sum(Demand)) |>
  filter(time_is_complete_at(Day, cal_isoweek$week)) |>
  index_by(Week = yearweek(Day)) |>
  summarise(Demand = sum(Demand))
vic_weekly |>
  gg_season(Demand, period = years(1L, calendar = cal_isoweek))

# Aggregate within the plot
vic_elec |>
  index_by(Day = date(Time)) |>
  summarise(Demand = sum(Demand)) |>
  ggplot(aes(x = Day, y = Demand)) +
  geom_time_line(colour = "grey60") +
  stat_summary_time(granule = weeks(1L), fun = mean, colour = "steelblue")

# Local time across the end of daylight saving
vic_elec |>
  filter(date(Time) >= date("2012-03-31"), date(Time) <= date("2012-04-02")) |>
  ggplot(aes(x = Time, y = Demand)) +
  geom_time_line() +
  scale_x_mixtime(time_chronon = cal_gregorian$minute(30L, tz = NA))

vic_elec |>
  filter(yearmonth(Time) <= yearmonth("2012 Apr")) |>
  ggplot(aes(x = Time, y = Demand, colour = Holiday, group = 1)) +
  geom_time_line() +
  coord_calendar(rows = weeks(1L), cols = months(2L))

pedestrian |>
  filter(Sensor == "Southern Cross Station") |>
  filter(yearmonth(Date_Time) <= yearmonth("2015 Apr")) |>
  ggplot(aes(x = Date_Time, y = Count)) +
  geom_time_line() +
  coord_calendar(rows = weeks(1L), cols = months(2L))

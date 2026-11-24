# Interactive season plot of monthly data with a slider for the length of the
# loop, drawn by libs/loop-slider.js. The index of `data` is a mixtime month.
loop_slider <- function(data, y, value = 5, max = 36) {
  date <- as.POSIXlt(as.Date(data[[tsibble::index_var(data)]]))
  spec <- list(
    month = date$year * 12L + date$mon - 70L * 12L,
    y = data[[y]], ylab = y, value = value, max = max
  )
  knitr::asis_output(sprintf(
    '<div class="webr-slider loop-slider" data-prevent-swipe><script type="application/json">%s</script></div>',
    jsonlite::toJSON(spec, auto_unbox = TRUE, digits = NA)
  ))
}

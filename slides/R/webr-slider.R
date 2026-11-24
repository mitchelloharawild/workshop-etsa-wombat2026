# Interactive plot whose data are recomputed in the browser by R (via webR) as
# its sliders move, drawn by webr-slider.js in the same style as the ggplot2
# graphics. `sliders` is a named list of sliders, each a list of `label`,
# `value`, `min`, `max` and `step`, and optionally `ticks` (values to mark
# under the slider) and `log = TRUE` (to space values logarithmically).
# `fn(data, ...)` takes the slider values as named arguments and returns a data
# frame with one column per stacked panel. It must only use base R: it runs here
# for the initial plot (which is also what the PDF handouts show) and in webR
# whenever a slider moves. Use `{name}` in `title` and `subtitle` to show the
# value of slider `name`.
webr_slider <- function(data, x, fn, sliders,
                        title = NULL, subtitle = NULL, height = 470) {
  data <- tibble::as_tibble(data)
  vars <- setdiff(names(data), x)
  spec <- list(
    fn = paste(deparse(fn), collapse = "\n"),
    x = format(as.Date(data[[x]])), xlab = x,
    data = as.list(data[vars]),
    init = as.list(do.call(fn, c(
      list(as.data.frame(data[vars])), lapply(sliders, `[[`, "value")
    ))),
    sliders = sliders, title = title, subtitle = subtitle, height = height
  )
  json <- jsonlite::toJSON(spec, auto_unbox = TRUE, digits = NA, null = "null")
  knitr::asis_output(sprintf(
    '<div class="webr-slider" data-prevent-swipe><script type="application/json">%s</script></div>',
    gsub("</", "<\\/", json, fixed = TRUE)
  ))
}

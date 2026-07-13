get_weather_forecast <- function(folder, location, output_file) {
  # Fetch an Open-Meteo weather forecast for a location and upload it to S3
  # openmeteo is GitHub-only; install here because FaaSr FunctionGitHubPackage
  # currently builds an invalid withr::with_libpaths() call for R packages.
  if (!requireNamespace("openmeteo", quietly = TRUE)) {
    remotes::install_github("tpisel/openmeteo", upgrade = "never")
  }
  library(openmeteo)
  library(tidyverse)

  # FaaSr passes arguments as strings. Accept either a place name ("tokyo")
  # or a "lat,lon" coordinate pair ("40.71,-74.01").
  parse_location <- function(loc) {
    loc <- trimws(loc)
    parts <- strsplit(loc, ",", fixed = TRUE)[[1]]
    if (length(parts) == 2) {
      nums <- suppressWarnings(as.numeric(trimws(parts)))
      if (!any(is.na(nums))) {
        return(nums)
      }

    }
    loc
  }

  location_label <- as.character(location)
  location_parsed <- parse_location(location)

  forecast <- weather_forecast(
    location_parsed,
    daily = c("temperature_2m_max", "temperature_2m_min", "precipitation_sum")
  ) %>%
    mutate(location = location_label)

  local_file <- "weather_forecast.csv"
  write_csv(forecast, local_file)

  faasr_put_file(local_file = local_file, remote_folder = folder, remote_file = output_file)

  log_msg <- paste0(
    "Function get_weather_forecast finished; forecast for '", location_label,
    "' written to ", folder, "/", output_file, " in default S3 bucket"
  )
  faasr_log(log_msg)
}

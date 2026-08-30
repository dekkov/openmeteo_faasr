get_weather_forecast <- function(folder, location, output_file, use_archive = "FALSE") {
  # Fetch an Open-Meteo weather forecast for a location and upload it to S3.
  if (!requireNamespace("openmeteo", quietly = TRUE)) {
    auth_token <- Sys.getenv("GH_PAT")
    if (!nzchar(auth_token)) {
      auth_token <- Sys.getenv("GITHUB_TOKEN")
    }
    if (!nzchar(auth_token)) {
      auth_token <- Sys.getenv("GITHUB_PAT")
    }

    remotes::install_github(
      "tpisel/openmeteo",
      auth_token = auth_token,
      upgrade = "never"
    )
  }

  library(openmeteo)
  library(tidyverse)

  # Optionally nest outputs under archive/YYYY-MM-DD so scheduled runs do not overwrite.
  resolve_folder <- function(folder, use_archive) {
    if (isTRUE(as.logical(use_archive))) {
      paste0(folder, "/archive/", format(Sys.Date(), "%Y-%m-%d"))
    } else {
      folder
    }
  }

  # FaaSr passes arguments as strings. Accept either a place name ("Tokyo")
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

  remote_folder <- resolve_folder(folder, use_archive)
  location_label <- as.character(location)
  location_parsed <- parse_location(location)

  forecast <- weather_forecast(
    location_parsed,
    daily = c("temperature_2m_max", "temperature_2m_min", "precipitation_sum")
  ) %>%
    mutate(location = location_label)

  local_file <- "weather_forecast.csv"
  write_csv(forecast, local_file)

  faasr_put_file(local_file = local_file, remote_folder = remote_folder, remote_file = output_file)

  log_msg <- paste0(
    "Function get_weather_forecast finished; forecast for '", location_label,
    "' written to ", remote_folder, "/", output_file, " in default S3 bucket"
  )
  faasr_log(log_msg)
}

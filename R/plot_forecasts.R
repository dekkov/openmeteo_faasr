plot_forecasts <- function(folder, input_file, output_file, use_archive = "FALSE") {
  # Download the combined multi-city forecast and upload a comparison plot to S3.
  library(tidyverse)

  # Keep the same archive prefix as earlier actions when use_archive is TRUE.
  resolve_folder <- function(folder, use_archive) {
    if (isTRUE(as.logical(use_archive))) {
      paste0(folder, "/archive/", format(Sys.Date(), "%Y-%m-%d"))
    } else {
      folder
    }
  }

  remote_folder <- resolve_folder(folder, use_archive)

  faasr_get_file(
    remote_folder = remote_folder,
    remote_file = input_file,
    local_file = "forecast_combined.csv"
  )

  forecast <- read_csv("forecast_combined.csv")

  # openmeteo column names can vary slightly by package version; normalize aliases.
  if (!"date" %in% names(forecast) && "time" %in% names(forecast)) {
    forecast <- forecast %>% rename(date = time)
  }
  if (!"location" %in% names(forecast)) {
    stop("Combined forecast is missing a 'location' column")
  }

  temp_max_col <- intersect(
    c("daily_temperature_2m_max", "temperature_2m_max", "temp_max"),
    names(forecast)
  )
  precip_col <- intersect(
    c("daily_precipitation_sum", "precipitation_sum", "precipitation"),
    names(forecast)
  )

  if (length(temp_max_col) == 0) {
    stop("Combined forecast is missing a daily maximum temperature column")
  }

  forecast <- forecast %>%
    mutate(date = as.Date(date))

  plot_df <- forecast %>%
    select(
      date,
      location,
      max_temp = all_of(temp_max_col[[1]]),
      precip = any_of(precip_col)
    )

  if ("precip" %in% names(plot_df)) {
    # Facet temperature and precipitation so both metrics share one PNG.
    plot_df <- plot_df %>%
      pivot_longer(
        cols = c(max_temp, precip),
        names_to = "metric",
        values_to = "value"
      ) %>%
      mutate(
        metric = recode(
          metric,
          max_temp = "Max temperature (°C)",
          precip = "Precipitation (mm)"
        )
      )

    forecast_plot <- ggplot(plot_df, aes(x = date, y = value, color = location)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      facet_wrap(~metric, scales = "free_y", ncol = 1) +
      labs(
        title = "Open-Meteo multi-city forecast comparison",
        x = "Date",
        y = NULL,
        color = "Location"
      ) +
      theme_minimal(base_size = 12) +
      theme(legend.position = "bottom")
  } else {
    forecast_plot <- ggplot(plot_df, aes(x = date, y = max_temp, color = location)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      labs(
        title = "Open-Meteo daily maximum temperature forecast",
        x = "Date",
        y = "Max temperature (°C)",
        color = "Location"
      ) +
      theme_minimal(base_size = 12) +
      theme(legend.position = "bottom")
  }

  local_file <- "forecast_comparison.png"
  ggsave(filename = local_file, plot = forecast_plot, width = 10, height = 8, dpi = 150)

  faasr_put_file(local_file = local_file, remote_folder = remote_folder, remote_file = output_file)

  log_msg <- paste0(
    "Function plot_forecasts finished; comparison plot written to ",
    remote_folder, "/", output_file, " in default S3 bucket"
  )
  faasr_log(log_msg)
}

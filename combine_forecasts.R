combine_forecasts <- function(folder, input_loc1, input_loc2, output_file) {
  # Download two location forecasts from S3 and combine them into one file

  library(tidyverse)

  faasr_get_file(remote_folder = folder, remote_file = input_loc1, local_file = "forecast_loc1.csv")
  faasr_get_file(remote_folder = folder, remote_file = input_loc2, local_file = "forecast_loc2.csv")

  forecast_loc1 <- read_csv("forecast_loc1.csv") %>%
    mutate(location_id = "loc1")
  forecast_loc2 <- read_csv("forecast_loc2.csv") %>%
    mutate(location_id = "loc2")

  common_cols <- intersect(names(forecast_loc1), names(forecast_loc2))
  for (col in common_cols) {
    if (!identical(class(forecast_loc1[[col]]), class(forecast_loc2[[col]]))) {
      forecast_loc1[[col]] <- as.character(forecast_loc1[[col]])
      forecast_loc2[[col]] <- as.character(forecast_loc2[[col]])
    }
  }

  forecast_combined <- bind_rows(forecast_loc1, forecast_loc2)

  local_file <- "forecast_combined.csv"
  write_csv(forecast_combined, local_file)

  faasr_put_file(local_file = local_file, remote_folder = folder, remote_file = output_file)

  log_msg <- paste0(
    "Function combine_forecasts finished; combined forecast written to ",
    folder, "/", output_file, " in default S3 bucket"
  )
  faasr_log(log_msg)
}

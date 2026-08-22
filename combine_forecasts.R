combine_forecasts <- function(
    folder,
    input_loc1,
    input_loc2,
    input_loc3,
    output_file,
    use_archive = "FALSE") {
  # Download three location forecasts from S3 and combine them into one file.
  library(tidyverse)

  # Keep the same archive prefix as the city-fetch actions when use_archive is TRUE.
  resolve_folder <- function(folder, use_archive) {
    if (isTRUE(as.logical(use_archive))) {
      paste0(folder, "/archive/", format(Sys.Date(), "%Y-%m-%d"))
    } else {
      folder
    }
  }

  remote_folder <- resolve_folder(folder, use_archive)

  faasr_get_file(remote_folder = remote_folder, remote_file = input_loc1, local_file = "forecast_loc1.csv")
  faasr_get_file(remote_folder = remote_folder, remote_file = input_loc2, local_file = "forecast_loc2.csv")
  faasr_get_file(remote_folder = remote_folder, remote_file = input_loc3, local_file = "forecast_loc3.csv")

  forecast_loc1 <- read_csv("forecast_loc1.csv")
  forecast_loc2 <- read_csv("forecast_loc2.csv")
  forecast_loc3 <- read_csv("forecast_loc3.csv")

  # Align column classes so bind_rows does not fail across city files.
  forecasts <- list(forecast_loc1, forecast_loc2, forecast_loc3)
  common_cols <- Reduce(intersect, lapply(forecasts, names))
  for (col in common_cols) {
    classes <- unique(vapply(
      forecasts,
      function(df) paste(class(df[[col]]), collapse = "/"),
      character(1)
    ))
    if (length(classes) > 1) {
      forecast_loc1[[col]] <- as.character(forecast_loc1[[col]])
      forecast_loc2[[col]] <- as.character(forecast_loc2[[col]])
      forecast_loc3[[col]] <- as.character(forecast_loc3[[col]])
    }
  }

  forecast_combined <- bind_rows(forecast_loc1, forecast_loc2, forecast_loc3)

  local_file <- "forecast_combined.csv"
  write_csv(forecast_combined, local_file)

  faasr_put_file(local_file = local_file, remote_folder = remote_folder, remote_file = output_file)

  log_msg <- paste0(
    "Function combine_forecasts finished; combined forecast written to ",
    remote_folder, "/", output_file, " in default S3 bucket"
  )
  faasr_log(log_msg)
}

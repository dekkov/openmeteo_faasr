# OpenMeteo Tutorial Next Steps

1. Simplify the weekly workflow setup:
   - Direct users to download `OpenMeteoForecastWeekly.json`.
   - Have users replace `YOUR_USERNAME`.
   - Have users upload the configured JSON to their `FaaSr-workflow` repository.
   - Remove instructions for rebuilding the weekly workflow in Workflow Builder.
2. Test `OpenMeteoForecastWeekly.json` manually before enabling its timer:
   - Register the workflow.
   - Invoke it once.
   - Confirm `tpisel/openmeteo` installs through `FunctionGitHubPackage`.
   - Confirm all three city forecasts complete.
   - Confirm `CombineForecasts` runs after all three inputs are available.
   - Confirm `PlotForecasts` produces `forecast_comparison.png`.
   - Confirm every action uses the same dated archive folder.
3. Use `dekkov/FaaSr-Backend` for testing until the fixes in
   [FaaSr/FaaSr-Backend#20](https://github.com/FaaSr/FaaSr-Backend/pull/20)
   are available upstream and in the published runtime image.
4. Enable the weekly timer with `0 12 * * 1`.
5. Capture tutorial images:
   - Weekly workflow registration.
   - `(FAASR SET TIMER)` inputs.
   - Generated timer workflow in GitHub Actions.
   - Dated MinIO/S3 archive folder and its files.
   - Final `forecast_comparison.png`.
6. Add the captured images to the weekly tutorial section.
7. Remove the unused compute-server and data-store screenshots left over from
   the deleted Workflow Builder walkthrough.
8. Keep `dekkov/openmeteo_faasr` function paths until the tutorial is migrated
   into `FaaSr/FaaSr-Functions`.

## Backend Testing Note

The current upstream backend path for R `FunctionGitHubPackage` dependencies has
three related problems:

- It quotes `/tmp/Rlibs` twice, producing invalid R syntax.
- It does not map the FaaSr-provided `GH_PAT` token to the token argument used by
  `remotes`/`devtools`.
- Its subprocess output handling can hide the original installation error.

The fixes are currently available from `dekkov/FaaSr-Backend`. Use that fork for
the primary test path until the upstream pull request is merged and its runtime
image is published. Keep the in-function `remotes::install_github()` workaround
on a separate test branch rather than presenting it as the tutorial's normal
installation method.

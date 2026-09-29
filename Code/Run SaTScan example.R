# -------------------------------------------------------------------------
# 1. USER SETTINGS
# -------------------------------------------------------------------------

# Path to your NON-GRAPHICAL SaTScan executable.
#
# Windows example:
satscan_bin <- "C:/Users/nj7786/Downloads/SaTScanBatch.exe"
#
# Linux example (uncomment and change if needed):
# satscan_bin <- "/opt/satscan/SaTScanBatch"

# Path to the top-level "Sample Analysis" folder AFTER you unzip it.
sample_root <- "C:/Users/nj7786/Documents/SaTScan/Sample Analysis"


# -------------------------------------------------------------------------
# 2. BUILD PATHS FOR THIS SAMPLE ANALYSIS
# -------------------------------------------------------------------------

disease_dir <- file.path(sample_root, "Disease_X")
run_dir     <- file.path(disease_dir, "20260120")
input_dir   <- file.path(run_dir, "input_files")
output_dir  <- file.path(run_dir, "output_files")

template_prm <- file.path(
  disease_dir,
  "SpaceTimePermutation_sample_parameter_file.prm"
)

case_file <- file.path(
  input_dir,
  "FakeCaseFile.csv"
)

coordinates_file <- file.path(
  sample_root,
  "Supporting Files",
  "NYC ct coordinates file.txt"
)

# Write the main SaTScan results here.
results_file <- file.path(
  output_dir,
  "Sample_analysis_results.txt"
)

# We make a COPY of the supplied .prm instead of overwriting the original.
run_prm <- file.path(
  run_dir,
  "SpaceTimePermutation_run_from_R.prm"
)


# -------------------------------------------------------------------------
# 3. CHECK THAT EVERYTHING EXISTS
# -------------------------------------------------------------------------

required_files <- c(
  satscan_bin,
  template_prm,
  case_file,
  coordinates_file
)

missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files) > 0) {
  stop(
    "These required files were not found:\n",
    paste0("  - ", missing_files, collapse = "\n")
  )
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}


# -------------------------------------------------------------------------
# 4. HELPER: CONVERT PATHS TO A FORMAT SATSCAN CAN READ
# -------------------------------------------------------------------------

satscan_path <- function(x) {
  x <- normalizePath(x, mustWork = FALSE)

  # On Windows, use backslashes in the .prm.
  if (.Platform$OS.type == "windows") {
    x <- gsub("/", "\\\\", x, fixed = TRUE)
  }

  x
}


# -------------------------------------------------------------------------
# 5. COPY AND UPDATE THE PARAMETER FILE
# -------------------------------------------------------------------------

prm <- readLines(template_prm, warn = FALSE)

replace_prm_value <- function(lines, key, value) {
  pattern <- paste0("^", key, "=")
  hit <- grep(pattern, lines)

  if (length(hit) == 0) {
    stop("Parameter not found in .prm: ", key)
  }

  if (length(hit) > 1) {
    warning("More than one '", key, "' entry found; replacing all matches.")
  }

  lines[hit] <- paste0(key, "=", value)
  lines
}

prm <- replace_prm_value(
  prm,
  "CaseFile",
  satscan_path(case_file)
)

prm <- replace_prm_value(
  prm,
  "CoordinatesFile",
  satscan_path(coordinates_file)
)

prm <- replace_prm_value(
  prm,
  "ResultsFile",
  satscan_path(results_file)
)

writeLines(prm, run_prm)

cat("\nParameter file prepared:\n")
cat("  ", run_prm, "\n\n", sep = "")

cat("SaTScan inputs:\n")
cat("  Case file:        ", case_file, "\n", sep = "")
cat("  Coordinates file: ", coordinates_file, "\n", sep = "")
cat("  Results file:     ", results_file, "\n\n", sep = "")


# -------------------------------------------------------------------------
# 6. RUN SATSCAN
# -------------------------------------------------------------------------
#
# Equivalent at the command prompt to:
#
#   SaTScanBatch.exe "C:\...\SpaceTimePermutation_run_from_R.prm"
#

cat("Starting SaTScan...\n\n")

satscan_output <- system2(
  command = satscan_bin,
  args = shQuote(normalizePath(run_prm, mustWork = TRUE)),
  stdout = TRUE,
  stderr = TRUE
)

status <- attr(satscan_output, "status")

# system2() generally has no "status" attribute when exit status = 0.
if (is.null(status)) {
  status <- 0L
}

if (length(satscan_output) > 0) {
  cat(paste(satscan_output, collapse = "\n"), "\n")
}


# -------------------------------------------------------------------------
# 7. VERIFY THAT THE ANALYSIS FINISHED
# -------------------------------------------------------------------------

if (status != 0) {
  stop(
    "\nSaTScan exited with status code ", status,
    ". Review the messages printed above."
  )
}

if (!file.exists(results_file)) {
  stop(
    "\nSaTScan returned exit status 0, but the expected results file ",
    "was not created:\n",
    results_file
  )
}

cat("\n----------------------------------------\n")
cat("SaTScan analysis completed successfully.\n")
cat("----------------------------------------\n")
cat("Main results:\n  ", results_file, "\n", sep = "")
cat("Parameter file used:\n  ", run_prm, "\n", sep = "")


# -------------------------------------------------------------------------
# 8. OPTIONAL: READ THE TEXT RESULTS BACK INTO R
# -------------------------------------------------------------------------

results_text <- readLines(results_file, warn = FALSE)

cat("\nFirst 25 lines of the SaTScan results:\n\n")
cat(paste(head(results_text, 25), collapse = "\n"))
cat("\n")

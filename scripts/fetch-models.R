# Downloads the cached brms fits (models/*.rds) from the book's Zenodo record.
#
#   Rscript scripts/fetch-models.R                      # every fit
#   Rscript scripts/fetch-models.R count-regression     # only some chapters (file slugs)
#   Rscript scripts/fetch-models.R --list               # what is missing, no download
#
# You only need this to re-execute a chapter (for example after deleting its
# _freeze/ folder). Reading the book or rendering from _freeze/ does not need
# the fits. Without them, brm() would refit each model from scratch, which
# takes hours; with them, file_refit = "never" loads the saved result.
#
# The Zenodo record id lives in scripts/models-source.txt (line "record: 1234567")
# or in the environment variable MODELS_ZENODO_RECORD. Each downloaded archive is
# checked against Zenodo's md5, and each extracted fit against models/MANIFEST.csv.

if (!file.exists("_quarto.yml")) stop("Run from the project root")
args <- commandArgs(trailingOnly = TRUE)
list_only <- "--list" %in% args
slugs <- setdiff(args, "--list")

# Which fits are missing or damaged locally?
man <- read.csv("models/MANIFEST.csv", stringsAsFactors = FALSE)
if (length(slugs)) man <- man[sub("_.*$", "", man$file) %in% slugs, ]
if (!nrow(man)) stop("No fits in the manifest match: ", paste(slugs, collapse = ", "))
path <- file.path("models", man$file)
ok <- file.exists(path) & !is.na(unname(tools::md5sum(path))) & unname(tools::md5sum(path)) == man$md5
need <- unique(man$archive[!ok])
cat(sprintf("%d of %d fits present and valid; %d archives needed\n", sum(ok), nrow(man), length(need)))
if (list_only || !length(need)) quit(save = "no")

# Record id: environment variable first, then the tracked text file
record <- Sys.getenv("MODELS_ZENODO_RECORD", unset = "")
if (!nzchar(record) && file.exists("scripts/models-source.txt")) {
  src <- readLines("scripts/models-source.txt", warn = FALSE)
  hit <- grep("^record:", src, value = TRUE)
  if (length(hit)) record <- trimws(sub("^record:", "", hit[1]))
}
if (!nzchar(record)) stop("No Zenodo record id. Fill 'record:' in scripts/models-source.txt ",
                          "(or set MODELS_ZENODO_RECORD).")

# Ask Zenodo which files the record holds
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install the jsonlite package first")
meta <- jsonlite::fromJSON(paste0("https://zenodo.org/api/records/", record))
zf <- meta$files
zkey  <- if (!is.null(zf$key)) zf$key else zf$filename
zurl  <- if (!is.null(zf$links$self)) zf$links$self else zf$links$download
zsum  <- sub("^md5:", "", zf$checksum)
if (any(!need %in% zkey)) stop("Not on Zenodo record ", record, ": ", paste(setdiff(need, zkey), collapse = ", "))

options(timeout = 3600)
tmp <- tempfile("models-"); dir.create(tmp)
for (a in need) {
  i <- match(a, zkey)
  dest <- file.path(tmp, a)
  cat("Downloading", a, "...\n")
  utils::download.file(zurl[i], dest, mode = "wb", quiet = TRUE)
  if (unname(tools::md5sum(dest)) != zsum[i]) stop("Checksum mismatch for ", a, "; try again")
  utils::untar(dest, exdir = "models")
  unlink(dest)
}

# Verify every extracted fit against the manifest
ok <- file.exists(path) & unname(tools::md5sum(path)) == man$md5
bad <- man$file[!ok]
if (length(bad)) stop("These fits failed verification: ", paste(bad, collapse = ", "))
cat("Done. All requested fits are in models/ and match the manifest.\n")

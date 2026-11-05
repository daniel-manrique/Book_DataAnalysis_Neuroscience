# Prepares the cached brms fits (models/*.rds) for archiving on Zenodo.
#
#   Rscript scripts/models-pack.R           # writes models/MANIFEST.csv and models-archive/*.tar
#   Rscript scripts/models-pack.R --dry     # only writes the manifest and reports, no archives
#
# Why: the fits are too large for GitHub (see README.md). The
# web edition is built from _freeze/, so the fits are only needed to re-execute
# a chapter. They live on Zenodo; scripts/fetch-models.R brings them back.
#
# What it does, in plain steps:
#   1. computes an md5 checksum for every models/*.rds;
#   2. groups the fits by chapter (the file name before the first underscore),
#      because a Zenodo record accepts at most 100 files and we have more fits;
#   3. writes models/MANIFEST.csv (small, tracked in git) with file, size, md5
#      and the archive that holds it;
#   4. packs one uncompressed .tar per chapter into models-archive/ (the .rds
#      files are already compressed, so compressing again gains nothing);
#   5. reports fits that no chapter mentions, so you can decide whether to
#      archive them.

if (!file.exists("_quarto.yml")) stop("Run from the project root")
dry <- "--dry" %in% commandArgs(trailingOnly = TRUE)

# 1. Every cached fit and its checksum
fits <- sort(list.files("models", pattern = "[.]rds$"))
if (!length(fits)) stop("No models/*.rds found")
md5  <- unname(tools::md5sum(file.path("models", fits)))
size <- file.size(file.path("models", fits))

# 2. Chapter group = file name up to the first underscore
chapter <- sub("_.*$", "", fits)
archive <- paste0("models-", chapter, ".tar")

# 3. Manifest (tracked in git; it is a few kilobytes)
manifest <- data.frame(file = fits, bytes = size, md5 = md5,
                       archive = archive, stringsAsFactors = FALSE)
write.csv(manifest, "models/MANIFEST.csv", row.names = FALSE)
cat(sprintf("Manifest: %d fits, %.2f GB, %d chapter archives\n",
            nrow(manifest), sum(size) / 1024^3, length(unique(archive))))

# 4. One tar per chapter
if (!dry) {
  dir.create("models-archive", showWarnings = FALSE)
  owd <- setwd("models"); on.exit(setwd(owd), add = TRUE)
  for (a in unique(archive)) {
    members <- fits[archive == a]
    utils::tar(file.path("..", "models-archive", a), files = members,
               compression = "none", tar = "internal")
  }
  setwd(owd)
  arc <- file.path("models-archive", unique(archive))
  write.csv(data.frame(archive = basename(arc), bytes = file.size(arc),
                       md5 = unname(tools::md5sum(arc))),
            "models-archive/ARCHIVES.csv", row.names = FALSE)
  cat(sprintf("Wrote %d archives to models-archive/ (upload these to Zenodo)\n", length(arc)))
}

# 5. Fits that no chapter mentions
qmd  <- list.files(".", pattern = "[.]qmd$")
text <- paste(unlist(lapply(qmd, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")
used <- vapply(fits, function(f) grepl(paste0("models/", sub("[.]rds$", "", f)), text, fixed = TRUE), TRUE)
if (any(!used)) {
  cat("\nFits not mentioned in any .qmd (probably stale; check before archiving):\n")
  cat(paste0("  ", fits[!used]), sep = "\n")
}

library(downlit)
library(xml2)

# Not called from any chapter, but needed at render time. renv's implicit
# snapshot only sees code it can scan, so declare them here to keep them in
# renv.lock. webshot2/chromote/magick: knitr uses them to screenshot
# HTML widgets for the PDF edition. quarto/rstudioapi: Quarto's R integration.
library(webshot2)
library(chromote)
library(magick)
library(quarto)
library(rstudioapi)

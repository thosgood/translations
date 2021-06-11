#!/usr/bin/env Rscript

bookdown::render_book("index.Rmd",
                      "bookdown::gitbook",
                      output_dir = "output",
                      config_file = "_bookdown.yml")

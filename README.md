## Source files

The source files for the translations are found in either the `/markdown` or the `/latex` folder.
Those in the `/markdown` folder can be built simply by running `quarto render`.

## To-do list

### Bugs

- (PDF) sometimes the content of an environment starts on a new line (e.g. 2.1, 2.4, 2.6, 2.7 etc. in `MSRI-16-1989-79`)
  + see also e.g. any theorem that starts with an em-dash followed by a new line (e.g. Theorem 1 in `SHC-9-2`)
- (BOTH) **indentation in lists should be two spaces, not four!**

### Improvements

- (CI) just move all building to GitHub CI?
  + deploy to a `build` branch and then just cron reset and pull from that

- (PDF) header on title page
- (PDF) link to html version in translator's note

- (HTML) link to pdf version in translator's note
- (HTML) show `oldpage` in the margin, as a sidenote?

- (BOTH) include link to `.qmd` source file on github
  + make the `view` metadata in `_bookdown.yml` work somehow...
  + link to the `.tex` file instead in the pdf?

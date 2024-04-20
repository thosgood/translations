## Source files

The source files for the translations are found in either the `/rmd` or the `/latex` folder; the `/bookdown-builder` folder is just used to build the final HTML/PDF versions.

## To-do list

### Bugs

- (PDF) sometimes the content of an environment starts on a new line (e.g. 2.1, 2.4, 2.6, 2.7 etc. in `MSRI-16-1989-79`)
  + see also e.g. any theorem that starts with an em-dash followed by a new line (e.g. Theorem 1 in `SHC-9-2`)
- (BOTH) **indentation in lists should be two spaces, not four!**

### Improvements

- (SCRIPT) make `server_pull_and_build` better...
  + display WAY less output
  + don't break all subsequent builds if one build fails!

- **consider different output format? just `html_document`?**
  + (https://github.com/thosgood/bookdown-maths when it's done)

- (PDF) header on title page
- (PDF) link to html version in translator's note

- (BOTH) include link to `.Rmd` source file on github
  + make the `view` metadata in `_bookdown.yml` work somehow...
  + link to the `.tex` file instead in the pdf?
- (BOTH) figure out a better standard for where to insert `\oldpage{}`
  + *should always been on a line by itself?*
  + **go back an fix this in all Rmd files**

- (HTML) link to pdf version in translator's note
- (HTML) previews of internal links (e.g. equations, sections, footnotes, and citations) on hover?
  + if so, **definitely** have a way of disabling this (ideally in the header bar, alongside e.g. TOC toggle button)
- (HTML) show `oldpage` in the margin, as a sidenote?
- (HTML) maths in the TOC still looks weird... (e.g. $f^!$ won't display)
  + seems that super/subscripts seem to cause problems? (see also `AIF-4-...`)
- (HTML) when anchors are inside other anchors, all the anchors appear when you hover over them... (e.g. Deligne's "minus three points")

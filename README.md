# To-do list

## Bugs

- (PDF) sometimes the content of an environment starts on a new line (e.g. 2.1, 2.4, 2.6, 2.7 etc. in `MSRI-16-1989-79`)

## Improvements

- **consider different output format? just `html_document`?**
  + (https://github.com/thosgood/bookdown-maths when it's done)

- (PDF) header on title page
- (PDF) link to html version in translator's note
- (HTML) link to pdf version in translator's note
- (HTML) get rid of `.html` (make it an `index.html` in the folder called `BSMF-86-etc.etc.`)

- (BOTH) include link to `.Rmd` source file on github
  + make the `view` metadata in `_bookdown.yml` work somehow...
  + link to the `.tex` file instead in the pdf?

- (HTML) previews of internal links (e.g. equations, sections, footnotes, and citations) on hover?
  + if so, **definitely** have a way of disabling this (ideally in the header bar, alongside e.g. TOC toggle button)
- (HTML) maths in the TOC still looks weird... (e.g. $f^!$ won't display)
  + seems that super/subscripts seem to cause problems? (see also `AIF-4-...`)
- (HTML) when anchors are inside other anchors, all the anchors appear when you hover over them...
- (HTML) option to have split-by-section (e.g. `MSRI-16-1989-79` would be easier to read if each section was on a separate page)

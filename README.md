# To-do list

## Technical

- **consider different output format? just `html_document`?**

- (PDF) header on title page
- (PDF) link to html version in translator's note
- (HTML) reading progress bar
- (HTML) bring back sepia mode
  + sync this up with [thosgood/fga](https://github.com/thosgood/fga) and [thosgood/sga](https://github.com/thosgood/sga)
- (HTML) previews of (internal) links on hover?
  + if so, **definitely** have a way of disabling this (ideally in the header bar, alongside e.g. TOC toggle button)
- (HTML) maths in the TOC still looks weird... (e.g. $f^!$ won't display)
  + seems that super/subscripts seem to cause problems? (see also `AIF-4-...`)
- (HTML) when anchors are inside other anchors, all the anchors appear when you hover over them...
- (BOTH) include link to `.Rmd` source file on github
  + make the `view` metadata in `_bookdown.yml` work somehow...
  + link to the `.tex` file instead in the pdf?

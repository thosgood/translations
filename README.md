# To-do list

## Translation-al

- `.Rmd` versions of existing translations
  + `978-3-540-05190-9`
  + `AIF-4-1952-73`
  + `BSMF-86-1958-137`
  + `FGA-*`
  + `MSRI-16-1989-79`


## Technical

- (SERVER) rename html files to `index.html` and put them (along with the pdf file) into a directory named after the file (so that we can go to `/bookdown/THING` instead of `/bookdown/THING.html`)

- (PDF) header on title page
- (PDF) git commit version
- (HTML) katex in section title appears twice in TOC
  + also in title in header (if title contains katex)
- (HTML) reading progress bar
- (HTML) previews of (internal) links on hover?
  + if so, **definitely** have a way of disabling this (ideally in the header bar, alongside e.g. TOC toggle button)
- (BOTH) include link to `.Rmd` source file on github
  + make the `view` metadata in `_bookdown.yml` work somehow...

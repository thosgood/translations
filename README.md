### Rmd conversion

directory structure:

- `??/items/ITEM.Rmd`, `items/ANOTHER_ITEM.Rmd`, ... (where `items/` is where files with updates are pulled to from GitHub)
- `~/builder/` (containing the `.Rproj` file etc.)
- `??/public_html/` (containing the current `builds/` directory)

method:

- for each `items/ITEM.Rmd`
  1. get `$ITEM_NAME` from `items/ITEM.Rmd`
  2. copy `items/${ITEM_NAME}.Rmd` (and `items/${ITEM_NAME}.bib`) to `~/builder/index.Rmd` (and `~/builder/bib.bib`)
  3. run `~/builder/build.R`
  4. rename `_main.html` (resp. `_main.pdf`, `_main.tex`) to `${ITEM_NAME}.html` (resp. `${ITEM_NAME}.pdf`, `${ITEM_NAME}.tex`)
- copy `~/builder/output` to `??/public_html/bookdown` (i.e. also rename `output/` to `bookdown/`)

#### To-do list

- (PDF) no header on title page
- (HTML) latex in section title appears twice in TOC
  + also in title in header (if title contains latex)
- (HTML) link to github copy of Rmd source ("source" metadata)
- (BOTH) git commit version

### Server code

```bash
#!/bin/bash

TRANSLATIONS_DIR=~/translations

cd $TRANSLATIONS_DIR
git fetch
NEW=$(git diff --name-only master origin/master | grep -E '.tex$')
if [ -z "$NEW" ]; then
  echo "no changes"
else
  echo "Here are the .tex files that have changed:"
  files=`git diff --name-only master origin/master | grep -E '.tex$' `
  git pull
  COMMIT=$(git rev-parse --short HEAD)
  echo $COMMIT
  cd $TRANSLATIONS_DIR/builds
  for file in $files; do
    BASE=${file##*/}
    PREF=${BASE%.*}
    cp $TRANSLATIONS_DIR/$file ./$BASE &&
    sed -i 's/serverfalse/servertrue/g' ./$BASE &&
    sed -i "s/GitCommitHashVariable/$COMMIT/g" ./$BASE &&
    echo $BASE &&
    shpdflatex.sh $BASE &&
    cp $PREF.pdf /var/www/labs.thosgood.com/builds
  done
  rm $TRANSLATIONS_DIR/builds/*
fi
```

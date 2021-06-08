### To-do list

- (PDF) header on title page
- (HTML) latex in section title appears twice in TOC
  + also in title in header (if title contains latex)
- (HTML) link to github copy of Rmd source ("source" metadata)
- (HTML) make `download: ["pdf"]` in `_output.yml` work somehow...
- (BOTH) git commit version

### Server code

**Using the following versions:**
- `bookdown 0.22.3`
- `pandoc 2.11.1.1`
- `pdfTeX 3.141592653-2.6-1.40.22`

```bash
#!/bin/bash

TRANSLATIONS_DIR=~/translations
WEBSITE=/var/www/labs.thosgood.com

cd $TRANSLATIONS_DIR
git fetch
NEWTEX=$(git diff --name-only master origin/master | grep -E '.tex$')
NEWRMD=$(git diff --name-only master origin/master | grep -E '.Rmd$')
if [ -z "$NEWTEX" ] && [ -z "$NEWRMD" ]; then
  echo "no changes"
else
  echo "Here are the .tex files that have changed:"
  echo "$NEWTEX"
  echo "Here are the .Rmd files that have changed:"
  echo "$NEWRMD"
  git pull
  COMMIT=$(git rev-parse --short HEAD)
  echo "Updating to git commit hash $COMMIT"
  if ! [ -z "$NEWTEX" ]; then
    cd $TRANSLATIONS_DIR/builds
    for file in $NEWTEX; do
      BASE=${file##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$file ./$BASE &&
      sed -i 's/serverfalse/servertrue/g' ./$BASE &&
      sed -i "s/GitCommitHashVariable/$COMMIT/g" ./$BASE &&
      echo "$BASE" &&
      shpdflatex.sh $BASE &&
      cp $PREF.pdf $WEBSITE/builds
    done
  fi
  if ! [ -z "$NEWRMD" ]; then
    cd $TRANSLATIONS_DIR/bookdown-builder/
    if [ -f "./_main.Rmd" ]; then
      rm ./_main.Rmd
    fi
    for file in $NEWRMD; do
      BASE=${file##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$file ./index.Rmd
      if [ -f "$TRANSLATIONS_DIR/${file%.*}.bib" ]; then
        cp "$TRANSLATIONS_DIR/${file%.*}.bib" .
      fi
      echo "$BASE" &&
      sed -i "s/PDF_FILE_NAME/$PREF/g" ./_output.yml &&
      ./build.R &&
      mv output/_main.html output/$PREF.html &&
      mv output/_main.pdf output/$PREF.pdf &&
      mv output/_main.tex output/$PREF.tex &&
      rm index.Rmd &&
      rm *.bib
    done
    cp -r output/* $WEBSITE/bookdown
  fi
fi
```

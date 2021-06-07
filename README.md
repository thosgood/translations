### To-do list

- (PDF) no header on title page
- (HTML) latex in section title appears twice in TOC
  + also in title in header (if title contains latex)
- (HTML) link to github copy of Rmd source ("source" metadata)
- (BOTH) git commit version

### Server code

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
    rm $TRANSLATIONS_DIR/builds/*
  fi
  if ! [ -z "$NEWRMD" ]; then
    cd $TRANSLATIONS_DIR/bookdown-builder/
    for file in $NEWRMD; do
      BASE=${file##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$file ./index.Rmd
      if [ -f "${file%.*}.bib"]; then
        cp $TRANSLATIONS_DIR/${file%.*}.bib .
      fi
      echo "$BASE" &&
      ./build.R &&
      mv ./output/_main.html ./bookdown-builder/output/$PREF.html &&
      mv ./output/_main.pdf ./bookdown-builder/output/$PREF.pdf &&
      mv ./output/_main.tex ./bookdown-builder/output/$PREF.tex
    done
    #mv $TRANSLATIONS_DIR/bookdown-builder/output $WEBSITE/bookdown
  fi
fi
```

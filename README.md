### To-do list

- move `clever_git_pull` into this repo

- (PDF) header on title page
- (HTML) latex in section title appears twice in TOC
  + also in title in header (if title contains latex)
- (HTML) link to github copy of Rmd source ("source" metadata)
- (HTML) make `download: ["pdf"]` in `_output.yml` work somehow...
  + need to rename the pdf halfway through the `build.R` process, before starting the gitbook build!
- (HTML) reading progress bar
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
  printf "No changes to any .tex or .Rmd files!\n"
else
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "Here are the .tex files that have changed:\n"
  printf "$NEWTEX\n"
  printf "Here are the .Rmd files that have changed:\n"
  printf "$NEWRMD\n"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  git pull
  COMMIT=$(git rev-parse --short HEAD)
  printf "\nUpdating to git commit $COMMIT\n"
  if ! [ -z "$NEWTEX" ]; then
    cd $TRANSLATIONS_DIR/builds
    for file in $NEWTEX; do
      BASE=${file##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$file ./$BASE &&
      sed -i 's/serverfalse/servertrue/g' ./$BASE &&
      sed -i "s/GitCommitHashVariable/$COMMIT/g" ./$BASE &&
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      shpdflatex.sh $BASE &&
      cp $PREF.pdf $WEBSITE/builds
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
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
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      sed -i "s/PDF_FILE_NAME/$PREF/g" ./_output.yml &&
      ./build.R &&
      mv output/_main.html output/$PREF.html &&
      mv output/_main.pdf output/$PREF.pdf &&
      mv output/_main.tex output/$PREF.tex &&
      rm index.Rmd &&
      rm *.bib
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    done
    cp -r output/* $WEBSITE/bookdown
  fi
  printf "\nDone!\n"
fi
```

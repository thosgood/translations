#!/bin/bash

# Using the following versions:
# - bookdown 0.22.3
# - pandoc 2.11.1.1
# - pdfTeX 3.141592653-2.6-1.40.22

usage() { echo "Usage: $0 [-a <rmd|tex>]" 1>&2; exit 1; }

while getopts ":s:p:" o; do
    case "${o}" in
        a)
            s=${OPTARG}
            (("$s" == "rmd" || "$s" == "tex")) || usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

TRANSLATIONS_DIR=~/translations
WEBSITE=/var/www/labs.thosgood.com

cd $TRANSLATIONS_DIR
git reset --hard
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
    for file in $NEWRMD; do
      BASE=${file##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$file ./index.Rmd
      if [ -f "$TRANSLATIONS_DIR/${file%.*}.bib" ]; then
        cp "$TRANSLATIONS_DIR/${file%.*}.bib" .
      fi
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      sed -ir "s/\".*pdf\"/$PREF.pdf/g" _output.yml &&
      ./build_pdf.R &&
      mv output/_main.pdf "output/$PREF.pdf" &&
      ./build_html.R &&
      mv output/_main.html "output/$PREF.html" &&
      mv output/_main.tex "output/$PREF.tex" &&
      rm index.Rmd &&
      rm *.bib
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    done
    cp -r output/* $WEBSITE/bookdown
  fi
  printf "\nDone!\n"
fi

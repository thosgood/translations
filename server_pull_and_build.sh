#!/bin/bash

# Using the following versions:
# - bookdown 0.22.3
# - pandoc 2.11.1.1
# - pdfTeX 3.141592653-2.6-1.40.22

usage() { echo "Usage: $0 [-a <rmd|tex>]" 1>&2; exit 1; }

while getopts ":a:" o; do
    case "${o}" in
        a)
            ALL_TYPE=${OPTARG}
            if [[ "$ALL_TYPE" != "rmd" ]] && [[ "$ALL_TYPE" != "tex" ]]; then
              usage
            fi
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
git clean -df
git fetch

if [ "$ALL_TYPE" == "tex" ]; then
  NEW_TEX=$(find latex _in-progress -name '*.tex')
elif [ "$ALL_TYPE" == "rmd" ]; then
  NEW_RMD=$(find rmd _in-progress -name '*.Rmd')
else
  NEW_TEX=$(git diff --name-only master origin/master | grep -E '.tex$')
  NEW_RMD=$(git diff --name-only master origin/master | grep -E '.Rmd$')
fi

if [ -z "$NEW_TEX" ] && [ -z "$NEW_RMD" ]; then
  printf "No changes to any .tex or .Rmd files!\n"
else
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "Here are the .tex files that have changed:\n"
  printf "$NEW_TEX\n"
  printf "Here are the .Rmd files that have changed:\n"
  printf "$NEW_RMD\n"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  git pull
  COMMIT=$(git rev-parse --short HEAD)
  printf "\nUpdating to git commit $COMMIT\n"
  if ! [ -z "$NEW_TEX" ]; then
    cd $TRANSLATIONS_DIR/builds
    for FILE in $NEW_TEX; do
      BASE=${FILE##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$FILE ./$BASE &&
      sed -i 's/serverfalse/servertrue/g' ./$BASE &&
      sed -i "s/GitCommitHashVariable/$COMMIT/g" ./$BASE &&
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      shpdflatex.sh $BASE &&
      cp $PREF.pdf $WEBSITE/builds
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    done
  fi
  if ! [ -z "$NEW_RMD" ]; then
    cd $TRANSLATIONS_DIR/bookdown-builder/
    for FILE in $NEW_RMD; do
      if [ -z "_main.Rmd" ]; then
        rm _main.Rmd
      fi
      BASE=${FILE##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$FILE ./index.Rmd
      if [ -f "$TRANSLATIONS_DIR/${FILE%.*}.bib" ]; then
        cp "$TRANSLATIONS_DIR/${FILE%.*}.bib" .
      fi
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      sed -ir "s/\".*pdf\"/\"$PREF.pdf\"/g" _output.yml &&
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

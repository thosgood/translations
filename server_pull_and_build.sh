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

# Where the local copy of the repo is
TRANSLATIONS_DIR=~/translations
# Where to "publish" files
WEBSITE=/var/www/labs.thosgood.com/translations

# Clean-up
cd $TRANSLATIONS_DIR
git reset --hard
git clean -df
git fetch

if [ "$ALL_TYPE" == "tex" ]; then
  # To rebuild all tex files
  NEW_TEX=$(find latex _in-progress -name '*.tex')
elif [ "$ALL_TYPE" == "rmd" ]; then
  # To rebuild all Rmd files
  NEW_RMD=$(find rmd _in-progress -name '*.Rmd')
else
  # Only get changed files
  NEW_TEX=$(git diff --name-only main origin/main | grep -E '.tex$')
  NEW_RMD=$(git diff --name-only main origin/main | grep -E '.Rmd$')
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
  # Get the git commit hash
  COMMIT=$(git rev-parse --short HEAD)
  if ! [ -z "$NEW_TEX" ]; then
    cd $TRANSLATIONS_DIR/builds
    for FILE in $NEW_TEX; do
      BASE=${FILE##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$FILE ./$BASE &&
      # Automatic linking to the git commit
      sed -i 's/serverfalse/servertrue/g' ./$BASE &&
      sed -i "s/GitCommitHashVariable/$COMMIT/g" ./$BASE &&
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      # Build
      shpdflatex.sh $BASE &&
      # Deploy
      cp $PREF.pdf $WEBSITE
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    done
  fi
  if ! [ -z "$NEW_RMD" ]; then
    cd $TRANSLATIONS_DIR/bookdown-builder/
    for FILE in $NEW_RMD; do
      # Clean-up
      if [ -z "_main.Rmd" ]; then
        rm _main.Rmd
      fi
      BASE=${FILE##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$FILE ./index.Rmd
      # If there's a bib file, then bring that along too
      if [ -f "$TRANSLATIONS_DIR/${FILE%.*}.bib" ]; then
        cp "$TRANSLATIONS_DIR/${FILE%.*}.bib" .
      fi
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      # Build
      # Tell Bookdown how to find the PDF file when we build the html version
      sed -ir "s/\".*pdf\"/\"$PREF.pdf\"/g" _output.yml &&
      # Git commit version number in automatic link
      # (note that this is the same for ALL files currently being built, so
      #  we don't need to worry about the fact that this is only changed on the
      #  first time through this loop (i.e. only for the first value of $FILE))
      sed -ir "s/GIT_COMMIT_HASH_VARIABLE/$COMMIT/g" _translator-note.Rmd &&
      ./build_pdf.R &&
      mv output/_main.pdf "output/$PREF.pdf" &&
      mv output/_main.tex "output/$PREF.tex" &&
      ./build_html.R &&
      mv output/_main.html "output/$PREF.html" &&
      # Clean-up
      rm index.Rmd &&
      rm *.bib
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    done
    # Deploy
    cp -r output/* $WEBSITE
  fi
  printf "\nDone!\n"
fi

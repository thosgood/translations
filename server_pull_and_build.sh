#!/bin/bash

# Using the following versions:
# - bookdown 0.22.3
# - pandoc 2.11.1.1
# - pdfTeX 3.141592653-2.6-1.40.22

usage() { echo "Usage: $0 [-a <qmd|tex>]" 1>&2; exit 1; }

while getopts ":a:" o; do
    case "${o}" in
        a)
            ALL_TYPE=${OPTARG}
            if [[ "$ALL_TYPE" != "qmd" ]] && [[ "$ALL_TYPE" != "tex" ]]; then
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
WEBSITE=/var/www/translations.thosgood.net/

# Clean-up
cd $TRANSLATIONS_DIR
git reset --hard
git clean -df
git fetch

if [ "$ALL_TYPE" == "tex" ]; then
  # To rebuild all tex files
  NEW_TEX=$(find latex _in-progress -name '*.tex')
elif [ "$ALL_TYPE" == "qmd" ]; then
  # To rebuild all qmd files
  NEW_RMD=$(find qmd _in-progress -name '*.qmd')
else
  # Only get changed files
  NEW_TEX=$(git diff --name-only main origin/main | grep -E '.tex$')
  NEW_RMD=$(git diff --name-only main origin/main | grep -E '.qmd$')
fi

if [ -z "$NEW_TEX" ] && [ -z "$NEW_RMD" ]; then
  printf "No changes to any .tex or .qmd files!\n"
else
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "Here are the .tex files that have changed:\n"
  printf "$NEW_TEX\n"
  printf "Here are the .qmd files that have changed:\n"
  printf "$NEW_RMD\n"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  git pull
  # Get the git commit hash
  COMMIT=$(git rev-parse --short HEAD)
  if ! [ -z "$NEW_TEX" ]; then
    mkdir -p $TRANSLATIONS_DIR/builds
    cd $TRANSLATIONS_DIR/builds
    for FILE in $NEW_TEX; do
      # TO-DO: put all latex ones inside their own directory and then just
      #        copy the whole directory (so can e.g. include .bib and .bcf easy)
      BASE=${FILE##*/}
      PREF=${BASE%.*}
      cp $TRANSLATIONS_DIR/$FILE ./$BASE &&
      if [ -f "$TRANSLATIONS_DIR/${FILE%.*}.bib" ]; then
        cp "$TRANSLATIONS_DIR/${FILE%.*}.bib" .
      fi
      # Automatic linking to the git commit
      sed -i 's/serverfalse/servertrue/g' ./$BASE &&
      sed -i "s/GitCommitHashVariable/$COMMIT/g" ./$BASE &&
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $BASE\n" &&
      # Build
      Rscript -e "tinytex::pdflatex('$BASE')" &&
      # Deploy
      cp $PREF.pdf $WEBSITE
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    done
  fi
  if ! [ -z "$NEW_RMD" ]; then
    cd $TRANSLATIONS_DIR/markdown/
    for FILE in $NEW_RMD; do
      BASE=${FILE##*/}
      PREF=${BASE%.*}
      quarto render $FILE
    done
    cp -r _output/* $WEBSITE
  fi
  printf "\nDone!\n"
fi

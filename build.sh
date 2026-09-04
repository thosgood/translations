#!/bin/bash

###################
# Parse arguments #
###################

usage() { echo "Usage: $0 -a [<quarto|latex|all>]" 1>&2; exit 1; }

while getopts ":a:" o; do
  case "${o}" in
    a)
      ALL_TYPE=${OPTARG}
      if [[ "$ALL_TYPE" != "quarto" ]] && [[ "$ALL_TYPE" != "latex" ]] && [[ "$ALL_TYPE" != "all" ]] ; then
        usage
      fi
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))


#############
# Variables #
#############

# The local website directory where we will "deploy" files.
WEBSITE_DIR=/var/www/translations.thosgood.net/

# The local repository location.
TRANSLATIONS_DIR=~/translations
# The local directory for the LaTeX / Quarto files.
LATEX_DIR=$TRANSLATIONS_DIR/latex
QUARTO_DIR=$TRANSLATIONS_DIR/markdown


###############################################
# Ensure that we are in the correct directory #
###############################################

if [[ "$PWD" != "$TRANSLATIONS_DIR" ]] ; then
  printf "\nThis is not a robustly written script: it needs to be run from $TRANSLATIONS_DIR\n"
  exit 1
fi


###########################################################
# Ensure that you haven't changed the directory structure #
###########################################################

if [ ! -d "$LATEX_DIR" ]; then
  prinf "\n$LATEX_DIR does not exist\n" &&
  exit 1
fi

if [ ! -d "$QUARTO_DIR" ]; then
  prinf "\n$QUARTO_DIR does not exist\n" &&
  exit 1
fi


############################
# Clean-up local directory #
############################

printf "Resetting local directory to clean slate...\n"
git reset --hard
git clean -df
if git fetch >/dev/null ; then
  printf "\nLocal directory reset to clean state\n"
else
  print "\ngit fetch failed\n"
fi


############################
# Pull from git repository #
############################

printf "\nUpdating from remote repository...\n"
if git pull >/dev/null ; then
    printf "\nAll local files now up to date\n"
    # Get the git commit hash
    COMMIT_HASH=$(git rev-parse --short HEAD)
else
    printf "\ngit pull failed\n"
    exit 1
fi


#####################
# Build LaTeX files #
#####################

if [ "$ALL_TYPE" != "latex" ] && [ "$ALL_TYPE" != "all" ] ; then
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "\nSkipping .tex files\n"
else
  cd $LATEX_DIR
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "\nBuilding all .tex files\n"
  TEX_FILES=$(find $LATEX_DIR -name '*.tex')
  if ! [ -z "$TEX_FILES" ] ; then
    for FILE in $TEX_FILES ; do
      FILE_DIR=$(dirname $FILE)
      FILE_BASE=$(basename $FILE)
      FILE_PREFIX=${FILE_BASE%.*}
      cd $FILE_DIR
      # Replace the placeholder string with the git commit. 
      sed -i 's/serverfalse/servertrue/g' ./$FILE_BASE &&
      sed -i "s/GitCommitHashVariable/$COMMIT_HASH/g" ./$FILE_BASE
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "\nWorking on $FILE_BASE...\n"
      if Rscript -e "tinytex::pdflatex('$FILE_BASE')" >/dev/null ; then
        printf "\nMoving $FILE_PREFIX.pdf to $WEBSITE_DIR\n"
        mv $FILE_PREFIX.pdf $WEBSITE_DIR
      else
        printf "\nTinyTeX encountered some sort of error\n"
      fi
    done
  fi
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "\nFinished building .tex files!\n"
fi


######################
# Build Quarto files #
######################

if [ "$ALL_TYPE" != "quarto" ] && [ "$ALL_TYPE" != "all" ] ; then
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "\nSkipping .qmd files\n"
else
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "\nBuilding all .qmd files\n"
  cd $QUARTO_DIR
  # Building all the Quarto files is easy!
  if quarto render >/dev/null ; then
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "\nFinished building .qmd files!\n"
    printf "\nMoving built files to $WEBSITE_DIR\n"
    mv -r _output/* $WEBSITE_DIR
  else
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "\nQuarto encountered some sort of error\n"
    exit 1
  fi
fi

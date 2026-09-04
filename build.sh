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
LATEX_DIR_NAME=latex
LATEX_DIR=$TRANSLATIONS_DIR/$LATEX_DIR_NAME
QUARTO_DIR_NAME=markdown
QUARTO_DIR=$TRANSLATIONS_DIR/$QUARTO_DIR_NAME


###############################################
# Ensure that we are in the correct directory #
###############################################

if [[ "$PWD" != "$TRANSLATIONS_DIR" ]] ; then
  printf "This is not a robustly written script: it needs to be run from $TRANSLATIONS_DIR\n"
  exit 1
fi


###########################################################
# Ensure that you haven't changed the directory structure #
###########################################################

if [ ! -d "$LATEX_DIR" ]; then
  prinf "$LATEX_DIR does not exist\n" &&
  exit 1
fi

if [ ! -d "$QUARTO_DIR" ]; then
  prinf "$QUARTO_DIR does not exist\n" &&
  exit 1
fi


############################
# Clean-up local directory #
############################

printf "Resetting local directory to clean slate...\n"
git reset --hard
git clean -df
if git fetch >/dev/null ; then
  printf "Local directory reset to clean state\n"
else
  print "git fetch failed\n"
fi


############################
# Pull from git repository #
############################

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
printf "Updating from remote repository...\n"
if git pull >/dev/null ; then
    printf "All local files now up to date\n"
    # Get the git commit hash
    COMMIT_HASH=$(git rev-parse --short HEAD)
else
    printf "git pull failed\n"
    exit 1
fi


#####################
# Build LaTeX files #
#####################


printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
if [ "$ALL_TYPE" != "latex" ] && [ "$ALL_TYPE" != "all" ] ; then
  printf "Skipping .tex files\n"
else
  printf "Building all .tex files\n"
  LATEX_FILES=$(find $LATEX_DIR -name '*.tex')
  if ! [ -z "$LATEX_FILES" ] ; then
    for FILE in $LATEX_FILES ; do
      FILE_DIR=$(dirname $FILE)
      FILE_BASE=$(basename $FILE)
      FILE_PREFIX=${FILE_BASE%.*}
      cd $FILE_DIR
      # Replace the placeholder string with the git commit. 
      sed -i 's/serverfalse/servertrue/g' ./$FILE_BASE &&
      sed -i "s/GitCommitHashVariable/$COMMIT_HASH/g" ./$FILE_BASE
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $FILE_BASE...\n"
      if Rscript -e "tinytex::pdflatex('$FILE_BASE')" >/dev/null ; then
        printf "$FILE_BASE successfully built!"
        printf "Moving $FILE_PREFIX.pdf to $WEBSITE_DIR\n"
        mv $FILE_PREFIX.pdf $WEBSITE_DIR
      else
        printf "\nTinyTeX encountered some sort of error\n"
      fi
      cd $TRANSLATIONS_DIR
    done
  fi
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  printf "Finished building .tex files!\n"
fi


######################
# Build Quarto files #
######################

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
if [ "$ALL_TYPE" != "quarto" ] && [ "$ALL_TYPE" != "all" ] ; then
  printf "Skipping .qmd files\n"
else
  printf "Building all .qmd files\n"
  QUARTO_FILES=$(find $QUARTO_DIR -name 'index.qmd')
  if ! [ -z "$QUARTO_FILES" ] ; then
    for FILE in $QUARTO_FILES ; do
      FILE_DIR=$(dirname $FILE)
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      printf "Working on $FILE_DIR...\n"
      if quarto render $FILE_DIR >/dev/null ; then
        printf "$FILE_DIR successfully built!\n"
      else
        printf "\nQuarto encountered some sort of error\n"
      fi
    done
  fi
  printf "Moving all built Quarto files to $WEBSITE_DIR"
  mv $QUARTO_DIR/_output/* $WEBSITE_DIR
fi

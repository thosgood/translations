#!/bin/bash


#############
# Variables #
#############

# The local website directory where we will "deploy" files.
WEBSITE_DIR=/var/www/translations.thosgood.net/

# The local repository location.
TRANSLATIONS_DIR=/home/tim/translations
# The local directory for the LaTeX / Quarto files.
LATEX_DIR=$TRANSLATIONS_DIR/latex
QUARTO_DIR=$TRANSLATIONS_DIR/markdown
QUARTO_OUTPUT_DIR=$QUARTO_DIR/_output


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


###################
# Parse arguments #
###################

usage() { echo "Usage: $0 [-a (all) | -l (latex) | -q (quarto) | -d (diff) ]" 1>&2; exit 1; }

while getopts "alqd" opt; do
  case "$opt" in 
    a)
      LATEX_FILES=$(find $LATEX_DIR -name '*.tex')
      QUARTO_FILES=$(find $QUARTO_DIR -name '*.qmd')
      ;;
    l)
      LATEX_FILES=$(find $LATEX_DIR -name '*.tex')
      ;;
    q)
      QUARTO_FILES=$(find $QUARTO_DIR -name '*.qmd')
      ;;
    d)
      LATEX_FILES=$(git diff --name-only main origin/main | grep -E '.tex' | grep -vE '_template')
      QUARTO_FILES=$(git diff --name-only main origin/main | grep -E '.qmd')
      ;;
    *)
      usage
      ;;
  esac
done


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
printf "Building .tex files\n"
if ! [ -z "$LATEX_FILES" ] ; then
  printf "Building .tex files\n"
  for FILE in $LATEX_FILES ; do
    FILE_DIR=$(dirname $FILE)
    FILE_BASE=$(basename $FILE)
    FILE_PREFIX=${FILE_BASE%.*}
    # Replace the placeholder string with the git commit. 
    sed -i 's/serverfalse/servertrue/g' $FILE &&
    sed -i "s/GitCommitHashVariable/$COMMIT_HASH/g" $FILE
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "Working on $FILE_BASE...\n"
    cd $FILE_DIR
    if Rscript -e "tinytex::pdflatex('$FILE_BASE')" >/dev/null ; then
      printf "$FILE_BASE successfully built!\n"
      mv $FILE_PREFIX.pdf $WEBSITE_DIR
      printf "$FILE_PREFIX.pdf moved to $WEBSITE_DIR\n"
    else
      printf "\nTinyTeX encountered some sort of error building $FILE_BASE\n"
    fi
    cd $TRANSLATIONS_DIR
  done
else
  printf "Skipping all .tex files\n"
fi
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
printf "Finished building all LaTeX translations!\n"
printf "All PDF files moved to $WEBSITE_DIR!\n"


######################
# Build Quarto files #
######################

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
if ! [ -z "$QUARTO_FILES" ] ; then
  printf "Building .qmd files\n"
  cd $QUARTO_DIR
  for FILE in $QUARTO_FILES ; do
    FILE_DIR=$(dirname $FILE)
    FILE_BASE=$(basename $FILE)
    FILE_PREFIX=${FILE_BASE%.*}
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "Working on $FILE_BASE...\n"
    cd $FILE_DIR
    if quarto render $FILE_BASE >/dev/null ; then
      printf "$FILE_BASE successfully built!\n"
      mv $QUARTO_OUTPUT_DIR/$FILE_PREFIX.html $WEBSITE_DIR
      mv $QUARTO_OUTPUT_DIR/$FILE_PREFIX.pdf $WEBSITE_DIR
      printf "$FILE_PREFIX.pdf moved to $WEBSITE_DIR\n"
    else
      printf "\nQuarto encountered some sort of error building $FILE_BASE\n"
    fi
    cd $TRANSLATIONS_DIR
  done
else
  printf "Skipping all .qmd files\n"
fi

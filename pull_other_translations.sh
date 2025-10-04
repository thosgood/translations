#!/bin/bash

LOCAL_DIR=~/other_translations
PUBLIC_DIR=/var/www/translations.thosgood.net

declare -a dirs=("sga" "fga" "hodge-theory" "minus-three-points")

for i in "${dirs[@]}"
do
  printf "Working on $i\n"
  cd $LOCAL_DIR/$i
  git reset --hard
  git clean -df
  git checkout build
  git pull

  if [ -d $PUBLIC_DIR/$i ]; then rm -r $PUBLIC_DIR/$i; fi
  cp -r $LOCAL_DIR/$i $PUBLIC_DIR
  rm -rf $PUBLIC_DIR/$i/.git
  printf "\n"
done

See <https://thosgood.com/translations> for details.

### To-do

- add end marker to `itenv` and `rmenv`
- spacing after `itenv` and `rmenv`...
- change version code to git commit number

### Server code

```bash
#!/bin/bash

TRANSLATIONS_DIR=~/translations

cd $TRANSLATIONS_DIR
git fetch
NEW=$(git diff --name-only master origin/master)
if [ -z "$NEW" ]; then
  echo "no changes"
else
  echo "Here are the .tex files that have changed:"
  files=`git diff --name-only master origin/master | grep -E '.tex$' `
  git pull
  cd $TRANSLATIONS_DIR/builds
  for file in $files; do
    BASE=${file##*/}
    PREF=${BASE%.*}
    cp $TRANSLATIONS_DIR/$file ./$BASE && echo $BASE && shpdflatex.sh $BASE && cp $PREF.pdf /var/www/labs.thosgood.com/builds
  done
  rm $TRANSLATIONS_DIR/builds/*
fi
```

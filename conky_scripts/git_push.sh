#!/bin/sh

echo "Pushing Conky widgets and scripts to github repo"

params=""
for element in "$@"
do
	params="$params $element"
done

cd ~/.conky/MHz_conky_widgets/
git fetch && git status
git add .
git commit -m "$params"
git push

echo "Pushed Conky widgets and scripts to github repo"

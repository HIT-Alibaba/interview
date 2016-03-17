#!/bin/sh
git add -A
git commit -am "update `date`"
git push
if which gitbook > /dev/null; then
    cd source
    gitbook build
    cd _book
    cp -R * ../../../interview-gitbook/
    cd ../../../interview-gitbook/
    git add -A
    git commit -am "update `date`"
    git push
else
    echo "Gitbook not installed."
fi

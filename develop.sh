#!/bin/sh
cd ..
mkdir interview-gitbook
cd interview-gitbook
git init
git remote add origin https://github.com/monsterLin/interview.git
git fetch
git checkout gh-pages
cd ../interview
cd source
gitbook install
cd ..


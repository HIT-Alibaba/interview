#!/bin/sh
cd ..
mkdir interview-gitbook
cd interview-gitbook
git init
git remote add origin git@github.com:HIT-Alibaba/interview.git
git fetch
git checkout gh-pages
cd ../interview

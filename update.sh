cd source
gitbook build
cd _book
cp -R * ../../../interview-gitbook/
cd ../../interview-gitbook/
git add -A
git commit -am "update"
git push

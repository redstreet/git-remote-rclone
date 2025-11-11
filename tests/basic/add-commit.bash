#!/usr/bin/bash

info() {
  echo -e "\n\n---------------- $1 ------------"
}


SANDBOX=$HOME/gnu/SANDBOX

info "Creating local repo"
cd $SANDBOX/testrepo
date >> xyz
git add .
git commit -m "."
git push origin
git show-ref
echo ""
echo "git fetch origin, then show-ref again:"
git fetch origin
git show-ref

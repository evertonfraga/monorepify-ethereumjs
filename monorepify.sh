#!/bin/bash

# exit when any command fails
set -e

# Saving current directory
CWD=`pwd`
MONOREPO="$CWD/ethereumjs-vm"

# List of repos we want to bring in
EXTERNAL_REPOS="account block blockchain tx"
ALL_REPOS="$EXTERNAL_REPOS vm"

# Migrating repos preserving their git history
# Based on: https://medium.com/@filipenevola/how-to-migrate-to-mono-repository-without-losing-any-git-history-7a4d80aa7de2
# 
# 1. copy repos
  # 1.1 Clone from original repos
  echo "Cloning all repos... "
  for REPO in $ALL_REPOS
  do
    git clone git@github.com:ethereumjs/ethereumjs-$REPO.git
  done

  # Doing changes in an own fork. TODO: Change to ethereumjs when it comes the time
  # git clone git@github.com:evertonfraga/ethereumjs-vm.git
  echo "OK"

  # 1.2 Destination repo, monorepo-1 branch
  echo -n "Creating branch monorepo... "
  cd $MONOREPO && git checkout -b monorepo
  cd $CWD

  # 1.3 Create subdirectories for each repo
  echo "Moving each repo to a subdirectory..."
  for REPO in $ALL_REPOS
  do
    mkdir -p ethereumjs-$REPO/packages/$REPO
  done
  echo "OK"

  # 1.4 Moving each repo to a subdirectory
  echo -n "Moving all files 1 directory deeper..."
  for REPO in $ALL_REPOS
  do
    cd $CWD/ethereumjs-$REPO
    ls -A1 | grep -Ev "^(packages|\.git)$" | xargs -I{} git mv {} packages/$REPO
    git commit -m "monorepo: moving $REPO"
  done
  echo "OK"

  # 1.5 Adding other directories as remote
  # no need to add VM here, as it is self
  echo -n "Adding other directories as remote..."
  cd $MONOREPO
  
  for REPO in $EXTERNAL_REPOS
  do
    git remote add $REPO $CWD/ethereumjs-$REPO/
  done
  echo "OK"

  # 1.6 pulling new remotes from other local repos
  git fetch --all

  # 1.7 merging "remote" repos in monorepo
  echo "Merging other repos to monorepo..."

  for REPO in $EXTERNAL_REPOS
  do
    git merge $REPO/master --no-edit --allow-unrelated-histories
  done
  echo "OK"

# 2. Handle files under ./.github
  echo "Handle files under ./.github..."
  cd $MONOREPO

  # 2.1 Move vm/.github to root 
  echo "Move vm/.github to root..."
  git mv packages/vm/.github/ .github
  echo "OK"

  # 2.2 Move all .yml files to root
  # TODO: Remove -k from `git mv`
  # at this point there's no yaml file on master, so I'm using -k to suppress errors
  echo "Move all .yml files to root..."
  git mv -k packages/*/.github/*.yml .github
  echo "OK"

  # 2.3 Remove packages' github dir (and their remaining contributing.md)
  git rm -rf packages/*/.github

  git commit -m 'monorepo: Unifying .github files'
  echo "OK"


# Final checks
for REPO in $ALL_REPOS
do
  cd $CWD/ethereumjs-$REPO
  echo "Commits in $REPO: `git rev-list --count HEAD`"
done


# Tearing down local origins
  echo -n "Tears down remotes..."
  cd $MONOREPO
  for REPO in $EXTERNAL_REPOS
  do
    git remote remove $REPO
  done
  echo "OK"


# 3. TODO: Changing all link references to the new repo and file structure

  # 3.1 Change repo name 
  # As a commit is pinned, it is OK to keep the file structure
  # Input:  https://github.com/ethereumjs/ethereumjs-tx/blob/5c81b38/src/types.ts#L8
  # Output: https://github.com/ethereumjs/ethereumjs-vm/blob/5c81b38/src/types.ts#L8

  # 3.2 Change file structure for links pointing to `master`
  # Input:    https://github.com/ethereumjs/ethereumjs-block/blob/master/docs/index.md
  # Output-2: https://github.com/ethereumjs/ethereumjs-vm/blob/master/docs/index.md
  # Output-1: https://github.com/ethereumjs/ethereumjs-vm/blob/master/package/block/docs/index.md

  # 3.3 Commit changes




# implement lerna
# merge vscode
# merge prettier
# deal with tsconfig
# deal with tslint
# make sure CHANGELOG can still be generated
# Update link references on all .MD files

#  124  Account
#  253  Block
#  232  Blockchain
#  466  TX
# 1341  VM

# 124 + 253 + 232 + 466 + 1341
# = 2416
# 9

#!/bin/bash

# exit when any command fails
set -e

# Saving current directory
CWD=`pwd`
MONOREPO="$CWD/ethereumjs-vm"

# Log function
GREEN="\033[0;32m"
NOCOLOR="\033[0m"
info() {
  echo -e "${GREEN}INFO: $1 ${NOCOLOR}"
}

# List of repos we want to bring in
EXTERNAL_REPOS="account block blockchain tx common testing"
ALL_REPOS="$EXTERNAL_REPOS vm"

# Migrating repos preserving their git history
# Based on: https://medium.com/@filipenevola/how-to-migrate-to-mono-repository-without-losing-any-git-history-7a4d80aa7de2
# 
# 1. copy repos
  # 1.1 Clone from original repos
  info "Cloning all repos... "
  for REPO in $ALL_REPOS
  do
    git clone git@github.com:ethereumjs/ethereumjs-$REPO.git
  done

  # TODO: REMOVE WHEN GH ACTIONS PR ARE MERGED
  cd $CWD/ethereumjs-account && git pull origin github-actions
  # cd $CWD/ethereumjs-block && git checkout github-actions
  cd $CWD/ethereumjs-blockchain && git pull origin github-actions
  # cd $CWD/ethereumjs-tx && git checkout github-actions
  # cd $CWD/ethereumjs  -vm && git checkout github-actions
  # END-TODO

  # Doing changes in an own fork. TODO: Change to ethereumjs when it comes the time
  # git clone git@github.com:evertonfraga/ethereumjs-vm.git
  # info "OK"

  # 1.2 Destination repo, monorepo branch
  info "Creating branch monorepo... "
  cd $MONOREPO && git checkout -b monorepo-1
  cd $CWD

  # 1.4 Moving each repo to a subdirectory
  info "Moving all files 1 directory deeper..."
  for REPO in $ALL_REPOS
  do
    mkdir -p $CWD/ethereumjs-$REPO/packages/$REPO
    cd $CWD/ethereumjs-$REPO
    ls -A1 | grep -Ev "^(packages|\.git)$" | xargs -I{} git mv {} packages/$REPO
    git commit -m "monorepo: moving $REPO"
  done
  info "OK"

  # 1.5 Adding other directories as remote
  # no need to add VM here, as it is self
  info "Adding other directories as remote..."
  cd $MONOREPO
  
  for REPO in $EXTERNAL_REPOS
  do
    git remote add $REPO $CWD/ethereumjs-$REPO/
  done
  info "OK"

  # 1.6 pulling new remotes from other local repos
  git fetch --all

  # 1.7 merging "remote" repos in monorepo
  info "Merging other repos to monorepo..."

  for REPO in $EXTERNAL_REPOS
  do
    info "Merging ethereumjs-$REPO"
    git merge $REPO/master --no-edit --allow-unrelated-histories
  done
  info "OK"

# 2. Handle files under ./.github
  info "Handle files under ./.github..."
  cd $MONOREPO

  # 2.1 Move vm/.github to root 
  info "Move vm/.github to root..."
  git mv packages/vm/.github/ .github
  info "OK"

  # 2.2 Move all .yml files to root
  # TODO: Remove -k from `git mv`
  # at this point there's no yaml file on master, so I'm using -k to suppress errors
  info "Move all .yml files to root..."
  git mv -k packages/*/.github/*.yml .github
  info "OK"

  # 2.3 Remove packages' github dir (and their remaining contributing.md)
  info "Move all .yml files to root..."
  git rm -rf packages/*/.github

  git commit -m 'monorepo: Unifying .github files'
  info "OK"


# Final checks
for REPO in $ALL_REPOS
do
  cd $CWD/ethereumjs-$REPO
  info "Commits in $REPO: `git rev-list --count HEAD`"
done


# Tearing down local origins
  info "Tears down remotes..."
  cd $MONOREPO
  for REPO in $EXTERNAL_REPOS
  do
    git remote remove $REPO
  done
  info "OK"


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

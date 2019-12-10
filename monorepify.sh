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
  echo -e "${GREEN}$1 ${NOCOLOR}"
}

# List of repos we want to bring in
EXTERNAL_REPOS="account block blockchain tx common"
ALL_REPOS="$EXTERNAL_REPOS vm"

# Migrating repos preserving their git history
# Based on: https://medium.com/@filipenevola/how-to-migrate-to-mono-repository-without-losing-any-git-history-7a4d80aa7de2
# 
# 1. copy repos
  # 1.1 Clone from original repos
  info "Cloning all repos... "
  for REPO in $ALL_REPOS
  do
    git clone git@github.com:ethereumjs/ethereumjs-$REPO.git --single-branch
  done

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
  mkdir -p .github/workflows

  # 2.2 Move all .yml files to root
  info "Move all .github files to root..."
  git mv packages/vm/.github/contributing.md .github/
  git mv packages/*/.github/workflows/* .github/workflows

  # 2.3 Remove packages' github dir (with their remaining contributing.md)
  info "Remove packages' github dir..."
  git rm -rf packages/*/.github --ignore-unmatch

  info "Committing github changes..."
  git commit -m 'monorepo: Moving .github files to root'
  info "Handle files under ./.github: DONE"

# 3. Inject paths to ignore for each job, so we don't run out of job runners

  info "Making test cascade changes..."
  cd $CWD
  node make-test-cascade.js  
  
  cd $MONOREPO
  git commit .github/workflows -m 'monorepo: Adding test cascade directives'
  info "OK"







# 4. TODO: Changing all link references to the new repo and file structure

  # 4.1 Change repo name 
  # As a commit is pinned, it is OK to keep the file structure
  # Input:  https://github.com/ethereumjs/ethereumjs-tx/blob/5c81b38/src/types.ts#L8
  # Output: https://github.com/ethereumjs/ethereumjs-vm/blob/5c81b38/src/types.ts#L8

  # 4.2 Change file structure for links pointing to `master`
  # Input:    https://github.com/ethereumjs/ethereumjs-block/blob/master/docs/index.md
  # Output-2: https://github.com/ethereumjs/ethereumjs-vm/blob/master/docs/index.md
  # Output-1: https://github.com/ethereumjs/ethereumjs-vm/blob/master/package/block/docs/index.md

  # 3.3 Commit changes


# TODO: 
# implement lerna
# merge vscode
# merge prettier
# deal with tsconfig
# deal with tslint
# make sure CHANGELOG can still be generated
# Update link references on all .MD files
# Update link references to the project badges
# Update link references to package.json

# Tearing down local origins
  info "Tears down remotes..."
  cd $MONOREPO
  git remote remove origin
  for REPO in $EXTERNAL_REPOS
  do
    git remote remove $REPO
  done
  info "OK"

# Convenience. TODO: remove
git remote add ev git@github.com:evertonfraga/ethereumjs-vm.git


# Final checks
for REPO in $ALL_REPOS
do
  cd $CWD/ethereumjs-$REPO
  info "Commits in $REPO: `git rev-list --count HEAD`"
done

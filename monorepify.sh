#!/bin/bash

# immediately exits when a command fails
set -e

setup_global_vars() {
  # Saving current directory
  CWD=`pwd`
  MONOREPO="$CWD/ethereumjs-vm"

  # List of repos we want to bring in
  EXTERNAL_REPOS="account block blockchain tx common"
  ALL_REPOS="$EXTERNAL_REPOS vm"
}

# Logging function
info() {
  GREEN="\033[0;32m"
  NOCOLOR="\033[0m"
  echo -e "${GREEN}$1 ${NOCOLOR}"
}

migrate_repos() {
  # Based on:
  # https://medium.com/@filipenevola/how-to-migrate-to-mono-repository-without-losing-any-git-history-7a4d80aa7de2

  info "1. Cloning all repos..."
  for REPO in $ALL_REPOS
  do
    git clone git@github.com:ethereumjs/ethereumjs-$REPO.git --single-branch
  done


  info "2. Creating branch monorepo..."
  cd $MONOREPO && git checkout -b monorepo


  info "3. Moving all files to /package/<name>."
  cd $CWD
  for REPO in $ALL_REPOS
  do
    mkdir -p $CWD/ethereumjs-$REPO/packages/$REPO
    cd $CWD/ethereumjs-$REPO
    ls -A1 | grep -Ev "^(packages|\.git)$" | xargs -I{} git mv {} packages/$REPO
    git commit -m "monorepo: moving $REPO"
  done


  info "4. Renaming tags..."
  COUNTER=1
  for REPO in $ALL_REPOS
  do
    info "4.$COUNTER Renaming tags from ethereumjs-$REPO"
    cd $CWD/ethereumjs-$REPO

    # Remove prefix `v` from tags
    # Input:  v1.0.2
    # Output: 1.0.2
    git tag -l | grep -E "^v" | sed -e "s/^v//" | xargs -I{} git tag {} v{}
    # Remove tags with `v` prefix
    git tag -l | grep -E "^v" | xargs -I{} git tag -d {}

    # Implements new tag format
    # Input:  1.0.2
    # Output: @ethereumjs/vm@1.0.2
    git tag -l | grep -E "^\d+\.\d+\.\d+" | xargs -I{} git tag @ethereumjs/$REPO@{} {}
    # Remove tags in the old format
    git tag -l | grep -E "^\d+\.\d+\.\d+" | xargs -I{} git tag -d {}

    ((COUNTER+=1))
  done


  info "5. Adding other directories as remote..."
  # no need to add VM here, as it is self
  cd $MONOREPO  
  for REPO in $EXTERNAL_REPOS
  do
    git remote add $REPO $CWD/ethereumjs-$REPO/
  done
  info "OK"


  info "6. Setting up git remotes from local files..."
  # Removing origin 
  git remote remove origin
  # Fetching all new repos from local paths
  git fetch --all
  # Adding a destination for the monorepo, ignoring its tags for now
  git remote add ev git@github.com:evertonfraga/ethereumjs-vm.git


  info "7. Merging other repos to monorepo..."
  for REPO in $EXTERNAL_REPOS
  do
    info "Merging ethereumjs-$REPO"
    git merge $REPO/master --no-edit --allow-unrelated-histories
  done
  info "OK"
}

migrate_github_files() {
  info "Migrate Github Files: START"
  cd $MONOREPO

  info "1. Handle files under ./.github..."
  mkdir -p .github/workflows

  info "2. Move all .github files to root..."
  git mv packages/vm/.github/contributing.md .github/
  git mv packages/*/.github/workflows/* .github/workflows

  info "3. Remove packages' github dir..."
  git rm -rf packages/*/.github --ignore-unmatch # also deletes remaining contributing.md files

  info "4. Committing github changes..."
  git commit -m 'monorepo: Moving .github files to root'

  info "5. Making cascade tests changes..."
  # context: https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
  cd $CWD
  node make-test-cascade.js  
  
  cd $MONOREPO
  git commit .github/workflows -m 'monorepo: Adding test cascade directives'

  info "Migrate Github Files: OK"
}

tear_down_remotes() {
  info "Tear down remotes..."
  for REPO in $EXTERNAL_REPOS
  do
    git remote remove $REPO
  done
  info "OK"
}

update_link_references() {
  # Changing all link references to the new repo and file structure

  # 4.1 Change repo name 
  # As a commit is pinned, it is OK to keep the file structure
  # Input:  https://github.com/ethereumjs/ethereumjs-tx/blob/5c81b38/src/types.ts#L8
  # Output: https://github.com/ethereumjs/ethereumjs-vm/blob/5c81b38/src/types.ts#L8

  # 4.2 Change file structure for links pointing to `master`
  # Input:    https://github.com/ethereumjs/ethereumjs-block/blob/master/docs/index.md
  # Output-2: https://github.com/ethereumjs/ethereumjs-vm/blob/master/docs/index.md
  # Output-1: https://github.com/ethereumjs/ethereumjs-vm/blob/master/package/block/docs/index.md
  info "implementation missing."
}

# 
# Execution starts here
# 

setup_global_vars
migrate_repos
migrate_github_files
tear_down_remotes
update_link_references

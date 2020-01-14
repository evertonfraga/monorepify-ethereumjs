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

SECTION=0
ITEM=0

section() {
  ((SECTION+=1))
  ITEM=0
  info "${SECTION}. $1"
}
item() {
  ((ITEM+=1))
  info "${SECTION}.${ITEM}. $1"
}

migrate_repos() {
  # Inspired on:
  # https://medium.com/@filipenevola/how-to-migrate-to-mono-repository-without-losing-any-git-history-7a4d80aa7de2
  
  section "Cloning all repos..."

  for REPO in $ALL_REPOS
  do
    git clone git@github.com:ethereumjs/ethereumjs-$REPO.git --single-branch
  done

  item "Creating branch monorepo..."
  cd $MONOREPO && git checkout -b monorepo

  item "Moving all files to /package/<name>."
  cd $CWD
  for REPO in $ALL_REPOS
  do
    mkdir -p $CWD/ethereumjs-$REPO/packages/$REPO
    cd $CWD/ethereumjs-$REPO
    ls -A1 | grep -Ev "^(packages|\.git)$" | xargs -I{} git mv {} packages/$REPO
    git commit -m "monorepo: moving $REPO"
  done

  section "Renaming tags..."
  for REPO in $ALL_REPOS
  do
    item "Renaming tags from ethereumjs-$REPO"
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

  done


  section "Adding other directories as remote..."
  # no need to add VM here, as it is self
  cd $MONOREPO  
  for REPO in $EXTERNAL_REPOS
  do
    git remote add $REPO $CWD/ethereumjs-$REPO/
  done
  info "OK"


  section "Setting up git remotes from local files..."
  # Fetching all new repos from local paths
  git fetch --all
  # Adding a destination for the monorepo, ignoring its tags for now
  git remote add ev git@github.com:evertonfraga/ethereumjs-vm.git


  section "Merging other repos to monorepo..."
  for REPO in $EXTERNAL_REPOS
  do
    item "Merging ethereumjs-$REPO"
    git merge $REPO/master --no-edit --allow-unrelated-histories
  done
  info "OK"
}

move_github_files() {
  section "Move Github Files: START"
  cd $MONOREPO

  item "Handle files under ./.github..."
  mkdir -p .github/workflows

  item "Move all .github files to root..."
  git mv packages/vm/.github/contributing.md .github/
  git mv packages/vm/.github/labeler.yml .github/
  git mv packages/*/.github/workflows/* .github/workflows

  item "Remove packages' github dir..."
  git rm -rf packages/*/.github --ignore-unmatch # also deletes remaining contributing.md files

  item "Committing github changes..."
  git commit -m 'monorepo: Moving .github files to root'
  info "Move Github Files: OK"
}

make_tests_cascade() {
  section "Making cascade tests changes..."
  # context: https://github.com/ethereumjs/ethereumjs-vm/issues/561#issuecomment-558943311
  cd $CWD
  node gh-actions-make-cascade-tests.js
  
  cd $MONOREPO
  git commit .github/workflows -m 'monorepo: Adding test cascade directives'
}

fix_cwd_github_files() {
  section "Fix github actions execution paths"

  cd $CWD
  node gh-actions-adjust-paths.js
  
  cd $MONOREPO
  git commit .github/workflows -m 'monorepo: Fixing execution paths for github actions'

  info "Fix github actions execution paths: OK"
}

tear_down_remotes() { 
  # That's for additional safety while developing
  section "Tear down remotes..."
  cd $MONOREPO

  for REPO in $EXTERNAL_REPOS
  do
    git remote remove $REPO
  done
  info "OK"
}

# Changing all link references to the new repo and file structure
update_link_references() {
  section "Update link references"
  cd $MONOREPO

  # Docs contain several github links referencing classes and methods.
  # They need to be updated to the new file structure and repo name
  item "Updating docs links"
  for REPO in $ALL_REPOS
  do
    info "Link updates for ${REPO}"
    cd $MONOREPO/packages/$REPO
    npm install

    # docs:build needs to have a proper git origin set, so it generates absolute urls correctly
    npm run docs:build
  done

  git commit packages/ -m 'Generating docs with updated urls'

  item "Link updates: changing repo names"
  # When a commit is pinned, it is OK to keep the file structure
  # Input:  https://github.com/ethereumjs/ethereumjs-tx/blob/5c81b38/src/types.ts#L8
  # Output: https://github.com/ethereumjs/ethereumjs-vm/blob/5c81b38/src/types.ts#L8

  item "Link updates: changing file structure"
  # Change file structure for links pointing to `master`
  # Input:    https://github.com/ethereumjs/ethereumjs-block/blob/master/docs/index.md
  # Output-2: https://github.com/ethereumjs/ethereumjs-vm/blob/master/docs/index.md
  # Output-1: https://github.com/ethereumjs/ethereumjs-vm/blob/master/package/block/docs/index.md

  item "Link updates: Changelog tag links"
  # Links for comparison across tags, found on CHANGELOG
  # Characters @ and / present on the new tag name format need to be escaped (%40 and %2F respectively)
  # Input: https://github.com/ethereumjs/ethereumjs-block/compare/v2.2.0...v2.2.1
  # Output: https://github.com/ethereumjs/ethereumjs-vm/compare/%40ethereumjs%2Fblock%402.2.0...%40ethereumjs%2Fblock%402.2.1) 
  # Note: sed syntax has some differences among OSes. This command was created targeting MacOS and might fail in Linux
  sed -E -e 's|(https://github.com/ethereumjs/ethereumjs-)([a-z]+)/compare/v?(.{5})...v?(.{5})|\1vm/compare/%40ethereumjs%2F\2%40\3...%40ethereumjs%2F\4|' -ibak */**/CHANGELOG.md
  git commit -am 'Updating tag comparison links in CHANGELOG'

  # Cleaning backup files produced by sed
  git clean -f 
}

lerna_init() {
  section "Lerna Init"
  cd $MONOREPO
  npx lerna init
  git add package.json lerna.json
  git commit -m 'Lerna'
}


# 
# Execution starts here
# 

setup_global_vars
migrate_repos
migrate_github_files
fix_cwd_github_files
tear_down_remotes
update_link_references
lerna_init

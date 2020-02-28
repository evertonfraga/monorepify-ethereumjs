#!/bin/bash

# immediately exits when a command fails
set -e

# prints commands prior to execution
set -o xtrace

setup_global_vars() {
  # Saving current directory
  CWD=`pwd`
  MONOREPO="$CWD/ethereumjs-vm"

  # List of repos we want to bring in
  EXTERNAL_REPOS="account block blockchain tx common"

  # Includes destination repo
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
rename_to_scoped_packages() {
  # Renames all references in package.json to their scoped version.
  section "Migrating to scoped packages"

  # DRY - Transforms package names list in Regex search
  # Input: "account block tx"
  # Output: "account|block|tx"
  PIPED_REPOS=`echo $ALL_REPOS | sed -e 's/ /|/g'`

  sed -E -e "s/\"ethereumjs-($PIPED_REPOS)\"/\"@ethereumjs\/\1\"/g" -ibak packages/*/package.json

  git commit -am 'Renaming packages to their scoped version @ethereumjs/<package>'
  git clean -f
}
rename_to_scoped_packages

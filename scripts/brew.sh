#!/usr/bin/env zsh
# Installation script for Homebrew packages
# Author: Yuzhou "Joe" Mo (@yuzhoumo)
# License: GNU GPLv3

casks=(
  # High priority
  bitwarden
  firefox
  eloston-chromium
  synology-drive
  signal
  discord
  slack
  kitty
  obsidian

  # Medium priority
  protonvpn
  spotify
  thunderbird
  protonmail-bridge
  ledger-live
  zoom
  figma

  # Low priority
  visual-studio-code
  tor-browser
  flux
  lulu
  vlc
  rectangle
  deluge
  imageoptim
  keka
  libreoffice
  android-platform-tools
)

cli=(
  bash
  openssh
  ffmpeg
  gh
  git
  gnupg
  htop
  neovim
  nvm
  openjdk
  tmux
  tree
  wget
  youtube-dl
)

pueue_group="brew_install"

set -e # Exit if any command fails

# Cleanup function
finish() {
  if pueue >/dev/null 2>&1; then
    pueue reset
    pueue group | grep "${pueue_group}" > /dev/null &&
      pueue group remove "${pueue_group}"
  fi
}
trap finish EXIT

# Trigger exit on interrupt
ctrlc() {
  printf "Exiting...\n"
  exit
}
trap ctrlc INT

# Ask for the administrator password upfront
sudo --validate

# Keep-alive: update existing `sudo` time stamp until `brew.sh` has finished
while true; do sudo --non-interactive true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Check to see if Homebrew is installed, and install it if it is not
command -v brew >/dev/null 2>&1 || /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Pre-install tasks
brew analytics off
printf "Tapping homebrew/cask-drivers...\n"
brew tap homebrew/cask-drivers # Needed for synology-drive
printf "Upgrading any already-installed formulae...\n"
brew upgrade

# Install pueue if not already installed
command -v pueue >/dev/null 2>&1 || brew install pueue || exit

# Start pueue in background if it isn't already running
pueue >/dev/null 2>&1 || pueued --daemonize

# Save set of already-installed packages
declare -A already_installed && \
  for i in $(brew list); do already_installed["$i"]=1; done

# Set to 1 if any cask/cli package needs to be installed
cli_flag=0; cask_flag=0

# Setup pueue group for install tasks
pueue group add "${pueue_group}"

# Parallelize 4 processes at once
pueue parallel 4 --group "${pueue_group}"

printf "Installing casks...\n"

# Install casks in parallel
for app_name in "${casks[@]}"; do
  if [[ "${already_installed["$app_name"]}" -ne 1 ]]; then
    pueue add -g "${pueue_group}" "brew install --cask $app_name"
    cask_flag=1
  else
    printf "Package already installed: %s\n" "${app_name}"
  fi
done

printf "Fetching cli packages...\n"

# Fetch cli packages in parallel (defer install to happen serially)
for app_name in "${cli[@]}"; do
  if [[ "${already_installed["$app_name"]}" -ne 1 ]]; then
    pueue add -g "${pueue_group}" "brew fetch $app_name"
    cli_flag=1
  else
    printf "Package already installed: %s\n" "${app_name}"
  fi
done

# Wait on pueue group if anything was fetched/installed
if [[ "$cli_flag" -eq 1 || "$cask_flag" -eq 1 ]]; then
  sleep 3 && pueue status
  pueue wait -g "${pueue_group}"
fi

printf "Installing cli packages...\n"

# Install cli packages serially (prevent conflicting dependencies)
for app_name in "${cli[@]}"; do
  [[ "${already_installed["$app_name"]}" -ne 1 ]] && \
    brew install "${app_name}"
done

# Disable "Are you sure you want to open..." dialog on installed casks
[[ "$cask_flag" -eq 1 ]] && \
  printf "Disabling Gatekeeper quarantine on all installed applications...\n"; \
  sudo xattr -dr com.apple.quarantine /Applications 2>/dev/null

printf "Cleanup brew...\n"
brew cleanup

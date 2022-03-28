#!/usr/bin/env zsh
# Additional configs for macOS after package installation
# by Yuzhou (Joe) Mo <joe.mo@berkeley.edu>
# License: GNU GPLv3

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `macos.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Navigate to current directory
cd "$(dirname "$0")"

###############################################################################
# Personalization                                                             #
###############################################################################

# Set desktop wallpaper
echo 'Setting desktop wallpaper...'
cp ../assets/images/wallpaper.jpg ${HOME}/Pictures/wallpaper.jpg
osascript -e "tell application \"Finder\" to set desktop picture to \
  \"${HOME}/Pictures/wallpaper.jpg\" as POSIX file"

# Set profile picture
# https://apple.stackexchange.com/questions/117530#367667
echo 'Setting user profile picture...'
cp ../assets/images/profile.png "${HOME}/Pictures/profile.png"
printf "%s %s \n%s:%s" "0x0A 0x5C 0x3A 0x2C" \
  "dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName" \
  "externalbinary:dsAttrTypeStandard:JPEGPhoto" \
  "${USERNAME}" "${HOME}/Pictures/profile.png" > dsimport.tmp 
sudo /usr/bin/dsimport dsimport.tmp /Local/Default M; rm dsimport.tmp

# Set default browser to Firefox
echo 'Setting default browser...\n'
brew install defaultbrowser
defaultbrowser firefox
brew uninstall defaultbrowser 

# Set Finder favorites
echo '\nSetting favorites in Finder sidebar...\n'
brew install mysides
mysides remove Recents > /dev/null
mysides remove Documents > /dev/null
mysides add home file://$HOME > /dev/null
mysides add Desktop file://$HOME/Desktop > /dev/null
mysides add Downloads file://$HOME/Downloads > /dev/null
mysides add Applications file:///Applications > /dev/null
mysides add AirDrop nwnode://domain-AirDrop > /dev/null
brew uninstall mysides

###############################################################################
# Configure Development Environment                                           #
###############################################################################

# Configure global git config
git config --global user.email "49494600+yuzhoumo@users.noreply.github.com"
git config --global user.name "Joe Mo"

# TODO: Setup Code folder and pull git repositories
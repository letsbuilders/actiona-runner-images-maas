#!/bin/bash -e
################################################################################
##  File:  install-firefox.sh
##  Desc:  Install Firefox
################################################################################

# Source the helpers for use with the script
source "$HELPER_SCRIPTS/install.sh"
source "$HELPER_SCRIPTS/os.sh"
source $HELPER_SCRIPTS/etc-environment.sh

# Mozillateam PPA is added manually because sometimes
# lanuchad portal sends empty answer when trying to add it automatically

repo_url="http://ppa.launchpad.net/mozillateam/ppa/ubuntu"
gpg_fingerprint="0ab215679c571d1c8325275b9bdb3d89ce49ec21"
gpg_key="/etc/apt/trusted.gpg.d/mozillateam_ubuntu_ppa.gpg"
repo_path="/etc/apt/sources.list.d/mozillateam-ubuntu-ppa-focal.list"

# Install Firefox
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${gpg_fingerprint}" | sudo gpg --dearmor -o $gpg_key
echo "deb $repo_url $(get_os_version_label) main" > $repo_path

apt-get update
apt-get install --target-release 'o=LP-PPA-mozillateam' -y firefox
rm $repo_path

# Document apt source repo's
echo "mozillateam $repo_url" >> $HELPER_SCRIPTS/apt-sources.txt

# add to gloabl system preferences for firefox locale en_US, because other browsers have en_US local.
# Default firefox local is en_GB
echo 'pref("intl.locale.requested","en_US");' >> "/usr/lib/firefox/browser/defaults/preferences/syspref.js"

# Download and unpack latest release of geckodriver
download_url=$(resolve_github_release_asset_url "mozilla/geckodriver" "test(\"linux64.tar.gz$\")" "latest")
driver_archive_path=$(download_with_retry "$download_url")

GECKODRIVER_DIR="/usr/local/share/gecko_driver"
GECKODRIVER_BIN="$GECKODRIVER_DIR/geckodriver"

mkdir -p $GECKODRIVER_DIR
tar -xzf "$driver_archive_path" -C $GECKODRIVER_DIR

chmod +x $GECKODRIVER_BIN
ln -s "$GECKODRIVER_BIN" /usr/bin/
set_etc_environment_variable "GECKOWEBDRIVER" "${GECKODRIVER_DIR}"

invoke_tests "Browsers" "Firefox"

#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server
#
# This script was built using Debian 11 OpenVZ server
# This script will download and install Steam Server, Sourcemod, Metamod, and compile and install War3Source-EVO for CSS
# You should install using a SUDO USER and not root user for security purposes.
# SUDO is needed for apt-get install and for getting the public ip address for this server via ifconfig.
#
## just in case someone removed the defaults.
if [ "${STEAM_USER}" == "" ]; then
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
fi

## download and install steamcmd
cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd
mkdir -p /mnt/server/steamapps # Fix steamcmd disk write error when this folder is missing
cd /mnt/server/steamcmd

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
chown -R root:root /mnt
export HOME=/mnt/server

## install game using steamcmd
./steamcmd.sh +force_install_dir /mnt/server +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +app_update ${SRCDS_APPID} ${EXTRA_FLAGS} +quit ## other flags may be needed depending on install. looking at you cs 1.6

## set up 32 bit libraries
mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

## set up 64 bit libraries
mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so
cd /mnt/server/

# ----- WC3 MODDING ------------------------------------------------

#    CSS - 232330
#    CSGO - 740
#    FOF - 295230
#    TF2 - 232250
#    L4D - 222840
#    L4D2 - 222860

serverAPPid="740"

# Game switcher for War3Source-EVO compiling
GAME_SWITCHER="CSGO"

SourceMetaModWar3InstallPath="./csgo"

sudo apt-get update
sudo dpkg --add-architecture i386
sudo apt-get install git
sudo apt-get install tar
sudo apt-get install screen
sudo apt-get install nano
sudo apt-get install lib32gcc1
sudo apt-get install lib32gcc-s1
sudo apt-get install lib32stdc++6
sudo apt-get install libc6-i386
sudo apt-get install linux-libc-dev:i386

sudo apt-get install clang
sudo apt-get install lib32z1
sudo apt-get install libbz2-1.0:i386
sudo apt-get install libncurses5:i386
sudo apt-get install libtinfo5:i386
sudo apt-get install libcurl3-gnutls:i386
sudo apt-get install libsdl2-2.0-0:i386
sudo apt-get install libc6-dev-i386


# git clone War3Source
git clone https://github.com/War3Evo/War3Source-EVO.git
cp -vrf ./War3Source-EVO/cfg "${SourceMetaModWar3InstallPath}"

cp -vrf ./War3Source-EVO/addons "${SourceMetaModWar3InstallPath}"
cp -vrf ./War3Source-EVO/sound "${SourceMetaModWar3InstallPath}"
rm -rf ./War3Source-EVO

# Get SourceMod Required to compile War3Source-EVO
wget "http://www.sourcemod.net/latest.php?version=1.9&os=linux" -O "${SourceMetaModWar3InstallPath}/sourcemod-1.9-linux.tar.gz"
tar -zxvf "${SourceMetaModWar3InstallPath}/sourcemod-1.9-linux.tar.gz" --directory "${SourceMetaModWar3InstallPath}"

# Extract SourceMod as List
tar --list -f "${SourceMetaModWar3InstallPath}/sourcemod-1.9-linux.tar.gz" > "${SourceMetaModWar3InstallPath}/smlist19.txt"


#
# COMPILE WAR3SOURCE-EVO
#
# Give spcomp the required permissions
chmod a+x "${SourceMetaModWar3InstallPath}/addons/sourcemod/scripting/spcomp_1.9.0.6261"
chmod a+x "${SourceMetaModWar3InstallPath}/addons/sourcemod/scripting/game_switcher_${GAME_SWITCHER}.sh"
chmod a+x "${SourceMetaModWar3InstallPath}/addons/sourcemod/scripting/compile_for_github_action.sh"
bash -c "${SourceMetaModWar3InstallPath}/addons/sourcemod/scripting/game_switcher_${GAME_SWITCHER}.sh"
bash -c "${SourceMetaModWar3InstallPath}/addons/sourcemod/scripting/compile_for_github_action.sh" || true

# Clean up & Remove SM 1.9
xargs rm -f < "${SourceMetaModWar3InstallPath}/smlist19.txt" || true
rm -rf ./War3Source-EVO
rm -rf .github
rm -rf .git

# Download SourceMod
test -e "sourcemod-1.11-linux.tar.gz" ||  wget "http://www.sourcemod.net/latest.php?version=1.11&os=linux" -O sourcemod-1.11-linux.tar.gz

# Extract SourceMod
tar -zxvf sourcemod-1.11-linux.tar.gz --directory "${SourceMetaModWar3InstallPath}"

# Download MetaMod
test -e "metamod-1.11-linux.tar.gz" ||  wget "https://www.metamodsource.net/latest.php?version=1.11&os=linux" -O metamod-1.11-linux.tar.gz

# Extract Metamod
tar --overwrite -zxvf metamod-1.11-linux.tar.gz --directory "${SourceMetaModWar3InstallPath}"

rm metamod-1.11-linux.tar.gz
rm sourcemod-1.11-linux.tar.gz
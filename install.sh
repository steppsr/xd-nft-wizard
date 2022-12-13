#!/bin/bash

##################
# INSTALL SCRIPT #
##################

appdir=`pwd`

# define some colors
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
bldgrn='\e[1;32m' # Bold Green
bldpur='\e[1;35m' # Bold Purple
txtrst='\e[0m'    # Text Reset

echo -e "${bldgrn}"

# Prequisite: jq - check if installed already and if not run the installer
if ! command -v jq &> /dev/null
then
    echo -e "Installing jq..."
    sudo apt install jq
fi

if ! command -v curl &> /dev/null
then
    echo -e "Installing curl..."
    sudo apt install curl
fi

# Create the working folders for the application
echo -e "Installing into $appdir directory..."

[ ! -d "$appdir/files" ] && mkdir "$appdir/files" && echo "${txtrst}files${bldgrn} sub-directory created..."

# Set the script as executable
echo -e "Making the script executable..."
chmod +x ./xdnft.sh

# Add an alias to the .bashrc profile
echo -e "Adding alias for script to user profile ${txtrst}~/.bashrc${bldgrn}..."
echo "" >> ~/.bashrc
echo "alias xdnft=\"bash $appdir/xdnft.sh\"" >> ~/.bashrc
source ~/.bashrc

echo -e "${bldpur}### Install complete! ###${txtrst}"
echo ""
echo ""
echo -e "One final task, please run the following command to reload your user profile:"
echo -e "${bldgrn}source ~/.bashrc${txtrst}"
echo ""
echo ""
echo -e "How to using the script: "
echo -e ""
user=`whoami`
server=`hostname`
echo -e "   $user@$server:$appdir$ ${bldgrn}xdnft${txtrst}"
echo ""
echo -e "${txtrst}"

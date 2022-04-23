#!/bin/bash
# Fail script execution if any function or snippet fails
set -e
source ./shared_funcs.sh

# Adds an empty line
# Args:
# numOfLines: the number of lines to add: Default = 1
#add_empty_line () {
#    local numOfLines=$1
#
#    if [ -z $numOfLines ]; then
#      numOfLines=1
#    fi
#
#    i=0
#    while [ $i -ne $numOfLines ]
#    do
#      i=$(($i+1))
#      echo ""
#    done
#
#}

#show_spinner() {
#    local pid=$!
#    local delay=0.4
#    local spinstr='|/-\'
#    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
#        local temp=${spinstr#?}
#        printf " [%c]  " "$spinstr"
#        local spinstr=$temp${spinstr%"$temp"}
#        sleep $delay
#        printf "\b\b\b\b\b\b"
#    done
#    printf "    \b\b\b\b"
#}

# Executes a command and shows a spinner
# Args:
# command: the command to execute with a spinner
#exec_command_and_show_spinner() {
#  local command=$@
#  # echo "THE COMMAND AND ARGS ARE $command"
#  ("$@") & show_spinner "$!"
#}
#
#backup_file() {
#    BACKED_UP_FILE=
#    local file_to_backup=$1
#    if [ -f "$file_to_backup" ]; then
#        echo "$file_to_backup exists"
#        echo "Backing up $file_to_backup ..."
#        local backup
#
#        if [ -f "${file_to_backup}-orig.bkup" ] ; then
#          backup=$(echo "$file_to_backup" | sed -e "s|$file_to_backup|$file_to_backup-$DATETIME|g")
#          backup="$backup.bkup"
#        else
#          backup="${file_to_backup}-orig.bkup"
#        fi
#
#        echo "Backing up $file_to_backup as $backup"
#        cp -v $file_to_backup $backup
#        BACKED_UP_FILE=$backup
#    else
#        echo "$file_to_backup does not exist. skipping backup"
#    fi
#}

## Finds a line containing a given string in a file and inserts the given new
## after the found line
## Args: $1 = the path to the file to search
##       $2 = the string to search for in the file. Not that this is a regex pattern so you must escape special characters such [ ]
##       and \
##       $3 = the string to insert after the found line
#function insert_after # file line newText
#{
#
#  local file="$1" line="$2" newText="$3"
# # echo "inserting '${newText}' after line  "${line}" in file ${file}"
#
#  if grep -q "${line}" "${file}"; then
#    sed -i -e "/^$line/a"$'\\\n'"$newText"$'\n' "$file"
#  else
#      echo -e "\n${newText}" >> ${file}
#  fi
#}

# Set an environment variable called NIC_CONFIG_FILE with
# the path to the config file of the NIC card to be configured
# Arg1=NIC Name: Name of the NIC card whose
# Arg2=SSID Name: Name of the SSID that Network Manager used to create
#                    the NIC config script
#get_nic_config_file() {
#    local nic_name=$1
#    local ssid_name=$2
#    NIC_CONFIG_FILE=
#    if [ -f "$NIC_CONFIG_BASE_PATH$nic_name" ]; then
#        NIC_CONFIG_FILE=$NIC_CONFIG_BASE_PATH$nic_name
#    elif [ -f "$NIC_CONFIG_BASE_PATH$ssid_name" ]; then
#        NIC_CONFIG_FILE=$NIC_CONFIG_BASE_PATH$ssid_name
#    fi
#}
#
## Deletes a directory if it can
## Arg1=directory_to_delete: the path to the directory
#delete_dir () {
#    local dir_to_delete=$1
#    if [ -d "$dir_to_delete" ]; then
#        echo "Deleting $dir_to_delete ..."
#        rm -rf $dir_to_delete
#        echo "Deleted $dir_to_delete ..."
#    else
#        echo "cannot delete $dir_to_delete. skipping ..."
#    fi
#}

## Installs wget
#install_wget (){
#  echo "Installing wget ..."
#
#  sudo dnf update -y
#  sudo dnf -y install wget
#}
#
## Install GIT
#install_git() {
#  sudo dnf install git -y
#  git --version
#}

## Installs Powerline-Fonts
#install_powerline_fonts () {
#    echo "Installing Powerline Fonts ..."
#    local fonts_install_dir=$USER_UNDER_CONFIG_HOME/fonts
#    local tty_consolefonts_dir=/usr/lib/kbd/consolefonts
#    local powerline_tty_font="ter-powerline-v14n"
#    delete_dir "$fonts_install_dir"
#    git clone https://github.com/powerline/fonts.git --depth=1 --quiet $fonts_install_dir
#    # install
#    # Set HOME to $USER_UNDER_CONFIG_HOME so that we dont accidentally install into root's HOME i.e /root
#    local origHome=$HOME
#    HOME=$USER_UNDER_CONFIG_HOME
#    cd $fonts_install_dir
#    ./install.sh
#    echo "Installing Powerline TTY terminal console fonts ... "
#    backup_file $VCONSOLE_CONF
#
#    # Check and make sure that we have the Terminus/PSF in the fonts dir before going ahead with Terminal Fonts Install
#    # NOTE: Only the fonts in Terminus directory (particularly the fonts in Terminus/PSF in the fonts directory) of
#    # powerline fonts can be used in TTY terminals (i.e. Alt F1 - F6 terminal consoles).
#    # The other Powerline fonts are for terminal apps such as iTerm2 terminal app in MacOS
#    # and terminal apps in the desktop environments in the various linux distros such the terminal app in GNOME etc
#    if  [ -d "Terminus/PSF" ] ; then
#      sudo find "." \( -name "$prefix*.psf.gz" \) -type f -print0 | xargs -0 -n1 -I % sudo cp "%" "$tty_consolefonts_dir"
#
#      if grep -iP "^FONT=.*$" $VCONSOLE_CONF ; then
#        # Delete the FONT stanza in /etc/vconsole.conf and replace it with $powerline_tty_font
#        sed -i '/^FONT=.*$/d' $VCONSOLE_CONF
#        echo "Updating $VCONSOLE_CONF with font $powerline_tty_font"
#        echo "FONT=\"$powerline_tty_font\"" >> $VCONSOLE_CONF
#      else
#        echo "Font not set in $VCONSOLE_CONF "
#        echo "Adding font $powerline_tty_font to $VCONSOLE_CONF"
#        echo "FONT=\"$powerline_tty_font\"" >> $VCONSOLE_CONF
#      fi
#
#      setfont $powerline_tty_font
#      echo "Finished Installing Powerline TTY terminal console fonts ... "
#    else
#      echo "$PWD/Terminus/PSF not found!!. Skipping Powerline TTY fonts installation ... "
#    fi
#    # clean-up a bit
#    cd ..
#    delete_dir fonts
#    HOME=$origHome
#    echo "Finished installing Powerline Fonts"
#}

#install_epel() {
#  # The code below should be used for when the centos Stream 9 EPEL is available
##  sudo dnf install epel-release
##  dnf repolist
#  echo "Installing EPEL ..."
#  echo " **************************************
#  Note: At the time of writing this, the Centos 9 Stream EPEL repos doesnt seem to be available,
#  so we have to use the centos 8 Stream EPEL repos for now.
#  Before applying this fix, check and make sure that the Centos 9 Stream EPEL repos are available
#  before going ahead replying yes
#  **************************************"
#  sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#
#  sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel*.repo
#   echo "Finished installing EPEL ..."
#
#}

# Install Bind9 i.e. DNS

#install_dns(){
#  echo "Installing DNS i.e Bind9 ..."
#  local namedConf=/etc/named.conf
#  sudo dnf install bind bind-utils -y
#  backup_file $namedConf
#  echo "Finished installing DNS i.e Bind9 ..."
#}

# Configures the keymap i.e the keyboard settings
# Args:
#     keymap [Default=us]: the key to use
#configure_keymap () {
#
#  echo "Configuring keymap ..."
#  local keymap=$1
#  if [ -z "$keymap" ]; then
#    keymap="us"
#  fi
#
#  if grep -iP "^KEYMAP=.*$" $VCONSOLE_CONF ; then
#   # Delete the keymap stanza in /etc/vconsole.conf and replace it with $keymap
#   sed -i '/^KEYMAP=.*$/d' $VCONSOLE_CONF
#   echo "Updating $VCONSOLE_CONF with keymap keymap"
#   echo "KEYMAP=\"$keymap\"" >> $VCONSOLE_CONF
#  else
#   echo "Font not set in $VCONSOLE_CONF "
#   echo "Adding font $powerline_tty_font to $VCONSOLE_CONF"
#    echo "KEYMAP=\"$powerline_tty_font\"" >> $VCONSOLE_CONF
#  fi
#  echo "Finished configuring keymap"
#}
# Installs google chrome
#install_google_chrome () {
#  # Install Google Chrome
#  echo "Installing Google Chrome ..."
#  cd /tmp
#  wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
#  sudo dnf localinstall google-chrome-stable_current_x86_64.rpm -y
#  #google-chrome &
#
#  echo "Google Chrome Completed!..."
#}

## Configures the hostname
#configure_hostname () {
#  # Configure the hostname
#  echo "Configuring the hostname in /etc/hostname ..."
#  echo "Backing up /etc/hostname ..."
#  cp -v /etc/hostname /etc/hostname.$DATETIME
#  echo "$HOSTNAME" > /etc/hostname
#  echo "Finished configuring the hostname in /etc/hostname ..."
#}

## Configure the default gateway
#configure_default_gateway() {
#  echo "Configuring the default gateway ..."
#
#  NETWORK_FILE=/etc/sysconfig/network
#  backup_file $NETWORK_FILE
#
#  echo "NETWORKING=yes
#  HOSTNAME=$HOSTNAME
#  GATEWAY=$DEFAULT_GATEWAY" > $NETWORK_FILE
#}

# Configures /etc/resolv.conf
#configure_resolv_conf(){
#  local resolv_conf=/etc/resolv.conf
#  echo "Creating $resolv_conf ..."
#  backup_file $resolv_conf
#
#  if [ "$CONFIGURE_DNS_CONFIRMATION" == "y" ] ; then
#    DNS_DOMAIN_SEARCH_STANZA="search $DOMAIN_NAME"
#    LOCAL_DNS_STANZA="nameserver $NIC_IP"
#  fi
#
#  echo "# $HOSTNAME resolv.conf
#
#$DNS_DOMAIN_SEARCH_STANZA
#$LOCAL_DNS_STANZA
#
## Google name servers i.e. Google DNS Servers
#nameserver 8.8.8.8
#nameserver 8.8.1.1
#
## Cloudflare name servers i.e Cloudflare DNS Servers
##nameserver 1.1.1.1
#" > $resolv_conf
#
#  echo "Finished creating $resolv_conf"
#}

# Configure wpa_supplicant
#configure_wpa_supplicant() {
#
#  echo "Configuring wpa_supplicant ..."
#  # Create / Update the /etc/sysconfig/network-scripts/ifcfg-SSID or /etc/sysconfig/network-scripts/ifcfg-NIC
#  # with static ip deteails
#  # returns NIC config file name in env var named NIC_CONFIG_FILE
#  get_nic_config_file $NIC $SSID
#  backup_file $NIC_CONFIG_FILE
#  if [ -f "$NIC_CONFIG_FILE" ]; then
#      echo "updating $NIC config $NIC_CONFIG_FILE with networking details ..."
#      if [ -f "$BACKED_UP_FILE" ]; then
#          NIC_CONFIG_FILE_BACKUP=$(echo $NIC_CONFIG_FILE | sed -e 's/ifcfg/__ifcfg/gI')
#          echo "renaming $BACKED_UP_FILE to $NIC_CONFIG_FILE_BACKUP"
#          mv -v $BACKED_UP_FILE $NIC_CONFIG_FILE_BACKUP
#      fi
#
#      if grep -qi "BOOTPROTO" "$NIC_CONFIG_FILE"; then
#          # Delete the line containing the BOOTPROTO stanza
#          sed -i '/BOOTPROTO/Id' $NIC_CONFIG_FILE
#          # append BOOTPROTO stanza
#          echo "BOOTPROTO=static" >> $NIC_CONFIG_FILE
#      fi
#
#      if grep -qi "IPADDR" "$NIC_CONFIG_FILE"; then
#          # Delete the line containing the IPADDR stanza
#          sed -i '/IPADDR/Id' $NIC_CONFIG_FILE
#          # append IPADDR stanza
#          echo "IPADDR=${NIC_IP}" >> $NIC_CONFIG_FILE
#      fi
#  else
#      echo "creating new $NIC_CONFIG_BASE_PATH$NIC ..."
#      echo "#
## File: ifcfg-$NIC
##
#DEVICE=$NIC
#IPADDR=$NIC_IP
#NETMASK=255.255.255.0
#BOOTPROTO=static
#ONBOOT=yes
##
## The following settings are optional
##
#BROADCAST=192.168.0.255
#NETWORK=192.168.0.0" > $NIC_CONFIG_BASE_PATH$NIC
#  echo "finished creating $NIC_CONFIG_BASE_PATH$NIC"
# fi
#
#
#  WPA_SUPPLICANT_CONF=/etc/wpa_supplicant/wpa_supplicant.conf
#  backup_file $WPA_SUPPLICANT_CONF
#  echo "creating new $WPA_SUPPLICANT_CONF"
#  wpa_passphrase $SSID $WIFI_PASSWORD > $WPA_SUPPLICANT_CONF
#  echo "Finished configuring wpa_supplicant ..."
#}


## Configure the NIC for NetworkManager
## Args:
##   $1 (nic) : The name of the network interface card (NIC) e.g. wlan0
##   $3 (nic_ip): The ip address of the NIC
##   $3 (ssid): the SSID of the Wifi to connect to
##   $5 (defaultGateway): The ip address of the default gateway
#configure_Wifi_For_NIC_using_NetworkManager(){
#  local nic=$1
#  local nic_ip=$2
#  local ssid=$3
#  local defaultGateway=$4
#  echo "Configuring NIC $nic for NetworkManager ..."
#  local dns_none_config_stanza="dns=none"
#  local network_dns_override_conf=/etc/NetworkManager/conf.d/no-dns-override.conf
#  local network_manager_conf=/etc/NetworkManager/NetworkManager.conf
#
#  if  ! grep -q $dns_none_config_stanza $network_manager_conf  ; then
#    echo "dns=none not found in $network_manager_conf"
##    backup_file $network_manager_conf
##    local comment="#inserted by George's post new install config script"
##    insert_after /etc/NetworkManager/NetworkManager.conf "\[main\]" "$comment"
##    insert_after /etc/NetworkManager/NetworkManager.conf "$comment" $dns_none_config_stanza
#    echo "Creating NetworkManager dns override config at $network_dns_override_conf"
#    echo -e "[main]
##Added by George Badu new install post setup script
##Prevents NetworkManager from overwriting /etc/resolv.conf
#dns=none" > $network_dns_override_conf
#
#  fi
#  systemctl restart NetworkManager.service
#  systemctl enable NetworkManager.service
#
#  backup_file /etc/NetworkManager/system-connections/$ssid.nmconnection
#  nmcli con mod $ssid ipv4.addresses $nic_ip/24
#  nmcli con mod $ssid ipv4.gateway $defaultGateway
#  nmcli con mod $ssid ipv4.method manual
#  # nmcli con mod $SSID ipv4.dns "8.8.8.8 8.8.1.1"
#  systemctl restart NetworkManager.service
#  nmcli con down $ssid
#  nmcli con up $ssid
#  echo "Finished configuring NIC $nic for NetworkManager"
#
#}

##Configure, update and setup raid
#configure_raid() {
#
#  echo "Configuring Raid ..."
#  RAID_CONF=/etc/mdadm.conf
#  backup_file $RAID_CONF
#  mdadm --examine --scan > $RAID_CONF
#  mdadm --assemble --scan
#  echo "Finished configuring Raid ..."
#}

#install_zsh_and_oh_my_zsh() {
#  # Install Oh My ZSH
#  echo "Installing zsh ..."
#  yum install zsh -y
#  chsh -s /bin/zsh $USER_UNDER_CONFIG
#  echo "Finished installing zsh ..."
#
#  add_empty_line
#
#  echo "Installing Oh-My-Zsh ..."
#  local origHome=$HOME
#  HOME=$USER_UNDER_CONFIG_HOME
#  ZSH=$USER_UNDER_CONFIG_HOME/.oh-my-zsh
#  ZSH_CUSTOM=$ZSH/custom
#
#
#  delete_dir $ZSH
#
#  # ZSH=$USER_UNDER_CONFIG_HOME/.oh-my-zsh sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" | zsh -c exit
#  wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
#  # INSTALL_SCRIPT=$(wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O -)
#  # echo "INSTALL_SCRIPT: $INSTALL_SCRIPT"
#
#  /bin/cp $USER_UNDER_CONFIG_HOME/.oh-my-zsh/templates/zshrc.zsh-template $USER_UNDER_CONFIG_HOME/.zshrc
#  echo "Finished installing Oh-My-Zsh ..."
#
#  add_empty_line
#
#  echo "Configuring Oh-My-Zsh ..."
#  add_empty_line
#  # Install powerline fonts
#  install_powerline_fonts
#  add_empty_line
#
##  echo "Sourcing $USER_UNDER_CONFIG_HOME/.zshrc..."
##  /bin/zsh -c "HOME=$USER_UNDER_CONFIG_HOME source $USER_UNDER_CONFIG_HOME/.zshrc"
#
#  add_empty_line
#  # Install Spaceship prompt
#  echo "Installing ZSH Theme Spaceship-Prompt ..."
#  delete_dir $ZSH_CUSTOM/themes/spaceship-prompt
#
#  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1 --quiet
#  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
#  echo "Finished installing ZSH Theme Spaceship-Prompt ..."
#  add_empty_line
#
#  # Install Zsh plugins
#  # Install zsh-autosuggestions
#  echo "Installing zsh-autosuggestions ..."
#  delete_dir ${USER_UNDER_CONFIG_HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
#  /bin/zsh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-${USER_UNDER_CONFIG_HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions --quiet"
#
#  add_empty_line
#
#  # Install zsh-syntax-highlighting
#  echo "Installing zsh-syntax-highlighting ..."
#  delete_dir ${USER_UNDER_CONFIG_HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
#  /bin/zsh -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$USER_UNDER_CONFIG_HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting --quiet"
#
#  add_empty_line
#
#  # Write ~/.zshrc
#  # Create ~/.zshrc
#  echo "Creating custom $USER_UNDER_CONFIG_HOME/.zshrc ..."
#  backup_file $USER_UNDER_CONFIG_HOME/.zshrc
#
#  echo '# If you come from bash you might have to change your $PATH.
## export PATH=$HOME/bin:/usr/local/bin:$PATH
#
## Path to your oh-my-zsh installation.
#export ZSH="$HOME/.oh-my-zsh"
#
## Set name of the theme to load --- if set to "random", it will
## load a random theme each time oh-my-zsh is loaded, in which case,
## to know which specific one was loaded, run: echo $RANDOM_THEME
## See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
##ZSH_THEME="robbyrussell"
#ZSH_THEME="spaceship"
#
#SPACESHIP_TIME_SHOW=true
#SPACESHIP_DIR_TRUNC=0
#SPACESHIP_USER_SHOW=always
#SPACESHIP_HOST_SHOW=always
#SPACESHIP_BATTERY_SHOW=always
#
## Set list of themes to pick from when loading at random
## Setting this variable when ZSH_THEME=random will cause zsh to load
## a theme from this variable instead of looking in $ZSH/themes/
## If set to an empty array, this variable will have no effect.
## ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )
#
## Uncomment the following line to use case-sensitive completion.
## CASE_SENSITIVE="true"
#
## Uncomment the following line to use hyphen-insensitive completion.
## Case-sensitive completion must be off. _ and - will be interchangeable.
## HYPHEN_INSENSITIVE="true"
#
## Uncomment the following line to disable bi-weekly auto-update checks.
## DISABLE_AUTO_UPDATE="true"
#
## Uncomment the following line to automatically update without prompting.
## DISABLE_UPDATE_PROMPT="true"
#
## Uncomment the following line to change how often to auto-update (in days).
## export UPDATE_ZSH_DAYS=13
#
## Uncomment the following line if pasting URLs and other text is messed up.
## DISABLE_MAGIC_FUNCTIONS=true
#
## Uncomment the following line to disable colors in ls.
## DISABLE_LS_COLORS="true"
#
## Uncomment the following line to disable auto-setting terminal title.
## DISABLE_AUTO_TITLE="true"
#
## Uncomment the following line to enable command auto-correction.
## ENABLE_CORRECTION="true"
#
## Uncomment the following line to display red dots whilst waiting for completion.
## COMPLETION_WAITING_DOTS="true"
#
## Uncomment the following line if you want to disable marking untracked files
## under VCS as dirty. This makes repository status check for large repositories
## much, much faster.
## DISABLE_UNTRACKED_FILES_DIRTY="true"
#
## Uncomment the following line if you want to change the command execution time
## stamp shown in the history command output.
## You can set one of the optional three formats:
## "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
## or set a custom format using the strftime function format specifications,
## see "man strftime" for details.
## HIST_STAMPS="mm/dd/yyyy"
#
## Would you like to use another custom folder than $ZSH/custom?
## ZSH_CUSTOM=/path/to/new-custom-folder
#
## Which plugins would you like to load?
## Standard plugins can be found in $ZSH/plugins/
## Custom plugins may be added to $ZSH_CUSTOM/plugins/
## Example format: plugins=(rails git textmate ruby lighthouse)
## Add wisely, as too many plugins slow down shell startup.
##plugins=(git)
#plugins=(
#	docker-compose
#        docker
#	extract
#	git
#      history-substring-search
#      history
#	npm
#	node
#      macos
#      vim-interaction
#	zsh-autosuggestions
#	zsh-syntax-highlighting
#	zsh_reload
#)
#
#source $ZSH/oh-my-zsh.sh
#
## User configuration
#
## export MANPATH="/usr/local/man:$MANPATH"
#
## You may need to manually set your language environment
## export LANG=en_US.UTF-8
#
## Preferred editor for local and remote sessions
## if [[ -n $SSH_CONNECTION ]]; then
##   export EDITOR=''vim''
## else
##   export EDITOR=''mvim''
## fi
#
## Compilation flags
## export ARCHFLAGS="-arch x86_64"
#
## Set personal aliases, overriding those provided by oh-my-zsh libs,
## plugins, and themes. Aliases can be placed here, though oh-my-zsh
## users are encouraged to define aliases within the ZSH_CUSTOM folder.
## For a full list of active aliases, run `alias`.
##
## Example aliases
## alias zshconfig="mate ~/.zshrc"
## alias ohmyzsh="mate ~/.oh-my-zsh"
#
## Source ~/.bash_profile
#
#source ~/.bash_profile
#
## If we are in the TTY terminal console, set the font to ter-powerline-v14n
#if tty | grep -iP "^/dev/tty[1-6]{1,1}" ; then
#  echo "Setting font to Powerline TTY font ter-powerline-v14n"
#  setfont ter-powerline-v14n
#fi
#
## Key Bindings
## Alt -> to jump one word forward
#bindkey "[C" forward-word
#
## Alt <- to jump one word backward
#bindkey "[D" backward-word
#
## Delete Word Backword bound to Alt+Backspace
## bindkey "^[^?" backward-kill-word
#
#' > $USER_UNDER_CONFIG_HOME/.zshrc
#
#  HOME=$origHome
#
#  echo "Finished creating custom $USER_UNDER_CONFIG_HOME/.zshrc "
#
#  add_empty_line
#
#  # CHMOD $USER_UNDER_CONFIG_HOME/.oh-my-zsh to allow read, write execute to $USER_UNDER_CONFIG
#  echo "Changing ownership of $USER_UNDER_CONFIG_HOME/.oh-my-zsh to $USER_UNDER_CONFIG ..."
#  chown -R $USER_UNDER_CONFIG $USER_UNDER_CONFIG_HOME/.oh-my-zsh
#  chmod -R u+rwx $USER_UNDER_CONFIG_HOME/.oh-my-zsh
#
#  echo "Changing ownership of $USER_UNDER_CONFIG_HOME/.zsh* to $USER_UNDER_CONFIG ..."
#  chown -R $USER_UNDER_CONFIG $USER_UNDER_CONFIG_HOME/.zsh*
#  chmod -R u+rwx $USER_UNDER_CONFIG_HOME/.zsh*
#
#  add_empty_line
#  echo "Finished configuring Oh-My-Zsh ..."
#}

# Set the default run level
#change_default_run_level() {
#  local defaultRunLevel="1"
#  local runLevel=$defaultRunLevel
#  echo "Configure the default run level "
#  echo "Current default run level: "
#  systemctl get-default
#  echo "
#
#Do you want change the current default run level?
#Please select a number or press enter to use the default run level
#
#1) graphical.target (Default)
#2) multi-user.target (Recommended for servers)
#  "
#
#  read runLevel
## if the user  doesnt provide a run level and presses Enter, we set the run leve to the default runlevel
#
#  if [ -z $runLevel ]; then
#    runLevel=$defaultRunLevel
#  else
#    while [ "$runLevel" != "1" ]  && [ "$runLevel" != "2" ]
#      do
#        echo "
#The provided run level $runLevel is unknown. Please select a number from the list below or press enter to continue
#
#1) graphical.target (Default)
#2) multi-user.target (Recommended for servers)"
#         read runLevel
#
#         # if the user doesnt provide a run level and presses Enter, we set the run leve to the default runlevel
#         if [ -z $runLevel ]; then
#             runLevel=$defaultRunLevel
#         fi
#      done
#  fi
#
#  if [ "$runLevel" == "1" ]  ; then
#     echo "Setting default run level to graphical.target ...
#     "
#     systemctl set-default graphical.target
#  elif [ "$runLevel" == "2" ]  ; then
#     echo "Setting default run level to multi-user.target ...
#     "
#     systemctl set-default multi-user.target
#  fi
#}
#

# Captures user input used to initialise the global variables below
# USER_UNDER_CONFIG: This the username of the user for which we configuring. We need to provide this because some commands are called using
#           sudo which will change the $HOME directory in the sudo context to that of root(i.e. /root), which can cause some undefined
#           behaviour
# USER_UNDER_CONFIG_HOME: The home directory of the provided user. This is set internally and is not user provided
# HOSTNAME [Default = mainframe]: The hostname that should be assigned to the machine we are configuring
# NIC_CONFIG_BASE_PATH: Set to /etc/sysconfig/network-scripts/ifcfg-
# VCONSOLE_CONF: Set to /etc/vconsole.conf
# KEYMAP [Default=us]: Sets the keyboard mapping i.e. Keymap
# DEFAULT_GATEWAY [Default = 192.168.0.1]: The default gateway that should used the machine being configured
# NIC [Default: wlp7s0]: The network interface card that will be configured with a static IP address of the machine being configured
# NIC_IP [Default: 192.168.0.2]: The static IP address to be assigned to the NIC
# $SSID: The SSID of the default Wi-Fi network the machine connects to
# WIFI_PASSWORD: The WiFi password
# CONFIGURE_DNS_CONFIRMATION [Default: n]: Holds the confirmation of whether to configure DNS
# DOMAIN_NAME [Default: homelan.com]: The domain to which the host i.e $HOSTNAME belongs

configure_user_provided_input_and_initialise_vars(){
  NIC_CONFIG_BASE_PATH=/etc/sysconfig/network-scripts/ifcfg-
  VCONSOLE_CONF=/etc/vconsole.conf

  echo "Please provide the username of the user to be configured"

  while [ -z $USER_UNDER_CONFIG ]
      do
          read USER_UNDER_CONFIG
          if [ -z $USER_UNDER_CONFIG ]; then
              echo "Username is required. Please enter the username"
          elif [ "$USER_UNDER_CONFIG" == "root" ]; then
              USER_UNDER_CONFIG_HOME=/$USER_UNDER_CONFIG
          else
              USER_UNDER_CONFIG_HOME=/home/$USER_UNDER_CONFIG
          fi
      done

  echo "Please provide the Keyboard mapping / Keyboard setting (i.e KEYMAP)

Default: us"
  read ${KEYMAP:-us}

  echo "Please a hostname for the machine you are configuring

Default: mainframe"
  read HOSTNAME
  HOSTNAME=${HOSTNAME:-mainframe}

  echo "Please enter the IP address of the  default gateway for your network

Default: 192.168.0.1"

  read DEFAULT_GATEWAY
  DEFAULT_GATEWAY=${DEFAULT_GATEWAY:-192.168.0.1}

  # show available NICs on this machine
  ip link

  echo "
Please enter the name of the NIC (Network Interface Card) of $HOSTNAME.
See above for details of NIC cards available on this machine
Default: wlp7s0"
  read NIC
  NIC=${NIC:-wlp7s0}

  echo "Please enter the static IP address of the NIC (Network Interface Card) of $NIC
Default: 192.168.0.2"
  read NIC_IP
  NIC_IP=${NIC_IP:-192.168.0.2}

  echo "Please enter Wi-Fi SSID"
  while [ -z $SSID ]
      do
          read SSID
          if [ -z $WIFI_PASSWORD ]; then
              echo "Wi-Fi SSID is required. Please enter Wi-Fi SSID"
          fi
      done

  echo "Please enter Wi-Fi Password"
  while [ -z $WIFI_PASSWORD ]
      do
          read WIFI_PASSWORD
          if [ -z $WIFI_PASSWORD ]; then
              echo "Wi-Fi Password is required. Please enter Wi-Fi Password"
          fi
      done


  echo "Do you want to configure $HOSTNAME as a local  DNS server?"
  print_confirmation_instructions

  read dnsServerConfigConfirmation
  CONFIGURE_DNS_CONFIRMATION=n

  if is_answer_yes "$dnsServerConfigConfirmation"  ; then
    CONFIGURE_DNS_CONFIRMATION=y
    echo "Please provide the domain of $HOSTNAME
Default: homelan.com"
    read DOMAIN_NAME
    DOMAIN_NAME=${DOMAIN_NAME:-homelan.com}
    add_empty_line

    if is_answer_yes "$CONFIGURE_DNS_CONFIRMATION"; then
        echo "Do you want to enable dynamic DNS updates i.e. allow hosts to automatically update the DNS server with new / updated host Ip addresses and names
Default: yes"
    print_confirmation_instructions
      read ALLOW_DYNAMIC_DNS_UPDATES
      ALLOW_DYNAMIC_DNS_UPDATES=${ALLOW_DYNAMIC_DNS_UPDATES:-y}
      add_empty_line
    fi
 fi
}

main () {
  require_root_access
  print_os_flavour
  local initDir=$PWD

  # Backs up a file
  # Arg1=file_to_back_up: The file to be backed up
  # Returns the name of the backed up file in an env var called BACKED_UP_FILE

  configure_user_provided_input_and_initialise_vars
  add_empty_line
  configure_keymap $KEYMAP $VCONSOLE_CONF
  add_empty_line
  install_wget
  add_empty_line
  install_google_chrome
  add_empty_line
  configure_hostname "$HOSTNAME"
  add_empty_line
  configure_default_gateway "$DEFAULT_GATEWAY" "$HOSTNAME"
  add_empty_line
  configure_resolv_conf "$HOSTNAME" "$CONFIGURE_DNS_CONFIRMATION" "$NIC_IP" "$DOMAIN_NAME"
  add_empty_line
  configure_wpa_supplicant "$NIC" "$NIC_IP" "$SSID" "$WIFI_PASSWORD" "$NIC_CONFIG_FILE" "$NIC_CONFIG_BASE_PATH"
  add_empty_line
  configure_raid
  add_empty_line
  install_git
  add_empty_line
  install_zsh_and_oh_my_zsh "$USER_UNDER_CONFIG" "$USER_UNDER_CONFIG_HOME" "$VCONSOLE_CONF"
  add_empty_line

  if is_answer_yes "$CONFIGURE_DNS_CONFIRMATION"; then
    #   $1 (dnsServerHostname): The hostname of the dns server e.g. mainframe
    #   $2 (domain): The dns zone / domain to configure or managed by the server e.g. homelab.com
    #   $3 (dnsServerIpAddress):  The static Ip address of the dns server e.g. 192.168.0.2
    #   $4 (cidrBlock): The CIDR block of the network e.g. 192.168.0.0/24
    #   $5 (allowDynamicDnsUpdates [Default: true]): if true i.e. (y, yes Yes, YES), the dns server allows clients to dynamically update the
    #                                 DNS with their hostnames and Ip address
    local cidrBlock
    get_suggested_cidr_block "$NIC_IP" cidrBlock
    install_and_configure_dns_server "$HOSTNAME" "$DOMAIN_NAME" "$NIC_IP" "$cidrBlock" "$ALLOW_DYNAMIC_DNS_UPDATES"
  fi
  change_default_run_level
  add_empty_line

  # Write message about installing VMWare Workstation
  echo "*************************"
  echo "Congrats!!!! ... Setup completed sucessully"
  echo "You can now install VMWare Workstation"
  echo "*************************"

  # Reboot
  echo "
"
  print_confirmation_instructions

  local rebootConfirmation
  read rebootConfirmation
  if is_answer_yes "$rebootConfirmation"  ; then
    add_empty_line
    configure_NIC_for_NetworkManager "$NIC" "$NIC_IP" "$SSID" "$DEFAULT_GATEWAY"
    sudo reboot
  else
    add_empty_line
    echo "NetworkManager is about to configure the static IP address for NIC $NIC"
    echo "You may be disconnected during the NIC configuration if you are remotely managing this server"
    echo "Please reconnect using IP address $NIC_IP"
    add_empty_line
    exec_command_and_show_spinner sleep 10
    configure_NIC_for_NetworkManager "$NIC" "$NIC_IP" "$SSID" "$DEFAULT_GATEWAY"
  fi

  echo "Finishing set up and logging into ZSH ..."
  if [ "$USER_UNDER_CONFIG" != "$USER" ] ; then

     echo "Logging $USER_UNDER_CONFIG into ZSH ..."
     cd "$initDir"
     su "$USER_UNDER_CONFIG"
  fi

}
# Call main
main

# Install BIND
# Install Kubernetes
# Add Script to create auto start VMs service


# Unset
set +e
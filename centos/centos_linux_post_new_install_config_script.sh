#!/bin/bash

# Adds an empty line
# Args:
# numOfLines: the number of lines to add: Default = 1
add_empty_line () {
    local numOfLines=$1

    if [ -z $numOfLines ]; then
      numOfLines=1
    fi

    i=0
    while [ $i -ne $numOfLines ]
    do
      i=$(($i+1))
      echo ""
    done

}
backup_file() {
    BACKED_UP_FILE=
    local file_to_backup=$1
    if [ -f "$file_to_backup" ]; then
        echo "$file_to_backup exists"
        echo "Backing up $file_to_backup ..."
        local backup=$(echo "$file_to_backup" | sed -e "s|$file_to_backup|$file_to_backup-$DATETIME|g")
        echo "Backing up $file_to_backup as $backup"
        cp -v $file_to_backup $backup.bkup
        BACKED_UP_FILE=$backup

    else
        echo "$file_to_backup does not exist. skipping backup"
    fi
}

# Set an environment variable called NIC_CONFIG_FILE with
# the path to the config file of the NIC card to be configured
# Arg1=NIC Name: Name of the NIC card whose
# Arg2=SSID Name: Name of the SSID that Network Manager used to create
#                    the NIC config script
get_nic_config_file() {
    local nic_name=$1
    local ssid_name=$2
    NIC_CONFIG_FILE=
    if [ -f "$NIC_CONFIG_BASE_PATH$nic_name" ]; then
        NIC_CONFIG_FILE=$NIC_CONFIG_BASE_PATH$nic_name
    elif [ -f "$NIC_CONFIG_BASE_PATH$ssid_name" ]; then
        NIC_CONFIG_FILE=$NIC_CONFIG_BASE_PATH$ssid_name
    fi
}

# Deletes a directory if it can
# Arg1=directory_to_delete: the path to the directory
delete_dir () {
    local dir_to_delete=$1
    if [ -d "$dir_to_delete" ]; then
        echo "Deleting $dir_to_delete ..."
        rm -rf $dir_to_delete
        echo "Deleted $dir_to_delete ..."
    else
        echo "cannot delete $dir_to_delete. skipping ..."
    fi
}

# Installs wget
install_wget (){
  echo "Installing wget ..."

  sudo dnf update -y
  sudo dnf -y install wget
}

# Install GIT
install_git() {
  sudo dnf install git -y
  git --version
}

# Installs Powerline-Fonts
install_powerline_fonts () {
    echo "Installing Powerline Fonts ..."
    local font_install_dir=$USERNAME_HOME/fonts
    delete_dir $font_install_dir
    git clone https://github.com/powerline/fonts.git --depth=1 --quiet $font_install_dir
    # install
    # Set HOME to $USERNAME_HOME so that we dont accidentally install into root's HOME i.e /root
    local origHome=$HOME
    HOME=$USERNAME_HOME
    cd $font_install_dir
    ./install.sh
    # clean-up a bit
    cd ..
    # rm -rf fonts
    HOME=$origHome
    echo "Finished installing Powerline Fonts"
}

# Installs google chrome
install_google_chrome () {
  # Install Google Chrome
  echo "Installing Google Chrome ..."
  cd /tmp
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
  sudo dnf localinstall google-chrome-stable_current_x86_64.rpm
  #google-chrome &

  echo "Google Chrome Completed!..."
}

# Installs the hostname
configure_hostname () {
  # Configure the hostname
  echo "Configuring the hostname in /etc/hostname ..."
  echo "Backing up /etc/hostname ..."
  cp -v /etc/hostname /etc/hostname.$DATETIME
  echo "$HOSTNAME" > /etc/hostname
  echo "Finished configuring the hostname in /etc/hostname ..."
}

# Configure the default gateway
configure_default_gateway() {
  echo "Configuring the default gateway ..."

  NETWORK_FILE=/etc/sysconfig/network
  backup_file $NETWORK_FILE

  echo "NETWORKING=yes
  HOSTNAME=$HOSTNAME
  GATEWAY=$DEFAULT_GATEWAY" > $NETWORK_FILE
}

# Configures /etc/resolv.conf
configure_resolv_conf(){
  local resolv_conf=/etc/resolv.conf
  echo "Creating $resolv_conf ..."
  backup_file $resolv_conf

  echo "# $HOSTNAME resolv.conf
# Google name servers i.e. Google DNS Servers
nameserver 8.8.8.8
nameserver 8.8.1.1
# Cloudflare name servers i.e Cloudflare DNS Servers
nameserver 8.8.1.1
" > $resolv_conf

  echo "Finished creating $resolv_conf"
}

# Configure wpa_supplicant
configure_wpa_supplicant() {

  echo "Configuring wpa_supplicant ..."
  # Create / Update the /etc/sysconfig/network-scripts/ifcfg-SSID or /etc/sysconfig/network-scripts/ifcfg-NIC
  # with static ip deteails
  # returns NIC config file name in env var named NIC_CONFIG_FILE
  get_nic_config_file $NIC $SSID
  backup_file $NIC_CONFIG_FILE
  if [ -f "$NIC_CONFIG_FILE" ]; then
      echo "updating $NIC config $NIC_CONFIG_FILE with networking details ..."
      if [ -f "$BACKED_UP_FILE" ]; then
          NIC_CONFIG_FILE_BACKUP=$(echo $NIC_CONFIG_FILE | sed -e 's/ifcfg/__ifcfg/gI')
          echo "renaming $BACKED_UP_FILE to $NIC_CONFIG_FILE_BACKUP"
          mv -v $BACKED_UP_FILE $NIC_CONFIG_FILE_BACKUP
      fi

      if grep -qi "BOOTPROTO" "$NIC_CONFIG_FILE"; then
          # Delete the line containing the BOOTPROTO stanza
          sed -i '/BOOTPROTO/Id' $NIC_CONFIG_FILE
          # append BOOTPROTO stanza
          echo "BOOTPROTO=static" >> $NIC_CONFIG_FILE
      fi

      if grep -qi "IPADDR" "$NIC_CONFIG_FILE"; then
          # Delete the line containing the IPADDR stanza
          sed -i '/IPADDR/Id' $NIC_CONFIG_FILE
          # append IPADDR stanza
          echo "IPADDR=${NIC_IP}" >> $NIC_CONFIG_FILE
      fi
  else
      echo "creating new $NIC_CONFIG_BASE_PATH$NIC ..."
      echo "#
# File: ifcfg-$NIC
#
DEVICE=$NIC
IPADDR=$NIC_IP
NETMASK=255.255.255.0
BOOTPROTO=static
ONBOOT=yes
#
# The following settings are optional
#
BROADCAST=192.168.0.255
NETWORK=192.168.0.0" > $NIC_CONFIG_BASE_PATH$NIC
  echo "finished creating $NIC_CONFIG_BASE_PATH$NIC"
 fi


  WPA_SUPPLICANT_CONF=/etc/wpa_supplicant/wpa_supplicant.conf
  backup_file $WPA_SUPPLICANT_CONF
  echo "creating new $WPA_SUPPLICANT_CONF"
  wpa_passphrase $SSID $WIFI_PASSWORD > $WPA_SUPPLICANT_CONF
  echo "Finished configuring wpa_supplicant ..."
}


# Configure the NIC for NetworkManager
configure_NIC_for_NetworkManager(){
  echo "Configuring NIC $NIC for NetworkManager ..."
  backup_file /etc/NetworkManager/system-connections/$SSID.nmconnection
  nmcli con mod $SSID ipv4.addresses $NIC_IP/24
  nmcli con mod $SSID ipv4.gateway $DEFAULT_GATEWAY
  nmcli con mod $SSID ipv4.method manual
  # nmcli con mod $SSID ipv4.dns "8.8.8.8 8.8.1.1"
  nmcli con down $SSID
  nmcli con up $SSID
  echo "Finished configuring NIC $NIC for NetworkManager"

}

#Configure, update and setup raid
configure_raid() {

  echo "Configuring Raid ..."
  RAID_CONF=/etc/mdadm.conf
  backup_file $RAID_CONF
  mdadm --examine --scan > $RAID_CONF
  mdadm --assemble --scan
  echo "Finished configuring Raid ..."
}

install_zsh_and_oh_my_zsh() {
  # Install Oh My ZSH
  echo "Installing zsh ..."
  yum install zsh -y
  chsh -s /bin/zsh $USERNAME
  echo "Finished installing zsh ..."

  add_empty_line

  echo "Installing Oh-My-Zsh ..."
  local origHome=$HOME
  HOME=$USERNAME_HOME
  ZSH=$USERNAME_HOME/.oh-my-zsh
  ZSH_CUSTOM=$ZSH/custom


  delete_dir $ZSH

  # ZSH=$USERNAME_HOME/.oh-my-zsh sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" | zsh -c exit
  wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
  # INSTALL_SCRIPT=$(wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O -)
  # echo "INSTALL_SCRIPT: $INSTALL_SCRIPT"

  /bin/cp $USERNAME_HOME/.oh-my-zsh/templates/zshrc.zsh-template $USERNAME_HOME/.zshrc
  echo "Finished installing Oh-My-Zsh ..."

  add_empty_line

  echo "Configuring Oh-My-Zsh ..."
  add_empty_line
  # Install powerline fonts
  install_powerline_fonts
  add_empty_line

#  echo "Sourcing $USERNAME_HOME/.zshrc..."
#  /bin/zsh -c "HOME=$USERNAME_HOME source $USERNAME_HOME/.zshrc"

  add_empty_line
  # Install Spaceship prompt
  echo "Installing ZSH Theme Spaceship-Prompt ..."
  delete_dir $ZSH_CUSTOM/themes/spaceship-prompt

  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1 --quiet
  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  echo "Finished installing ZSH Theme Spaceship-Prompt ..."
  add_empty_line

  # Install Zsh plugins
  # Install zsh-autosuggestions
  echo "Installing zsh-autosuggestions ..."
  delete_dir ${USERNAME_HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  /bin/zsh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-${USERNAME_HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions --quiet"

  add_empty_line

  # Install zsh-syntax-highlighting
  echo "Installing zsh-syntax-highlighting ..."
  delete_dir ${USERNAME_HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  /bin/zsh -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$USERNAME_HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting --quiet"

  add_empty_line

  # Write ~/.zshrc
  # Create ~/.zshrc
  echo "Creating custom $USERNAME_HOME/.zshrc ..."
  backup_file $USERNAME_HOME/.zshrc

  echo '# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="spaceship"

SPACESHIP_TIME_SHOW=true
SPACESHIP_DIR_TRUNC=0
SPACESHIP_USER_SHOW=always
SPACESHIP_HOST_SHOW=always
SPACESHIP_BATTERY_SHOW=always

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see "man strftime" for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
#plugins=(git)
plugins=(
	docker-compose
        docker
	extract
	git
      history-substring-search
      history
	npm
	node
      macos
      vim-interaction
	zsh-autosuggestions
	zsh-syntax-highlighting
	zsh_reload
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR=''vim''
# else
#   export EDITOR=''mvim''
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Source ~/.bash_profile

source ~/.bash_profile

# Key Bindings
# Alt -> to jump one word forward
bindkey "[C" forward-word

# Alt <- to jump one word backward
bindkey "[D" backward-word

# Delete Word Backword bound to Alt+Backspace
# bindkey "^[^?" backward-kill-word

' > $USERNAME_HOME/.zshrc

  HOME=$origHome

  echo "Finished creating custom $USERNAME_HOME/.zshrc "

  add_empty_line

  # CHMOD $USERNAME_HOME/.oh-my-zsh to allow read, write execute to $USERNAME
  echo "Changing ownership of $USERNAME_HOME/.oh-my-zsh to $USERNAME ..."
  chown -R $USERNAME $USERNAME_HOME/.oh-my-zsh
  chmod -R u+rwx $USERNAME_HOME/.oh-my-zsh

  echo "Changing ownership of $USERNAME_HOME/.zsh* to $USERNAME ..."
  chown -R $USERNAME $USERNAME_HOME/.zsh*
  chmod -R u+rwx $USERNAME_HOME/.zsh*

  add_empty_line
  echo "Finished configuring Oh-My-Zsh ..."
}

# Set the default run level
change_default_run_level() {
  local defaultRunLevel="1"
  local runLevel=$defaultRunLevel
  echo "Configure the default run level "
  echo "Current default run level: "
  systemctl get-default
  echo "

Do you want change the current default run level?
Please select a number or press enter to use the default run level

1) graphical.target (Default)
2) multi-user.target (Recommended for servers)
  "

  read runLevel
# if the user  doesnt provide a run level and presses Enter, we set the run leve to the default runlevel

  if [ -z $runLevel ]; then
    runLevel=$defaultRunLevel
  else
    while [ "$runLevel" != "1" ]  && [ "$runLevel" != "2" ]
      do
        echo "
The provided run level $runLevel is unknown. Please select a number from the list below or press enter to continue

1) graphical.target (Default)
2) multi-user.target (Recommended for servers)"
         read runLevel

         # if the user doesnt provide a run level and presses Enter, we set the run leve to the default runlevel
         if [ -z $runLevel ]; then
             runLevel=$defaultRunLevel
         fi
      done
  fi

  if [ "$runLevel" == "1" ]  ; then
     echo "Setting default run level to graphical.target ...
     "
     systemctl set-default graphical.target
  elif [ "$runLevel" == "2" ]  ; then
     echo "Setting default run level to multi-user.target ...
     "
     systemctl set-default multi-user.target
  fi
}
# Captures user input used to initialise the global variables below
# USERNAME: This the username of the user for which we configuring. We need to provide this because some commands are called using
#           sudo which will change the $HOME directory in the sudo context to that of root(i.e. /root), which can cause some undefined
#           behaviour
# USERNAME_HOME: The home directory of the provided user. This is set internally and is not user provided
# HOSTNAME: The hostname that should be assigned to the machine we are configuring - Default = mainframe
# NIC_CONFIG_BASE_PATH: Set to /etc/sysconfig/network-scripts/ifcfg-
# DEFAULT_GATEWAY: The default gateway that should used the machine being configured - Default = 192.168.0.1
# NIC: The network interface card that will be configured with a static IP address of the machine being configured: Default: wlp7s0
# NIC_IP: The static IP address to be assigned to the NIC
# $SSID: The SSID of the default Wi-Fi network the machine connects to
# WIFI_PASSWORD: The WiFi password

configure_user_provided_input_and_initialise_vars(){
  DATETIME=$(date '+%Y-%m-%d %H:%M:%S' | sed -e 's/ /_/g' | sed -e 's/:/_/g')
  NIC_CONFIG_BASE_PATH=/etc/sysconfig/network-scripts/ifcfg-

  echo "Please provide the username of the user to be configured"
  while [ -z $USERNAME ]
      do
          read USERNAME
          if [ -z $USERNAME ]; then
              echo "Username is required. Please enter the username"
          elif [ "$USERNAME" == "root" ]; then
              USERNAME_HOME=/$USERNAME
          else
              USERNAME_HOME=/home/$USERNAME
          fi
      done

  echo "Please enter the hostname of the machine you are configuring

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
}

main () {
  local script_caller=$(whoami)
  if [ "$script_caller" != "root" ]; then
    echo "********************************************************
This script must be executed by user 'root'.
Please user 'sudo' to execute this script
********************************************************"
    exit
  fi
  local initDir=$PWD

  # Backs up a file
  # Arg1=file_to_back_up: The file to be backed up
  # Returns the name of the backed up file in an env var called BACKED_UP_FILE

  configure_user_provided_input_and_initialise_vars
  add_empty_line
  install_wget
  add_empty_line
  install_google_chrome
  add_empty_line
  configure_hostname
  add_empty_line
  configure_default_gateway
  add_empty_line
  configure_resolv_conf
  add_empty_line
  configure_wpa_supplicant
  add_empty_line
  configure_raid
  add_empty_line
  install_git
  add_empty_line
  install_zsh_and_oh_my_zsh
  add_empty_line
  change_default_run_level
  add_empty_line

  # Write message about installing VMWare Workstation
  echo "*************************"
  echo "Congrats!!!! ... Setup completed sucessully"
  echo "You can now install VMWare Workstation"
  echo "*************************"

  # Reboot
  echo "

Reboot (Only 'YES', 'Yes', 'yes' or 'y' will do)"

  local rebootConfirmation
  read rebootConfirmation
  if [ "$rebootConfirmation" == "Yes" ] || [ "$rebootConfirmation" == "yes" ] || [ "$rebootConfirmation" == "y" ] || [ "$rebootConfirmation" == "YES" ] ; then
    add_empty_line
    configure_NIC_for_NetworkManager
    sudo reboot
  else
    add_empty_line
    echo "NetworkManager is about to configure the static IP address for NIC $NIC"
    echo "You will be disconnected during the NIC configuration if you are remotely managing this server"
    echo "Please reconnect using IP address $NIC_IP"
    add_empty_line
    sleep 10
    configure_NIC_for_NetworkManager
  fi

  echo "Finishing set up and logging into ZSH ..."
  if [ "$USERNAME" != "$USER" ] ; then

     echo "Logging $USERNAME into ZSH ..."
     cd $initDir
     su $USERNAME
  fi

}

# Call main
main

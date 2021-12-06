#!/bin/bash

# Prepares and returns a result from a function.
# Args:
#   $1 (valueToSet): The value to be returned from a function
#   $2 (variableToSet): the name of the variable to set. If this is not given, the result will be echoed.
#   Example usage: return_function_result "$value" "$nameOfVariableToSet"
#   Note: the variables MUST USE THE SHELL EXPANSION OPERATOR $ and be quoted like so "$value" "$nameOfVariableToSet"
return_function_result(){
  local __valueToSet__=$1
  local __variableToSet__=$2
     if [[ "$__variableToSet__" ]]; then
             eval $__variableToSet__="'$__valueToSet__'"
         else
             echo "$__valueToSet__"
      fi
}
# Makes sure that either script or function is run with root access
function require_root_access() {
  set -e
  local script_caller=$(whoami)
  if [ "$script_caller" != "root" ]; then
      echo "********************************************************
This script must be executed by user 'root'.
Please use 'sudo' to execute this script or login as user
root before executing this script / commands
********************************************************"
    exit
  fi
}
# Returns the flavour of the OS e.g.  If the OS is Debian flavoured, will return 'debian' the OUT variable
# Fedora flavoured OS suchs as Centos, RHEL, RockyLinux, AlmaLinux will return 'fedora' in the OUT variable
# Args:
#   $1 (OUT flavour): when provided the OS flavour will be assigned to this variable
#   Example usage get_os_flavour flavour
get_os_flavour() {
  source /etc/os-release && IFS=', ' read -r -a os_flavours <<< "$ID_LIKE"
  local fedora_flavours=("rhel centos fedora")
  local debian_flavours=("debian")
  local __flavour__
  local __returnVariable__=$1

  for flavour in "${os_flavours[@]}"
    do
      echo "flavour is $flavour"
      local funRes
      containsElement "$flavour" "${fedora_flavours[@]}"
      local funRes=$?

      if [ $funRes -eq 0 ] ; then
        __flavour__="fedora"
        break
      fi

      containsElement "$flavour" "${debian_flavours[@]}"
      local funRes=$?
      if [ $funRes -eq 0 ] ; then
        __flavour__="debian"
        break
      fi
    done
  unset IFS # or set back to original IFS if previously set
  return_function_result "$__flavour__" "$__returnVariable__"
}

# Checks if the supplied cidr is valid
#  Args:
#   $1 (cidrBlock) : The CIDR block e.g. 192.168.0.0/24
is_valid_cidr() {

  local cidrBlock=$1
  local cidrBlockRegexPattern="^([0-9]{1,3}\.){3}[0-9]{1,3}/\d{1,2}$"
    if echo "$cidrBlock"| grep -iP "$cidrBlockRegexPattern" ; then
      return 0
    fi
    return 1
}

# Returns true (i.e return code 0) if the answer supplied is on of "Yes", "yes", "YES" or "y"
# Args:
#   $1 (answer) : the answer provided
is_answer_yes() {
  local __answer__=$1
  if [ "$__answer__" == "Yes" ] || [ "$__answer__" == "yes" ] || [ "$__answer__" == "y" ] || [ "$__answer__" == "YES" ] || [ "$__answer__" == "true" ]  || [ "$__answer__" == "TRUE" ] ; then
    return 0
  fi
  return 1
}

# An alias for is_answer_yes
# Args:
#   $1 (valueToTest) : the value to test
is_true(){
  local __value__=$1
  is_answer_yes "$__value__"
  local result=$?
  return $result
}

# Checks if a package is installed. Return 0 if package is installed, and 1 if package is not installed
# Args:
#   $1 (packageName): The name of the package to check
#   Exampele usage is_package_installed sudo
is_package_installed() {
  local packageName=$1
  local result=1
  local flavour
  get_os_flavour flavour

  if [ "$flavour" == "fedora" ]; then
    sudo dnf list installed "$packageName" | if grep -q "Installed Packages"; then
        result=0;
      fi
  elif [ "$flavour" == "debian" ]; then
   dpkg -s "$packageName" | if grep -q "install ok installed"; then
     result=0
     fi
   else
     echo "Unknown OS flavor $flavour. Skipping Bind9 installation..."
  fi

  return "$result"

}

# Prints the values that will be accepted as confirmation of an instruction
print_confirmation_instructions(){
  echo "Only 'YES', 'Yes', 'yes', 'y', 'true' or 'TRUE' will be accepted as as confirmation"
}


# Given an Ip Address, will supply a naive cidr block i.e. this method strips of the last octet in ip address
# and replaces it with "0/24" e.g. given an Ip address 192.168.0.2, will return 192.168.0.0/24
# Args:
#   $1 (ipAddress): The ip address that will be used as the base of the CIDR block
#   $2 (out cidrBlock): When provided, The cidrBlock will be returned in this variable
get_suggested_cidr_block(){

  local ipAddress=$1
  local __cidrBlock__=$2

    if [ -z "$ipAddress" ] ; then
      echo "An Ip Address is required: Please provide an Ip address as arg 1"
      return 1
    fi
  local cidrBlock
  # Replaces the last stanza in an Ip address with 0/24.
  # For example given an Ip address 192.168.0.2, will return 192.168.0.0/24
  cidrBlock=$(echo "$cidrBlock" | sed -E "s/[0-9]{1,3}$/0\/24/g")
  return_function_result "$cidrBlock" "$__cidrBlock__"
}

# Given a CIDR block such as 192.168.0.0/24, this function will extract and return
# the network ip (i.e 192.168.0.0) and the network prefix i.e. 24
#  Args:
#   $1 (cidrBlock) : The CIDR block e.g. 192.168.0.0/24
#   $2 (OUT networkIp): The network ip to return i.e. (192.168.0.0)
#   $3 (OUT networkPrefix): The network prefix to return i.e. (24)
extract_network_ip_and_network_prefix_from_cidr_block() {
  local cidrBlock=$1
  local networkIpOut=$2
  local networkPrefixOut=$3
  local __networkIp__
  local __networkPrefix__

  if [ -z "$cidrBlock" ] ; then
      echo "The CIDR block is required"
      echo "Please provide the CIDR block as arg 1"
      return 1
  fi

  if is_valid_cidr "$cidrBlock" ; then
    IFS='/' read -r -a ipAndPrefixArr <<< "$cidrBlock";
    unset IFS # reset IFS to its previous value
    __networkIp__=${ipAndPrefixArr[0]}
    __networkPrefix__=${ipAndPrefixArr[1]}
  fi

  return_function_result "$__networkIp__" "$networkIpOut"
  return_function_result "$__networkPrefix__" "$networkPrefixOut"
}

print_os_flavour() {
    local flavour
    get_os_flavour flavour

    if [ "$flavour" == "fedora" ] ; then
      echo "*****************************************"
      echo "Configuring a Fedora flavoured system"
      echo "*****************************************"
    elif [ "$flavour" == "debian" ]; then
      echo "*****************************************"
      echo "Configuring a Debian flavoured system"
      echo "*****************************************"
    else
      echo "*****************************************"
      echo "Configuring an unknown flavoured system"
      echo "*****************************************"
    fi
}
# Returns 0 if the array contains the given element
# Args:
#  $1 (element): element to search for
#  $2 (array): the array to search
# Example usage:  array=("something to search for" "a string" "test2000")
                 # containsElement "a string" "${array[@]}"
                 # echo $?
                 # 0
                 # containsElement "blaha" "${array[@]}"
                 # echo $?
                 # 1


containsElement () {
  local elem=$1
  local array=$2
  for item in "${array[@]}"; do
      [[ $elem == "$item" ]] && echo "$elem present in the array"; return 0;
  done
  return 1
}

# Set an environment variable called NIC_CONFIG_FILE with
# the path to the config file of the NIC card to be configured on fedora flavoured systems such as Centos and RHEL
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

# Adds an empty line
# Args:
# $1 (numOfLines): the number of lines to add: Default = 1
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

show_spinner() {
    local pid=$!
    local delay=0.4
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Executes a command and shows a spinner
# Args:
# $1 (command) : the command to execute with a spinner
exec_command_and_show_spinner() {
  local command=$@
  # echo "THE COMMAND AND ARGS ARE $command"
  ("$@") & show_spinner "$!"
}

# Backs up a file
# Args:
#   $1 (fileToBackUp): the file to be backed up
backup_file() {
    BACKED_UP_FILE=
    local file_to_backup=$1
    if [ -f "$file_to_backup" ]; then
        echo "$file_to_backup exists"
        echo "Backing up $file_to_backup ..."
        local backup

        if [ -f "${file_to_backup}-orig.bkup" ] ; then
          backup=$(echo "$file_to_backup" | sed -e "s|$file_to_backup|$file_to_backup-$DATETIME|g")
          backup="$backup.bkup"
        else
          backup="${file_to_backup}-orig.bkup"
        fi

        echo "Backing up $file_to_backup as $backup"
        cp -v $file_to_backup $backup
        BACKED_UP_FILE=$backup
    else
        echo "$file_to_backup does not exist. skipping backup"
    fi
}

# Finds a line containing a given string in a file and inserts the given new
# after the found line
# Args: $1 = the path to the file to search
#       $2 = the string to search for in the file. Not that this is a regex pattern so you must escape special characters such [ ]
#       and \
#       $3 = the string to insert after the found line
function insert_after # file line newText
{

  local file="$1" line="$2" newText="$3"
 # echo "inserting '${newText}' after line  "${line}" in file ${file}"

  if grep -q "${line}" "${file}"; then
    sed -i -e "/^$line/a"$'\\\n'"$newText"$'\n' "$file"
  else
      echo -e "\n${newText}" >> ${file}
  fi
}

# Deletes a directory if it can
# Args
# $1 (directory_to_delete): the path to the directory
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

  local flavour
  get_os_flavour flavour

  if [ "$flavour" == "fedora" ] ; then
    sudo dnf update -y
    sudo dnf -y install wget
  elif [ "$flavour" == "debian" ]; then
    sudo apt-get update
    sudo apt-get -y install wget
  fi


}

# Install GIT
install_git() {
  local flavour
  get_os_flavour flavour

   if [ "$flavour" == "fedora" ] ; then
      sudo dnf install git -y
      git --version
    elif [ "$flavour" == "debian" ]; then
      sudo apt-get update
      sudo apt-get -y install git
    fi

}

# Installs Powerline-Fonts
# Args:
# $1 (userUnderConfigHome) : The $HOME of the user who for whom the powerline fonts are to be installed for
# $2 (vconsoleConf) : The path to the console configuration file. Usually /etc/vconsole.conf
install_powerline_fonts () {
    echo "Installing Powerline Fonts ..."
  local userUnderConfigHome=$1
  local vconsoleConf=$2
  if [ -z "$userUnderConfigHome" ]; then
      echo "The USER_UNDER_CONFIG is required e.g. /home/dman. Please supply the USER_UNDER_CONFIG as arg 1"
      return 1
  fi

  if [ -z "$vconsoleConf" ]; then
     echo "The VCONSOLE file path (usually /etc/vconsole.conf for fedora flavour) is required. Please supply the path to VCONSOLE file as arg 2"
     return 1
  fi

    local fonts_install_dir=$userUnderConfigHome/fonts
    local tty_consolefonts_dir=/usr/lib/kbd/consolefonts
    local powerline_tty_font="ter-powerline-v14n"
    local vconsoleConf=$2
    delete_dir "$fonts_install_dir"
    git clone https://github.com/powerline/fonts.git --depth=1 --quiet $fonts_install_dir
    # install
    # Set HOME to $userUnderConfigHome so that we dont accidentally install into root's HOME i.e /root
    local origHome=$HOME
    HOME=$userUnderConfigHome
    cd $fonts_install_dir
    ./install.sh
    echo "Installing Powerline TTY terminal console fonts ... "
    backup_file $vconsoleConf

    # Check and make sure that we have the Terminus/PSF in the fonts dir before going ahead with Terminal Fonts Install
    # NOTE: Only the fonts in Terminus directory (particularly the fonts in Terminus/PSF in the fonts directory) of
    # powerline fonts can be used in TTY terminals (i.e. Alt F1 - F6 terminal consoles).
    # The other Powerline fonts are for terminal apps such as iTerm2 terminal app in MacOS
    # and terminal apps in the desktop environments in the various linux distros such the terminal app in GNOME etc
    if  [ -d "Terminus/PSF" ] ; then
      sudo find "." \( -name "$prefix*.psf.gz" \) -type f -print0 | xargs -0 -n1 -I % sudo cp "%" "$tty_consolefonts_dir"

      if grep -iP "^FONT=.*$" $vconsoleConf ; then
        # Delete the FONT stanza in /etc/vconsole.conf and replace it with $powerline_tty_font
        sed -i '/^FONT=.*$/d' $vconsoleConf
        echo "Updating $vconsoleConf with font $powerline_tty_font"
        echo "FONT=\"$powerline_tty_font\"" >> $vconsoleConf
      else
        echo "Font not set in $vconsoleConf "
        echo "Adding font $powerline_tty_font to $vconsoleConf"
        echo "FONT=\"$powerline_tty_font\"" >> $vconsoleConf
      fi

      setfont $powerline_tty_font
      echo "Finished Installing Powerline TTY terminal console fonts ... "
    else
      echo "$PWD/Terminus/PSF not found!!. Skipping Powerline TTY fonts installation ... "
    fi
    # clean-up a bit
    cd ..
    delete_dir fonts
    HOME=$origHome
    echo "Finished installing Powerline Fonts"
}

install_epel() {
  # The code below should be used for when the centos Stream 9 EPEL is available
#  sudo dnf install epel-release
#  dnf repolist

  echo "Installing EPEL ..."
  local result=1
  local flavour
  get_os_flavour flavour
  if [ "$flavour" == "fedora" ] ; then
    echo " **************************************
Note: At the time of writing this, the Centos 9 Stream EPEL repos doesnt seem to be available,
so we have to use the centos 8 Stream EPEL repos for now.
Before applying this fix, check and make sure that the Centos 9 Stream EPEL repos are available
before going ahead replying yes
**************************************"
    sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y

    sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel*.repo
    result=0
    echo "Finished installing EPEL ..."
 elif [ "$flavour" == "debian" ]; then
    echo "EPEL cannot be installed on Debian flavoured systems. Skipping ..."

 else
    echo "EPEL cannot be installed on an unknown flavour. Skipping ..."
 fi

  return $result
}


# Install the Bind9 named server
install_bind9() {
  local flavour
  get_os_flavour flavour

  echo "Installing Bind9 (named) ..."

  if [ "$flavour" == "fedora" ] ; then
    sudo dnf install bind bind-utils -y
  elif [ "$flavour" == "debian" ]; then
    sudo apt-get update
    sudo apt-get -y install bind bind-utils
  else
    echo "Unknown OS flavor $flavour. Skipping Bind9 installation..."
    return 1
  fi
}

# Install sshpass
install_sshpass() {
  local installSspPassResult
  local flavour
  get_os_flavour flavour
  echo "Installing installing sshpass ..."

  if [ "$flavour" == "fedora" ] ; then
    install_epel
    sudo dnf install sshpass -y
    installSspPassResult=$?
  elif [ "$flavour" == "debian" ]; then
    sudo apt-get update
    sudo apt-get -y install sshpass
    installSspPassResult=$?
  else
      echo "Unknown OS flavor $flavour. Skipping sshpass installation..."
      installSspPassResult=1
  fi

  echo "Finished installing installing sshpass"
  return "$installSspPassResult"
}

# Install Bind9 i.e. DNS server
# Args:
#   $1 (dnsServerHostname): The hostname of the dns server e.g. mainframe
#   $2 (domain): The dns zone / domain to configure or managed by the server e.g. homelab.com
#   $3 (dnsServerIpAddress):  The static Ip address of the dns server e.g. 192.168.0.2
#   $4 (cidrBlock): The CIDR block of the network e.g. 192.168.0.0/24
#   $5 (allowDynamicDnsUpdates [Default: true]): if true i.e. (y, yes Yes, YES), the dns server allows clients to dynamically update the
#                                 DNS with their hostnames and Ip address
install_and_configure_dns_server(){
  echo "Configuring and installing DNS server ..."

  local namedConf=/etc/named.conf
  local dnsServerHostname=$1
  local dnsForwardZone=$2
  local dnsServerIpAddress=$3
  local cidrBlock=$4
  local allowDynamicDnsUpdates=${5:-y}
  local dnsForwardZoneFile
  local dnsReverseZoneFile

  backup_file $namedConf

    local flavour
    get_os_flavour flavour

    if [ "$flavour" == "fedora" ] ; then
      install_bind9
      #   $1 (dnsForwardZone): The forward zone (domain) on the dns server
      #   $2 (cidrBlock): The CIDR block of the network e.g. 192.168.0.0/24
      #   $3 (OUT recommendForwardZoneStanzaFileNameOut): When provided, the recommended forward zone file path will be assigned to this variable. If not provided,
      #     the recommended forward zone file name will be echoed to stdout.
      #   $4 (OUT recommendedReverseZoneFilePathOut): When provided, the recommended reverse zone file path will be assigned to this variable. If not provided,
      #     the recommended forward zone file name will be echoed to stdout.
      create_static_dns_named_local_conf "$dnsForwardZone" "$cidrBlock" "$dnsForwardZoneFile" "$dnsReverseZoneFile"

      # Creates a forward zone file for a DNS server
      # Args:
      #   $1 (dnsForwardZone): The zone (i.e domain e.g. homelan.com) of the dns server
      #   $2 (nameserverHostname): The hostname of the DNS server e.g. mainframe
      #   $3 (nameserverIp): The ip address of the name server being configured e.g. 192.168.0.2
      #   $4 (forwardZoneFile): The full file name (full path)  to where the forward zone file should be saved to
      #     e.g. /etc/named/zones/homelan.com.db
      #     See create_static_dns_named_local_conf which will return you a recommended filepath for the forward zone
      create_dns_forward_zone_file "$dnsForwardZone" "$dnsServerHostname" "$dnsServerIpAddress" "$dnsForwardZoneFile"

      #   $1 (dnsReverseZone): The zone (i.e domain e.g. homelan.com) of the dns server
      #   $2 (nameserverHostname): The hostname of the DNS server e.g. mainframe
      #   $3 (nameserverIp): The ip address of the name server being configured e.g. 192.168.0.2
      #   $4 (reverseZoneFile): The full file name (full path)  to where the reverse zone file should be saved to
      #     e.g. /etc/named/zones/192.168.0.db
      #     See create_static_dns_named_local_conf which will return you a recommended filepath for the reverse zone

      create_dns_reverse_zone_file "$dnsForwardZone" "$dnsServerHostname" "$dnsServerIpAddress" "$dnsReverseZoneFile"

      # $1 (cidrBlock): the cidrBlock of the network that the dns provides names for e.g. 192.168.0.0/24
      create_dns_named_conf "$cidrBlock"

      if is_ans_yes "$allowDynamicDnsUpdates"; then
        #   $1 (dnsForwardZone): The forward zone (domain) on the dns server that the key will be used to update
        #   $2 (cidrBlock): The CIDR block of the network e.g. 192.168.0.0/24
        #   $3 (dnsNamedLocalConfFileDir [Default: /etc/named]): The location of the /etc/named/named.local.conf
        create_dynamic_dns_update_key_and_update_named_local_conf_to_allow_dynamic_dns_updates "$dnsForwardZone" "$cidrBlock"
      fi

    elif [ "$flavour" == "debian" ]; then
      install_bind9
    fi

  echo "Finished configuring and installing DNS server ..."
}

# Configures a host Dynamic DNS client. This means that the configured host/client will send Ip and name updates to
# the DNS server
# Args:
#   $1 (dnsServerIp): The IP address if the DNS server
#   $2 (dnsServerName): The name of the DNS server e.g. mainframe
#   $3 (dnsDomain): The domain name of the DNS server e.g. homelan.com
#   $4 (nic): The NIC of the host of the being configured e.g. wlan0
#   $5 (tryObtainDNSUpdateKeyFromDNSServer): if true, the client being configured will try and obtain the dynamic dns update
#                                             key from the DNS server
#   $6 (dnsServerUsername): if tryObtainDNSUpdateKeyFromDNSServer is true, this is required. This is the username used to connect the
#                           dns server to obtain the ddnsUpdate key
#   $7 (dnsServerPassword): if tryObtainDNSUpdateKeyFromDNSServer is true, this is required. This is the password of dnsServerUsername
#                           used to connect the dns server to obtain the ddnsUpdate key
#   $8 (ddnsUpdateKey [Default: /etc/ddnsupdate.key]): The full path to the location of the dynamic dns update on the client.
#     If tryObtainDNSUpdateKeyFromDNSServer is true, the ddnsUpdate key obtained from the server will be written to the provided file path
#   $9 (ddnsKeyLocationOnDnsServer[Default: /etc/ddnsupdate.key]): The location on the DNS server where the dynamic DNS update key is stored.
#                                                                   Note that dnsServerUsername must have permission to read the ddnsUpdateKey
configure_dynamic_dns_client () {

  local dnsServerIp=$1
  local dnsServerName=$2
  local dnsDomain=$3
  local nic=$4
  local tryObtainDNSUpdateKeyFromDNSServer=${5:-true}
  local dnsServerUsername=$6
  local dnsServerPassword=$7
  local ddnsUpdateKey=${8:-/etc/ddnsupdate.key}
  local ddnsKeyLocationOnDnsServer=${9:-/etc/ddnsupdate.key}

  echo "Configuring dynamic dns client ..."
  install_bind9

  if [ -z "$dnsServerIp" ]; then
    echo "The DNS server IP is required. Please supply the DNS server IP as arg 1"
    return 1
  fi

  if [ -z "$dnsServerName" ]; then
      echo "The DNS server name is required. Please supply the DNS server IP as arg 2"
      return 1
    fi

  if [ -z "$dnsDomain" ]; then
      echo "The DNS server domain (zone) is required. Please supply the DNS server IP as arg 3"
      return 1
    fi

  if [ -z "$nic" ]; then
      echo "The network interface card (nic) is required. Please supply the NIC as arg 4"
      return 1
    fi

  if is_true "$tryObtainDNSUpdateKeyFromDNSServer"; then

    if [ -z "$dnsServerUsername" ] ; then
      echo "The dnsServerUsername required when tryObtainDNSUpdateKeyFromDNSServer is true . Please supply the dnsServerUsername server IP as arg 4"
      return 1
    fi
    if [ -z "$dnsServerPassword" ] ; then
      echo "The dnsServerPassword required when tryObtainDNSUpdateKeyFromDNSServer is true . Please supply the dnsServerPassword server IP as arg 5"
      return 1
    fi

    if ! is_package_installed "sshpass"; then
      install_sshpass
    fi

    sshpass -p "$dnsServerPassword" scp -r -o StrictHostKeyChecking=no "$dnsServerUsername"@"$dnsServerIp":"$ddnsKeyLocationOnDnsServer" "$ddnsUpdateKey" && echo $?
    local scpResult=$?

    if [ "$scpResult" -gt 0 ] ; then
      echo "Failed to copy DDNS update key from $dnsServerIp:$ddnsKeyLocationOnDnsServer"
      echo "Copy response code: $scpResult"
      echo "Response codes explained:"
      echo "1      Invalid command line argument

2      Conflicting arguments given

3      General runtime error

4      Unrecognized response from ssh (parse error)

5      Invalid/incorrect password

6      Host public key is unknown. sshpass exits without confirming the new key."
      add_empty_line
      echo "Do you want to continue setup?"
      echo "*******Note******"
      echo "If you continue, please make sure that there is a valid dynamic dns update key at $ddnsUpdateKey else dynamic DNS updates will not work"
      echo "*************"
      print_confirmation_instructions

      local continueConf
      read continueConf

      if ! is_answer_yes "$continueConf" ; then
        return 1
      fi
    fi

  fi

  #   $1 (nameserverHostname): the name of the nameserver (i.e DNS nameserver)
  #   $2 (nic): The name of the nic whose ip will be sent to the DNS server as part of the DNS A record.
  #   $3 (domainName) - the domain name of the DNS server
  #   $4 (dnsUpdateKey [Default: /etc/ddnsupdate.key]) - The path to the key that is used to update the dns.

  #   The key should be obtained from the admin of the DNS server
  create_dns_publisher_systemd_timer "$dnsServerName" "$nic" "$dnsDomain" "$ddnsUpdateKey"

  echo "Finished configuring dynamic dns client"

}

# Configures the keymap i.e the keyboard settings
# Args:
#   $1 (keymap) [Default=us]: the key to use
#   $2 (vconsoleConf) : The path to the console configuration file. Usually /etc/vconsole.conf
configure_keymap () {

  echo "Configuring keymap ..."
  local keymap=${1:-"us"}
  local vconsoleConf=$2


  if grep -iP "^KEYMAP=.*$" $vconsoleConf ; then
   # Delete the keymap stanza in /etc/vconsole.conf and replace it with $keymap
   sed -i '/^KEYMAP=.*$/d' $vconsoleConf
   echo "Updating $vconsoleConf with keymap keymap"
   echo "KEYMAP=\"$keymap\"" >> $vconsoleConf
  else
   echo "Font not set in $vconsoleConf "
   echo "Adding font $powerline_tty_font to $vconsoleConf"
    echo "KEYMAP=\"$powerline_tty_font\"" >> $vconsoleConf
  fi
  echo "Finished configuring keymap"
}
# Installs google chrome
install_google_chrome () {
  # Install Google Chrome
  echo "Installing Google Chrome ..."
  local flavour
  get_os_flavour flavour
  cd /tmp

  if [ "$flavour" == "fedora" ] ; then
      wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
      sudo dnf localinstall google-chrome-stable_current_x86_64.rpm -y
  elif [ "$flavour" == "debian" ]; then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install ./google-chrome-stable_current_amd64.deb
 fi
  #google-chrome &

  echo "Google Chrome Completed!..."
}

# Configures the hostname
# Args:
#   $1 (hostname): the hostname of the host being configured e.g. mainframe
configure_hostname () {
  # Configure the hostname
  echo "Configuring the hostname in /etc/hostname ..."
  local hostname=$1
  local hostnameFile=/etc/hostname

  if [ -z "$hostname" ]; then
     echo "The hostname of the server being configured is required. Please supply the hostname as arg 1"
     return 1
  fi

  echo "Backing up $hostnameFile ..."
  backup_file $hostnameFile
  echo "$hostname" > /etc/hostname
  echo "Finished configuring the hostname in $hostnameFile ..."
}

# Configure the default gateway
# Args:
#   $1 (gatewayIpAddress): the ip address of the default gateway e.g. 192.168.0.1
#   $2 (hostname): the hostname of the host being configured e.g. mainframe
configure_default_gateway() {
  echo "Configuring the default gateway ..."
  local gatewayIpAddress=$1
  local hostname=$2

  if [ -z "$gatewayIpAddress" ]; then
      echo "The gateway ip address is required. Please supply the gateway ip address as arg 1"
      return 1
  fi

  if [ -z "$hostname" ]; then
     echo "The hostname of the server being configured is required. Please supply the hostname as arg 2"
     return 1
  fi


  local flavour
  get_os_flavour flavour

  if [ "$flavour" == "fedora" ] ; then
      local networkFile=/etc/sysconfig/network
      backup_file $networkFile

      echo "NETWORKING=yes
HOSTNAME=$hostname
GATEWAY=$gatewayIpAddress" > $networkFile
  elif [ "$flavour" == "debian" ]; then
    echo "Default Gateway not configuration not supported in Debian based systems. Skipping"
  fi

}

# Configures /etc/resolv.conf
# Args:
# $1 (hostname) : the hostname of the host being configured /etc/resolv.conf
# $2 (useLocalDNS) : if this is set to 'y', will add local nameserver  to /etc/resolv.conf
# $3 (localNameserverIp): the ip address of the local nameserver. Only required if useLocalDNS ='y'
# $4 (localDNSDomainName): the domain name of the local nameserver e.g homelan.com. Only required if useLocalDNS ='y'

configure_resolv_conf(){
  local hostname=$1
  local useLocalDNS=$2
  local localNameserverIp=$3
  local localDNSDomainName=$4
  local resolv_conf=/etc/resolv.conf
  echo "Creating $resolv_conf ..."
  backup_file $resolv_conf

  while [ -z "$hostname" ]
      do
        echo  "hostname is required to configure $resolv_conf"
        read hostname
        add_empty_line
      done

  if is_true "$useLocalDNS"  ; then


    while [ -z "$localNameserverIp" ]
      do
        echo  "Local nameserver IP is required to configure local DNS"
        read localNameserverIp
        add_empty_line
      done

    while [ -z "$localNameserverIp" ]
      do
        echo  "Local DNS domain name (e.g. homelan.com)  is required to configure local DNS"
        read localDNSDomainName
        add_empty_line
      done

    local localDnsSearchStanza="search $localDNSDomainName"
    localDnsNameserverStanza="nameserver $localNameserverIp"
  fi

  echo "# $HOSTNAME resolv.conf

$localDnsSearchStanza
$localDnsNameserverStanza

# Google name servers i.e. Google DNS Servers
nameserver 8.8.8.8
nameserver 8.8.1.1

# Cloudflare name servers i.e Cloudflare DNS Servers
#nameserver 1.1.1.1
" > $resolv_conf

  echo "Finished creating $resolv_conf"
}

# Configure wpa_supplicant
# Args:
#   $1 (nic) : The network interface card to be configured
#   $2 (nicIp): The ip address of the NIC.
#   $3 (ssid): The SSID of the WiFi network.
#   $4 (wifiPassword): The password of the WiFi network.
#   $5 (nicConfigFile): The network configuration file of the NIC card
#   $6 (nicConfigBasePath): The path to the directory containing network configuration files of the NIC card including
#                           the NIC prefix e.g. /etc/sysconfig/network-scripts/ifcfg-
configure_wpa_supplicant() {
  local nic=$1
  local nicIp=$2
  local ssid=$3
  local wifiPassword=$4
  local nicConfigFile=$5
  local nicConfigBasePath=$6

  echo "Configuring wpa_supplicant ..."
  if [ "$flavour" == "fedora" ] ; then

    # Create / Update the /etc/sysconfig/network-scripts/ifcfg-SSID or /etc/sysconfig/network-scripts/ifcfg-NIC
    # with static ip deteails
    # returns NIC config file name in env var named nicConfigFile
    get_nic_config_file $nic $ssid
    backup_file $nicConfigFile
    if [ -f "$nicConfigFile" ]; then
        echo "updating $$nicConfigBasePath config $nicConfigFile with networking details ..."
        if [ -f "$BACKED_UP_FILE" ]; then
            local nicConfigFile_BACKUP=$(echo $nicConfigFile | sed -e 's/ifcfg/__ifcfg/gI')
            echo "renaming $BACKED_UP_FILE to $nicConfigFile_BACKUP"
            mv -v $BACKED_UP_FILE $nicConfigFile_BACKUP
        fi

        if grep -qi "BOOTPROTO" "$nicConfigFile"; then
            # Delete the line containing the BOOTPROTO stanza
            sed -i '/BOOTPROTO/Id' $nicConfigFile
            # append BOOTPROTO stanza
            echo "BOOTPROTO=static" >> $nicConfigFile
        fi

        if grep -qi "IPADDR" "$nicConfigFile"; then
            # Delete the line containing the IPADDR stanza
            sed -i '/IPADDR/Id' $nicConfigFile
            # append IPADDR stanza
            echo "IPADDR=${nicIp}" >> $nicConfigFile
        fi
    else
      echo "creating new $nicConfigBasePath$nic ..."
      echo "#
# File: ifcfg-$nic
#
DEVICE=$nic
IPADDR=$nicIp
NETMASK=255.255.255.0
BOOTPROTO=static
ONBOOT=yes
#
# The following settings are optional
#
BROADCAST=192.168.0.255
NETWORK=192.168.0.0" > $nicConfigBasePath$nic
      echo "finished creating $nicConfigBasePath$nic"
    fi


    local wpaSupplicantConf=/etc/wpa_supplicant/wpa_supplicant.conf
    backup_file $wpaSupplicantConf
    echo "creating new $wpaSupplicantConf"
    wpa_passphrase $ssid $wifPassword> $wpaSupplicantConf
    echo "Finished configuring wpa_supplicant ..."
 elif [ "$flavour" == "debian" ]; then
    echo "WPA_Supplicant configuration on Debian flavoured systems is currently not supported. Skipping ..."
 fi
}


# Configure the NIC for NetworkManager
# Args:
#   $1 (nic) : The name of the network interface card (NIC) e.g. wlan0
#   $3 (nic_ip): The ip address of the NIC
#   $3 (ssid): the SSID of the Wifi to connect to
#   $5 (defaultGateway): The ip address of the default gateway
configure_NIC_for_NetworkManager(){
  local nic=$1
  local nic_ip=$2
  local ssid=$3
  local defaultGateway=$4
  echo "Configuring NIC $nic for NetworkManager ..."
  local dns_none_config_stanza="dns=none"
  local network_dns_override_conf=/etc/NetworkManager/conf.d/no-dns-override.conf
  local network_manager_conf=/etc/NetworkManager/NetworkManager.conf

  if [ -z "$nic" ]; then
     echo "The name of the network interface card  (e.g. wlan0) is required. Please supply the nic as arg 1"
     return 1
  fi

  if [ -z "$nic_ip" ]; then
      echo "The nic ip is required. Please supply the nic ip name as arg 2"
      return 1
  fi

  if [ -z "$ssid" ]; then
    echo "The SSID is required. Please supply the SSID as arg 3"
    return 1
  fi

  if [ -z "$defaultGateway" ]; then
    echo "The default gateway is required. Please supply the default gateway as arg 4"
    return 1
  fi


  if  ! grep -q $dns_none_config_stanza $network_manager_conf  ; then
    echo "dns=none not found in $network_manager_conf"
#    backup_file $network_manager_conf
#    local comment="#inserted by George's post new install config script"
#    insert_after /etc/NetworkManager/NetworkManager.conf "\[main\]" "$comment"
#    insert_after /etc/NetworkManager/NetworkManager.conf "$comment" $dns_none_config_stanza
    echo "Creating NetworkManager dns override config at $network_dns_override_conf"
    echo -e "[main]
#Added by George Badu new install post setup script
#Prevents NetworkManager from overwriting /etc/resolv.conf
dns=none" > $network_dns_override_conf

  fi
  systemctl restart NetworkManager.service
  systemctl enable NetworkManager.service

  backup_file /etc/NetworkManager/system-connections/$ssid.nmconnection
  nmcli con mod $ssid ipv4.addresses $nic_ip/24
  nmcli con mod $ssid ipv4.gateway $defaultGateway
  nmcli con mod $ssid ipv4.method manual
  # nmcli con mod $SSID ipv4.dns "8.8.8.8 8.8.1.1"
  systemctl restart NetworkManager.service
  nmcli con down $ssid
  nmcli con up $ssid
  echo "Finished configuring NIC $nic for NetworkManager"

}

#Configure, update and setup raid
configure_raid() {

  echo "Configuring Raid ..."
  local raidConf=/etc/mdadm.conf
  backup_file $raidConf
  mdadm --examine --scan > $raidConf
  mdadm --assemble --scan
  echo "Finished configuring Raid ..."
}

# Installs ZSH and configures Oh-My-ZSH
# Args:
#   $1 (userUnderConfig): The user for whom zsh and oh-my-zsh is being configured for
#   $2 (userUnderConfigHome): The HOME directory of userUnderConfig
#   $3 (vconsoleConf):he path to the console configuration file. Usually /etc/vconsole.conf

install_zsh_and_oh_my_zsh() {

  if [ -z $userUnderConfig ] ; then
    echo "The username of the user under configuration is required. Please provide the username for the user under configuration"
    return 1
  fi

  if [ -z $userUnderConfigHome ] ; then
      echo "The HOME directory of user $userUnderConfig is required. Please provide the HOME directory of user $userUnderConfig"
      return 1
  fi

   if [ -z $vconsoleConf ] ; then
        echo "The path to vconsole configuration is required. Please provide the path to vconfiguration"
        echo "If your are using a Fedora flavoured system such as Centos, RHEL or AlmaLinux, this will usually be /etc/vconsole.conf"
        return 1
    fi

  local userUnderConfig=$1
  local userUnderConfigHome=$2
  # Install Oh My ZSH
  echo "Installing zsh ..."
  yum install zsh -y
  chsh -s /bin/zsh $userUnderConfig
  echo "Finished installing zsh ..."

  add_empty_line

  echo "Installing Oh-My-Zsh ..."
  local origHome=$HOME
  HOME=$userUnderConfigHome
  ZSH=$userUnderConfigHome/.oh-my-zsh
  ZSH_CUSTOM=$ZSH/custom


  delete_dir $ZSH

  # ZSH=$userUnderConfigHome/.oh-my-zsh sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" | zsh -c exit
  wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
  # INSTALL_SCRIPT=$(wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O -)
  # echo "INSTALL_SCRIPT: $INSTALL_SCRIPT"

  /bin/cp $userUnderConfigHome/.oh-my-zsh/templates/zshrc.zsh-template $userUnderConfigHome/.zshrc
  echo "Finished installing Oh-My-Zsh ..."

  add_empty_line

  echo "Configuring Oh-My-Zsh ..."
  add_empty_line
  # Install powerline fonts
  install_powerline_fonts $userUnderConfigHome $vconsoleConf
  add_empty_line

#  echo "Sourcing $userUnderConfigHome/.zshrc..."
#  /bin/zsh -c "HOME=$userUnderConfigHome source $userUnderConfigHome/.zshrc"

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
  delete_dir ${userUnderConfigHome}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  /bin/zsh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-${userUnderConfigHome}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions --quiet"

  add_empty_line

  # Install zsh-syntax-highlighting
  echo "Installing zsh-syntax-highlighting ..."
  delete_dir ${userUnderConfigHome}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  /bin/zsh -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$userUnderConfigHome/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting --quiet"

  add_empty_line

  # Write ~/.zshrc
  # Create ~/.zshrc
  echo "Creating custom $userUnderConfigHome/.zshrc ..."
  backup_file $userUnderConfigHome/.zshrc

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

# If we are in the TTY terminal console, set the font to ter-powerline-v14n
if tty | grep -iP "^/dev/tty[1-6]{1,1}" ; then
  echo "Setting font to Powerline TTY font ter-powerline-v14n"
  setfont ter-powerline-v14n
fi

# Key Bindings
# Alt -> to jump one word forward
bindkey "[C" forward-word

# Alt <- to jump one word backward
bindkey "[D" backward-word

# Delete Word Backword bound to Alt+Backspace
# bindkey "^[^?" backward-kill-word

' > $userUnderConfigHome/.zshrc

  HOME=$origHome

  echo "Finished creating custom $userUnderConfigHome/.zshrc "

  add_empty_line

  # CHMOD $userUnderConfigHome/.oh-my-zsh to allow read, write execute to $USER_UNDER_CONFIG
  echo "Changing ownership of $userUnderConfigHome/.oh-my-zsh to $userUnderConfig ..."
  chown -R $userUnderConfig $userUnderConfigHome/.oh-my-zsh
  chmod -R u+rwx $userUnderConfigHome/.oh-my-zsh

  echo "Changing ownership of $userUnderConfigHome/.zsh* to $userUnderConfig ..."
  chown -R $userUnderConfig $userUnderConfigHome/.zsh*
  chmod -R u+rwx $userUnderConfigHome/.zsh*

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

# Returns the ip of the given network interface card (NIC) in the nicIp out variable. If not
# Args:
#   $1 (nic): The name of the nic whose ip will be sent to the DNS server as part of the DNS A record
#   $2 (out nicIp): The ip of the NIC will be placed in this variable when supplied by the caller of this method
get_ip() {
  local nic=$1
  local ___result___=$2

  if [ -z "$nic" ]; then
    echo "Please provide the name of the network interface card (NIC  i.e. arg 1)"
    echo "You can issue the command 'ip a' to inspect the  network interface cards on your host"
    add_empty_line
    return 1
  fi
  local ipAddr
  ipAddr=$(ip addr show $nic | grep inet|grep -v inet6 | awk '{print $2}'| awk '{split($0,a,"/"); print a[1]}')
  return_function_result "$ipAddr"  "$___result___"
}


# Create and configures a script located at /opt/dns_updates_publisher/dns_updates_publisher.sh on a host to update the DNS record (i.e the hosts A record)
# on a DNS server. This will add the host to the same zone (domain / network) as the dns .
# This is the script is designed to be maintained by a systemd timer
# Args:
#   $1 (nameserverName): the name of the nameserver (i.e DNS nameserver)
#   $2 (nic): The name of the nic whose ip will be sent to the DNS server as part of the DNS A record.
#   $3 (domainName) - the domain name of the DNS server
#   $4 (dnsUpdateKey [Default: /etc/ddnsupdate.key]) - The path to the key that is used to update the dns.
#   The key should be obtained from the admin of the DNS server
create_and_configure_dns_updates_publisher_script() {
  echo "Creating and configuring dns updater script"
  local nameserverName=$1
  local nic=$2
  local domainName=$3
  local dnsUpdateKey=$4
  local dns_publisher_install_dir=/opt/dns_updates_publisher
  local dns_publisher_script=$dns_publisher_install_dir/dns_updates_publisher.sh
  mkdir -p $dns_publisher_install_dir
  KEY=/etc/ddnsupdate.key


  if [ -z "$nameserverName" ]; then
      echo "Nameserver Name (i.e DNS server name e.g. mainframe) was not provided. Nameserver is required"
     return  1
  fi

  if [ -z "$domainName" ]; then
      echo "Nameserver domain (i.e DNS server  domain name e.g homelan.com) was not provided. Nameserver domain is required"
      return  1
  fi

  if [ -z "$nic" ]; then
    echo "Please provide the name of the network interface card (NIC  i.e. arg 1)"
    echo "You can issue the command 'ip a' to inspect the  network interface cards on your host"
    add_empty_line
    return 1
  fi

  if [ -z "$dnsUpdateKey" ]; then
    echo "DNS update key path not supplied. Using default path of /etc/ddnsupdate.key "
    dnsUpdateKey=/etc/ddnsupdate.key
  fi

  if [ ! -e $dnsUpdateKey ] ; then
    echo "The DNS update key file cannot be found"
    echo "Please copy the DNS update key from your DNS server to location $KEY"
    return 1
  fi

  local ns=$nameserverName.$domainName
  local domain=$HOSTNAME.$domainName.
  local zone=$domainName.

  local nicIp
  get_ip $nic nicIp
  echo "NIC_IP -> $nicIp"
  cat <<-STOP > $dns_publisher_script
#!/bin/bash
echo "Sending DNS update"
nsupdate -k $dnsUpdateKey -v <<-EOF
server $ns
zone $zone
update delete $domain A
update add $domain 30 A $nicIp
send
EOF
STOP

  chmod +x $dns_publisher_script
  echo "Finished creating and configuring dns updater script"
}

# Creates Systemd Service that issued to update the DNS Server with the name and Ip address
# of the host that the service runs on. The systemd service unit will be located at /etc/systemd/system/dns_publisher.service
#   $1 (nameserverHostname): the name of the nameserver (i.e DNS nameserver)
#   $2 (nic): The name of the nic whose ip will be sent to the DNS server as part of the DNS A record.
#   $3 (domainName) - the domain name of the DNS server
#   $4 (dnsUpdateKey [Default: /etc/ddnsupdate.key]) - The path to the key that is used to update the dns.
#   The key should be obtained from the admin of the DNS server
create_dns_publisher_systemd_service() {

  echo "Creating DNS publisher systemd service ..."
  local dns_publisher_install_dir=/opt/dns_publisher
  local dns_publisher_script=$dns_publisher_install_dir/dns_publisher.sh
  local dns_publisher_service_path=/etc/systemd/system/dns_publisher.service
  local nameserverHostname=$1
  local nic=$2
  local domainName=$3
  local dnsUpdateKey=$4

  if [ -z "$nameserverHostname" ]; then
      echo "The nameserver host name (e.g. mainframe) is required. Please supply the nameserner name as arg 1"
      return 1
  fi

  if [ -z "$nic" ]; then
    echo "The name of the network interface card  (e.g. wlan0) is required. Please supply the nic as arg 2"
    return 1
  fi

  if [ -z "$domainName" ]; then
      echo "The domain name (zone) is required. Please supply the nic as arg 3"
      return 1
  fi

  create_and_configure_dns_updates_publisher_script $nameserverHostname $nic $domainName $dnsUpdateKey

  cat <<-EOF > $dns_publisher_service_path
[Unit]
Description=A Systemd service that publishes the  hostname and Ip address (i.e DNS A records) of this host (i.e $HOSTNAME)  to the DNS server

[Service]
Type=simple
ExecStart=$dns_publisher_script

[Install]
WantedBy=multi-user.target
EOF
  echo "Finished creating DNS publisher systemd service"

}

# Creates Systemd Timer that is used to update the DNS Server with the name and Ip address
# of the host that the timer runs on. The systemd timer unit will be located at /etc/systemd/system/dns_publisher.timer
#   $1 (nameserverHostname): the name of the nameserver (i.e DNS nameserver)
#   $2 (nic): The name of the nic whose ip will be sent to the DNS server as part of the DNS A record.
#   $3 (domainName) - the domain name of the DNS server
#   $4 (dnsUpdateKey [Default: /etc/ddnsupdate.key]) - The path to the key that is used to update the dns.
#   The key should be obtained from the admin of the DNS server
create_dns_publisher_systemd_timer() {

  echo "Creating DNS publisher systemd timer ..."
  local timerName=dns_publisher.timer
  local dns_publisher_service_path=/etc/systemd/system/dns_publisher.service
  local dns_publisher_timer_path=/etc/systemd/system/$timerName
  local nameserverHostname=$1
  local nic=$2
  local domainName=$3
  local dnsUpdateKey=$4

  if [ -z "$nameserverHostname" ]; then
      echo "The nameserver host name (e.g. mainframe) is required. Please supply the nameserner name as arg 1"
      return 1
  fi

  if [ -z "$nic" ]; then
     echo "The name of the network interface card  (e.g. wlan0) is required. Please supply the nic as arg 2"
     return 1
  fi

    if [ -z "$domainName" ]; then
       echo "The domain name (zone) is required. Please supply the nic as arg 3"
       return 1
    fi

  create_dns_publisher_systemd_service $nameserverHostname $nic $domainName $dnsUpdateKey

  cat <<-EOF > $dns_publisher_timer_path
[Unit]
Description=A Systemd timer that publishes the  hostname and Ip address (i.e DNS A records) of this host (i.e $HOSTNAME) to the DNS server

[Timer]
#Execute job if it missed a run due to machine being off
Persistent=true
#Run 120 seconds after boot for the first time
OnBootSec=1
#Run every 1 minute thereafter
OnUnitActiveSec=60
Unit=$dns_publisher_service_path

[Install]
WantedBy=timers.target
EOF
  systemctl enable $timerName
  systemctl restart $timerName
  echo "Finished and configuring creating DNS publisher systemd timer"

}


# Creates the bind9 /etc/named/named.local.conf
# Args:
#   $1 (dnsForwardZone): The forward zone (domain) on the dns server
#   $2 (cidrBlock): The CIDR block of the network e.g. 192.168.0.0/24
#   $3 (OUT recommendForwardZoneStanzaFileNameOut): When provided, the recommended forward zone file path will be assigned to this variable. If not provided,
#     the recommended forward zone file name will be echoed to stdout.
#   $4 (OUT recommendedReverseZoneFilePathOut): When provided, the recommended reverse zone file path will be assigned to this variable. If not provided,
#     the recommended forward zone file name will be echoed to stdout.
#   Example Usage: create_static_dns_named_local_conf "$dnsForwardZone" "192.168.0.0/24"  recommendForwardZoneStanzaFileNameOut recommendedReverseZoneFilePathOut
#   Note: the forward zone files are assumed to be named "$dnsNamedLocalConfFileDir/$dnsForwardZone.db" e.g. /etc/named/zones/homelan.com.db .
#   The reverse zone file is assumed to be named "$dnsNamedLocalConfFileDir/NETWORK_PREFIX.db" e.g. /etc/named/zones/192.168.0.db
create_static_dns_named_local_conf() {

  local dnsForwardZone=$1
  local cidrBlock=$2
  local dnsNamedLocalConfFileDir=${5:-/etc/named}
  local dnsNamedLocalConf=$dnsNamedLocalConfFileDir/named.local.conf
  local __recommendedforwardZoneFilelPath__=$3
  local __recommendedReverseZoneFilelPath__=$4
  local dnsUpdateKey=/etc/ddnsupdate.key
  local forwardZoneStanza
  local reverseZoneStanza
  local __forwardZoneFile__
  local __reverseZoneFile__

  echo "Creating static DNS $dnsNamedLocalConf ..."

  if [ -z "$dnsForwardZone" ]; then
      echo "DNS Zone (domain) is required. Please supply dns zone as arg 1"
      return 1
  fi

  if [ -z "$cidrBlock" ] ; then
        echo "The CIDR block for the DNS is required to create the reverse zone of the DNS"
        echo "Please provide the CIDR block as arg 2"
        return 1
   fi

   echo "dnsNamedLocalConfFileDir -> $dnsNamedLocalConfFileDir"
   if [ "$dnsNamedLocalConfFileDir" ] && [ ! -d "$dnsNamedLocalConfFileDir" ] ; then
        echo "The named config (Bind9) directory $dnsNamedLocalConfFileDir cannot be found"
        echo "Please provide a path to the named config  directory as arg 3 or make sure that $dnsNamedLocalConfFileDir exists"
        return 1
    fi

  backup_file "$dnsNamedLocalConf"

  create_forward_zone_stanza_and_recommended_forward_zone_file_name "$dnsForwardZone" forwardZoneStanza  __forwardZoneFile__
  create_reverse_zone_stanza_and_recommended_reverse_zone_file_name "$cidrBlock" reverseZoneStanza __reverseZoneFile__

  echo "Overwriting $dnsNamedLocalConf with new static zone config ..."
  cat <<- EOF > $dnsNamedLocalConf
  $forwardZoneStanza

  $reverseZoneStanza
EOF
  echo "Finished creating static DNS $dnsNamedLocalConf"

  return_function_result "$__forwardZoneFile__" "$__recommendedforwardZoneFilelPath__"
  return_function_result "$__reverseZoneFile__" "$__recommendedReverseZoneFilelPath__"

}

# Creates a forward zone file for a DNS server
# Args:
#   $1 (dnsForwardZone): The zone (i.e domain e.g. homelan.com) of the dns server
#   $2 (nameserverHostname): The hostname of the DNS server e.g. mainframe
#   $3 (nameserverIp): The ip address of the name server being configured e.g. 192.168.0.2
#   $4 (forwardZoneFile): The full file name (full path)  to where the forward zone file should be saved to
#     e.g. /etc/named/zones/homelan.com.db
#     See create_static_dns_named_local_conf which will return you a recommended filepath for the forward zone

create_dns_forward_zone_file() {
  echo "Creating DNS forward zone file ..."
  local dnsForwardZone=$1
  local nameserverHostname=$2
  local nameserverIp=$3
  local forwardZoneFile=$4
  local forwardZoneFileDir
  local nameserverfqdn=$nameserverHostname.$dnsForwardZone.

   if [ -z "$dnsForwardZone" ]; then
        echo "DNS Zone (domain) is required. Please supply dns zone as arg 1"
        return 1
    fi

  if [ -z "$nameserverHostname" ]; then
        echo "The nameserver host name is required. Please supply the nameserner name as arg 2"
        return 1
  fi

    if [ -z "$nameserverIp" ]; then
          echo "The nameserver Ip is required. Please supply the nameserver ip as arg 3"
          return 1
    fi

     if [ -z "$forwardZoneFile" ]; then
              echo "The forward zone file path is required. Please supply the forward zone file path as arg 4"
              return 1
     fi

  # Extract the forward zone file directory from the forward zone file full path
  forwardZoneFileDir=$(dirname "$forwardZoneFile")

  #  Create the forwardZoneFileDir if it does not exist
  if [ ! -d "$forwardZoneFileDir" ] ; then
      echo "Creating forward zone file directory ..."
      mkdir -p "$forwardZoneFileDir"
  fi

  backup_file "$forwardZoneFile"

  cat <<EOF > $forwardZoneFile

$TTL    604800
@       IN      SOA     $nameserverfqdn admin.$dnsForwardZone. (
                    3       ; Serial
               604800     ; Refresh
                86400     ; Retry
              2419200     ; Expire
               604800 )   ; Negative Cache TTL
;
; name servers - NS records
       IN      NS      $nameserverfqdn

; name servers - A records
$nameserverfqdn.   IN      A       $nameserverIp

  ; 192.168.0.0/24 - A records
EOF

  echo "Finished creating DNS forward zone file ..."

}

# Creates a reverse zone file for a DNS server
# Args:
#   $1 (dnsForwardZone): The zone (i.e domain e.g. homelan.com) of the dns server
#   $2 (nameserverHostname): The hostname of the DNS server e.g. mainframe
#   $3 (nameserverIp): The ip address of the name server being configured e.g. 192.168.0.2
#   $4 (reverseZoneFile): The full file name (full path)  to where the reverse zone file should be saved to
#     e.g. /etc/named/zones/192.168.0.db
#     See create_static_dns_named_local_conf which will return you a recommended filepath for the reverse zone

create_dns_reverse_zone_file() {
  echo "Creating DNS reverse zone file ..."
  local dnsForwardZone=$1
  local nameserverHostname=$2
  local nameserverIp=$3
  local reverseZoneFile=$4
  local reverseZoneFileDir
  local nameserverfqdn=$nameserverHostname.$dnsForwardZone.

   if [ -z "$dnsForwardZone" ]; then
        echo "DNS Zone (domain) is required. Please supply dns zone as arg 1"
        return 1
    fi

  if [ -z "$nameserverHostname" ]; then
        echo "The nameserver host name is required. Please supply the nameserner name as arg 2"
        return 1
  fi

    if [ -z "$nameserverIp" ]; then
          echo "The nameserver Ip is required. Please supply the nameserver ip as arg 3"
          return 1
    fi

     if [ -z "$reverseZoneFile" ]; then
          echo "The reverser zone file path is required. Please supply the reverse zone file path as arg 4"
          return 1
     fi

  # Extract the forward zone file directory from the forward zone file full path
  reverseZoneFileDir=$(dirname "$reverseZoneFile")

  # Create the reverseZoneFileDir if it does not exist
  if [ ! -d "$reverseZoneFileDir" ] ; then
      echo "Creating reverse zone file directory ..."
      mkdir -p "$reverseZoneFileDir"
  fi

  backup_file "$reverseZoneFile"

  cat <<EOF > $reverseZoneFile

$TTL    604800
@       IN      SOA     $nameserverfqdn admin.$dnsForwardZone. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
; name servers
      IN      NS     $nameserverfqdn

; PTR Records
2   IN      PTR     $nameserverfqdn    ; $nameserverIp
EOF

  echo "Finished creating DNS reverse zone file ..."

}

# Created a /etc/named.conf configuration file for a Bind9 (named) DNS server
# Args:
#   $1 (cidrBlock): the cidrBlock of the network that the dns provides names for e.g. 192.168.0.0/24
create_dns_named_conf() {

  local namedConf=/etc/named.conf
  local networkIp
  echo "Creating $namedConf ..."
  local cidrBlock=$1

  if [ -z "$cidrBlock" ] ; then
      echo "The CIDR block for the DNS is required to create the reverse zone of the DNS"
      echo "Please provide the CIDR block as arg 1"
      return 1
  fi

  if ! is_valid_cidr "$cidrBlock" ; then
    echo "Invalid CIDR block"
    echo "Please provide a CIDR block e.g. 192.168.0.0/24"
  fi

  extract_network_ip_and_network_prefix_from_cidr_block "$cidrBlock" networkIp

  backup_file "$namedConf"
  cat <<EOF > $namedConf
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {
#       listen-on port 53 { 127.0.0.1; };
#       listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
#       allow-query     { localhost; };
/* Note the $cidrBlock i.e. the private home network
The stanza below means that we allow recursive queries from localhost
and network $cidrBlock (i.e subnet 255.255.255.0)
*/
        allow-query     { localhost;$cidrBlock; };

        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;

        dnssec-validation yes;

        managed-keys-directory "/var/named/dynamic";
        geoip-directory "/usr/share/GeoIP";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";

        /* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
        include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
# Include the zone file for the local domain i.e. the local network i.e. $networkIp
include "/etc/named/named.local.conf";
EOF
   echo "Finished creating $namedConf ..."
}

# Creates the dynamic dns update key and also updates the bind9 /etc/named/named.local.conf
# to allow updates of the zone files by a client if the client has a valid ddns update key
# Args:
#   $1 (dnsForwardZone): The forward zone (domain) on the dns server that the key will be used to update
#   $2 (cidrBlock): The CIDR block of the network e.g. 192.168.0.0/24
#   $3 (dnsNamedLocalConfFileDir [Default: /etc/named]): The location of the /etc/named/named.local.conf
#   Note: the forward zone files are assumed to be named "$dnsNamedLocalConfFileDir/$dnsForwardZone.db" e.g. /etc/named/zones/homelan.com.db .
#   The reverse zone file is assumed to be named "$dnsNamedLocalConfFileDir/NETWORK_PREFIX.db" e.g. /etc/named/zones/192.168.0.db

create_dynamic_dns_update_key_and_update_named_local_conf_to_allow_dynamic_dns_updates(){

  echo "Creating Dynamic DNS update key and updating DNS zone files to allow updates ..."
  local dnsForwardZone=$1
  local cidrBlock=$2
  local dnsNamedLocalConfFileDir=${3:-/etc/named}
  local dnsNamedLocalConf=$dnsNamedLocalConfFileDir/named.local.conf
  local forwardZoneFile=$dnsNamedLocalConfFileDir/zones/$dnsForwardZone.db
  local dnsUpdateKey=/etc/ddnsupdate.key
  local forwardZoneStanza
  local reverseZoneStanza
  local updatePolicyStanza="  update-policy {\n    grant ddns-key.$dnsForwardZone zonesub ANY;\n   };"

  if [ -z "$dnsForwardZone" ]; then
      echo "DNS Zone (domain) is required. Please supply dns zone as arg 1"
      return 1
  fi

  if [ -z "$cidrBlock" ] ; then
        echo "The CIDR block for the DNS is required to create the reverse zone of the DNS"
        echo "Please provide the CIDR block as arg 2"
        return 1
   fi

   if [ "$dnsNamedLocalConfFileDir" ] && [ ! -d "$dnsNamedLocalConfFileDir" ] ; then
        echo "The named config (Bind9) directory $dnsNamedLocalConfFileDir cannot be found"
        echo "Please provide a path to the named config  directory as arg 3 or make sure that $dnsNamedLocalConfFileDir exists"
        return 1
    fi

   if [ ! -f "$forwardZoneFile" ] ; then
        echo "Cannot find forward zone file $forwardZoneFile"
        echo "Please ensure that the forwardZoneFile exists and try again"
        return 1
    fi

  cat <<EOF > $dnsUpdateKey
key "ddns-key.REPLACE_WITH_DNS_ZONE" {
  algorithm hmac-sha256;
  REPLACE_WITH_SECRET
};
EOF

  # Generate Dynamic DNS update key
  # The line below generates a key and then extract the secret line from the key
  local secretLine
  secretLine=$(ddns-confgen -z "$dnsForwardZone" | sed -En '/^.*secret.*$/p'| sed -En 's/^[ \t]*//pg');
  # Substitute REPLACE_WITH_DNS_ZONE placeholder in the template with the supplied DNS forward zone
  sed -i "s/REPLACE_WITH_DNS_ZONE/$dnsForwardZone/g"  "$dnsUpdateKey";
  # Substitute REPLACE_WITH_SECRET placeholder in the template with the secret
  sed -i "s|REPLACE_WITH_SECRET|$secretLine|g" "$dnsUpdateKey";

  backup_file "$dnsNamedLocalConf"

  create_forward_zone_stanza_and_recommended_forward_zone_file_name "$dnsForwardZone" forwardZoneStanza
  create_reverse_zone_stanza_and_recommended_reverse_zone_file_name "$cidrBlock" reverseZoneStanza

  # Replace the "allow-update" line with the update-policy
  forwardZoneStanza=$(echo "$forwardZoneStanza" | sed "s|^.*allow-update.*$|$updatePolicyStanza|")
  reverseZoneStanza=$(echo "$reverseZoneStanza" | sed "s|^.*allow-update.*$|$updatePolicyStanza|")

  echo "Overwriting $dnsNamedLocalConf with new updatable zone config ..."
  cat <<- EOF > $dnsNamedLocalConf
  $forwardZoneStanza

  $reverseZoneStanza
EOF
  echo "Finished creating Dynamic DNS update key and updating DNS zone files to allow dynamic updates"
}

# Creates and returns the forward zone stanza and also a recommended file name that could be used as the file name of the forward
# zone file
# Args:
#   $1 (zone): The forward zone i.e. the domain of the dns
#   $2 (OUT forwardZoneStanzaOut): When provided, the reverse zone stanza will be assigned to this variable. If not provided,
#     the reverse zone stanza will be echoed to stdout
#   $3 (OUT recommendForwardZoneStanzaOutFileNameOut): When provided, the recommended forward zone file path will be assigned to this variable. If not provided,
#     the recommended forward zone file name will be echoed to stdout.
#     Example Usage: create_forward_zone_stanza_and_recommended_forward_zone_file_name "$dnsForwardZone" forwardZoneStanza recommendForwardZoneStanzaOutFileNameOut
#     **Note** OUT forwardZoneStanzaOut variable and OUT recommendForwardZoneStanzaOutFileNameOut MUST NOT BE USED in the expanded form
#     i.e They must not be prefixed by the the $ expansion character (i.e. DO NOT USE $forwardZoneStanzaOut or $recommendForwardZoneStanzaOutFileNameOut).
#     You just need to pass in the name of the out variables as is
create_forward_zone_stanza_and_recommended_forward_zone_file_name() {
  echo "Creating forward zone stanza ..."
  local zone=$1
  local __forwardZoneStanzaOut__=$2
  local __recommendForwardZoneStanzaOutFileNameOut__=$3
  local zoneName=$zone
  local __forwardZoneFileName__
  local __forwardZoneStanza__

  if [ -z "$zone" ] ; then
    echo "The zone (domain) for the DNS is required to create the forward zone of the DNS"
    echo "Please provide the zone as arg 1"
    return 1
  fi

  # if the zone does ends in a dot (i.e . ),  delete the dot
  if  echo "$zone" |  grep -iP "^.*\.$"; then
    zoneName=$(echo "$zone" | sed "s/\.$//gp")
  fi

  __forwardZoneFileName__="/etc/named/zones/${zoneName}.db"
  # reverse zone stanza
  __forwardZoneStanza__=$(eval 'cat << EOF
//Forward Zone
zone "$zoneName" IN {
  type master;
  file "$__forwardZoneFileName__";
  allow-update { none; };
};
EOF'
);

   echo "Finished creating forward zone stanza"
   return_function_result "$__forwardZoneStanza__" "$__forwardZoneStanzaOut__"
   return_function_result "$__forwardZoneFileName__" "$__recommendForwardZoneStanzaOutFileNameOut__"
}

# Creates and returns the reverse zone stanza and also a reverse zone file name that could be used as the file name of the reverse
# zone file
# Args:
#   $1 (cidrBlock): The CIDR block of the network e.g. 192.168.0.0/24
#   $2 (OUT reverseZoneStanzaOut): When provided, the reverse zone stanza will be assigned to this variable. If not provided,
#     the reverse zone stanza will be echoed to stdout
#   $3 (OUT recommendedReverseZoneFileNameOut): When provided, the recommended reverse zone file path will be assigned to this variable. If not provided,
#     the recommended reverse zone file name will be echoed to stdout
#     Example Usage: create_reverse_zone_stanza_and_recommended_reverse_zone_filename "$cidrBlock" reverseZoneStanzaOut recommendedReverseZoneFileNameOut
#     **Note** OUT reverseZoneStanzaOut variable and OUT recommendedReverseZoneFileNameOut MUST NOT BE USED in the expanded form
#     i.e They must not be prefixed by the the $ expansion character (i.e. DO NOT USE $reverseZoneStanzaOut or $recommendedReverseZoneFileNameOut).
#     You just need to pass in the name of the out variables as is
create_reverse_zone_stanza_and_recommended_reverse_zone_file_name() {
  echo "Creating reverse zone stanza ..."
  local cidrBlock=$1
  local __reverseZoneStanzaOut__=$2
  local __recommendedReverseZoneFileNameOut__=$3
  local cidrBlockRegexPattern="^([0-9]{1,3}\.){3}[0-9]{1,3}/\d{1,2}$"
  local networkIpArr
  local ipAndPrefixArr
  local reverseZoneName
  local __reverseZoneStanza__
  local __reverseZoneFileName__
  local reverseZoneFileNamePrefix

   if [ -z "$cidrBlock" ] ; then
        echo "The CIDR block for the DNS is required to create the reverse zone of the DNS"
        echo "Please provide the CIDR block as arg 2"
        return 1
    fi
#     if echo "$cidrBlock"| grep -iP "$cidrBlockRegexPattern" ; then
#      IFS='/' read -r -a ipAndPrefixArr <<< "$cidrBlock";
#      IFS='.' read -r -a networkIpArr <<< "${ipAndPrefixArr[0]}";
#      unset IFS # reset IFS to its previous value
#      local  cidrBlockSuffix=${ipAndPrefixArr[1]}
#      local reverseZoneIdxInNetworkIpArr=$((cidrBlockSuffix/8))
#
#      # Build the reverse zo
#      for ((i = $reverseZoneIdxInNetworkIpArr - 1 ; i >= 0 ; i--)); do
#
#        # Creating the zone name of the reverse zone
#        reverseZoneName=$reverseZoneName.${networkIpArr[$i]}
#        # Creating the file name of the reverse zone
#        reverseZoneFileNamePrefix=${networkIpArr[$i]}.$reverseZoneFileNamePrefix
#
#      done
#
#      # Remove the leading dot on the reverse zone name prefix
#      local reverseZonePrefix
#      reverseZonePrefix=$(echo "$reverseZoneName" | sed -En 's/^\.//p')
#      reverseZoneName="${reverseZonePrefix}.in-addr.arpa"
#    fi

     if is_valid_cidr "$cidrBlock" ; then

      local  cidrBlockSuffix
      local networkIp
      extract_network_ip_and_network_prefix_from_cidr_block "$cidrBlock" networkIp cidrBlockSuffix
      # Split the network ip into an array
      IFS='.' read -r -a networkIpArr <<< "${networkIp}";
      local reverseZoneIdxInNetworkIpArr=$((cidrBlockSuffix/8))

      # Build the reverse zo
      for ((i = $reverseZoneIdxInNetworkIpArr - 1 ; i >= 0 ; i--)); do

        # Creating the zone name of the reverse zone
        reverseZoneName=$reverseZoneName.${networkIpArr[$i]}
        # Creating the file name of the reverse zone
        reverseZoneFileNamePrefix=${networkIpArr[$i]}.$reverseZoneFileNamePrefix

      done

      # Remove the leading dot on the reverse zone name prefix
      local reverseZonePrefix
      reverseZonePrefix=$(echo "$reverseZoneName" | sed -En 's/^\.//p')
      reverseZoneName="${reverseZonePrefix}.in-addr.arpa"
        __reverseZoneFileName__="/etc/named/zones/${reverseZoneFileNamePrefix}db"
          # reverse zone stanza
        __reverseZoneStanza__=$(eval 'cat << EOF
//Reverse Zone
zone "$reverseZoneName" IN {
  type master;
  file "$__reverseZoneFileName__";
  allow-update { none; };
};
EOF'
      );
        echo "Finished creating reverse zone stanza"
        return_function_result "$__reverseZoneStanza__" "$__reverseZoneStanzaOut__"
        return_function_result "$__reverseZoneFileName__" "$__recommendedReverseZoneFileNameOut__"
    else
      echo "Invalid CIDR Block provided i.e. $cidrBlock"
      echo "Please provide a valid CIDR Block e.g. 192.168.0.0/24"
    fi

}


# Complete DNS Configuration for Fedora and Centos
# Do Default GW for debian based systems
# Create Systemd service and timer

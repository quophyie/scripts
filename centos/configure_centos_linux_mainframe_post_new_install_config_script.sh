#!/bin/bash
# Fail script execution if any function or snippet fails
set -e
source "${PWD}/shared_funcs.sh"

# Captures user input used to initialise the global variables below
# USER_UNDER_CONFIG: This the username of the user for which we configuring. We need to provide this because some commands are called using
#           sudo which will change the $HOME directory in the sudo context to that of root(i.e. /root), which can cause some undefined
#           behaviour
# USER_UNDER_CONFIG_HOME: The home directory of the provided user. This is set internally and is not user provided
# HOSTNAME [Default = mainframe]: The hostname that should be assigned to the machine we are configuring
# NIC_CONFIG_BASE_PATH: Set to /etc/sysconfig/network-scripts/ifcfg-
# VCONSOLE_CONF: Set to /etc/vconsole.conf for fedora based systems and
#                        /etc/default/console-setup for debian based systems
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
  local flavour
  get_os_flavour flavour

  if [ "${flavour}" == "fedora" ]; then
    VCONSOLE_CONF=/etc/vconsole.conf
  elif [ "${flavour}" == "debian" ]; then
    VCONSOLE_CONF=/etc/default/console-setup
  fi

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

  add_empty_line
  echo "Please provide the Keyboard mapping / Keyboard setting (i.e KEYMAP)"
  echo "Default: us"
  read KEYMAP
  KEYMAP=${KEYMAP:-us}

  add_empty_line
  echo "Please provide a hostname for the machine you are configuring"
  echo "Default: mainframe"
  read HOSTNAME
  HOSTNAME=${HOSTNAME:-mainframe}

  add_empty_line
  echo "Please enter the IP address of the  default gateway for your network"
  echo "Default: 192.168.0.1"

  read DEFAULT_GATEWAY
  DEFAULT_GATEWAY=${DEFAULT_GATEWAY:-192.168.0.1}

  # show available NICs on this machine
  add_empty_line
  ip a

  add_empty_line
  echo "Please enter the name of the NIC (Network Interface Card) of $HOSTNAME"
  echo "See above for details of NIC cards available on this machine"
  echo "Default: wlp7s0"
  read NIC
  NIC=${NIC:-wlp7s0}

  add_empty_line
  local defaultNicIp
  get_ip "${NIC}" defaultNicIp
  echo "Please enter the static IP address of the NIC (Network Interface Card) $NIC"
  echo "Default: ${defaultNicIp}"
  read NIC_IP
  NIC_IP=${NIC_IP:-${defaultNicIp}}

  if is_wireless_nic "${NIC}"; then
    add_empty_line
    echo "Please enter Wi-Fi SSID"
    while [ -z $SSID ]
        do
            read SSID
            if [ -z $SSID ]; then
                echo "Wi-Fi SSID is required. Please enter Wi-Fi SSID"
            fi
        done

    add_empty_line
    echo "Please enter Wi-Fi Password"
    while [ -z $WIFI_PASSWORD ]
        do
            read WIFI_PASSWORD
            if [ -z $WIFI_PASSWORD ]; then
                echo "Wi-Fi Password is required. Please enter Wi-Fi Password"
            fi
        done
  fi

  add_empty_line
  echo "Do you want to configure $HOSTNAME as a local  DNS server?"
  print_confirmation_instructions
  echo "Default: n"
  read dnsServerConfigConfirmation
  CONFIGURE_DNS_CONFIRMATION=n

  if is_answer_yes "$dnsServerConfigConfirmation"  ; then
    CONFIGURE_DNS_CONFIRMATION=y
    add_empty_line
    echo "Please provide the domain of $HOSTNAME"
    echo "Default: homelan.com"
    read DOMAIN_NAME
    DOMAIN_NAME=${DOMAIN_NAME:-homelan.com}
    add_empty_line

    if is_answer_yes "$CONFIGURE_DNS_CONFIRMATION"; then
      add_empty_line
      echo "Do you want to enable dynamic DNS updates i.e. allow hosts to automatically update the DNS server with new / updated host Ip addresses and names"
      print_confirmation_instructions
      echo "Default: yes"
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

  configure_user_provided_input_and_initialise_vars
  add_empty_line
  configure_keymap $KEYMAP $VCONSOLE_CONF
  add_empty_line
  install_wget
  add_empty_line
  install_google_chrome
  add_empty_line
  # configure_hostname "$HOSTNAME"
  # add_empty_line
  add_empty_line
  add_empty_line
  # configure_wpa_supplicant "$NIC" "$NIC_IP" "$SSID" "$WIFI_PASSWORD" "$NIC_CONFIG_FILE" "$NIC_CONFIG_BASE_PATH"
  add_empty_line
  configure_raid
  add_empty_line
  install_git
  add_empty_line
  install_zsh_and_oh_my_zsh "$USER_UNDER_CONFIG" "$USER_UNDER_CONFIG_HOME" "$VCONSOLE_CONF"
  install_zsh_and_oh_my_zsh "root" "/root" "$VCONSOLE_CONF"
  add_empty_line
  configure_user_shell "$USER_UNDER_CONFIG"
  configure_user_shell "root"

  if is_answer_yes "$CONFIGURE_DNS_CONFIRMATION"; then
    local cidrBlock
    get_suggested_cidr_block "$NIC_IP" cidrBlock
    install_and_configure_dns_server "$HOSTNAME" "$DOMAIN_NAME" "$NIC_IP" "$cidrBlock" "$ALLOW_DYNAMIC_DNS_UPDATES"
  fi
  change_default_run_level
  add_empty_line
  configure_networking "$NIC" "$HOSTNAME" --use_dhcp=no --nic_ip="${NIC_IP}" --gateway="${DEFAULT_GATEWAY}" --ssid=${SSID} --wifi_password="${WIFI_PASSWORD}" --local_nameserver_ip="${NIC_IP}" --use_local_dns="${CONFIGURE_DNS_CONFIRMATION}" --local_dns_domain_name="${DOMAIN_NAME}"

  # root has to manually login to zsh
  if [ "${USER_UNDER_CONFIG}" != "${USER}" ] ; then

     cd "$initDir"

     print_system_setup_completion_message 1
    if [ "$(basename "${SHELL}")" != "zsh" ] && [ "${USER}" != "root" ]; then
      echo "Logging $USER_UNDER_CONFIG into ZSH ..."
      zsh -i -c "su - \"$USER_UNDER_CONFIG\" "
    elif [ "$(basename "${SHELL}")" == "zsh" ]; then
      local zshrc="${USER_UNDER_CONFIG_HOME}"/.zshrc
      echo "sourcing ${zshrc}"
      source "${zshrc}"
    else
      add_empty_line
      echo "**********************************************************************************"
      echo "* If you are using zsh please source ${USER_UNDER_CONFIG_HOME}/${USER_UNDER_CONFIG}/.zshrc"
      echo "* else if you are using bash please source ${USER_UNDER_CONFIG_HOME}/${USER_UNDER_CONFIG}/.bash_profile"
      echo "**********************************************************************************"
    fi

  fi

}
# Call main
main

# TODO
# Install BIND
# Install Kubernetes
# Add Script to create auto start VMs service


# Unset
set +e
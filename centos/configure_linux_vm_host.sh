#!/bin/bash
# Fail script execution if any function or snippet fails
set -e
source "${PWD}/shared_funcs.sh"

## Configures /etc/resolv.conf
#create_nameserver_config(){
#  local resolv_conf=/etc/resolv.conf
#  echo "Creating $resolv_conf ..."
#  backup_file $resolv_conf
#
#  echo "# $HOSTNAME resolv.conf
#
#nameserver $NS_IP
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
#


# HOSTNAME
# NIC
# CONFIRM_CONFIGURE_DDNS_UPDATES
# VCONSOLE_CONF: Set to /etc/vconsole.conf for fedora based systems and
#                /etc/default/console-setup for debian based systems
# TRY_COPY_DDNS_UPDATE_KEY
# NS_USER
# NS_PASS
# NS_NAME
# NS_DOMAIN_NAME
# TRY_COPY_DDNS_UPDATE_KEY
# DDNS_UPDATE_KEY_ON_NS_SERVER
# DDNS_UPDATE_KEY
configure_user_provided_input_and_initialise_vars() {
  # NIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

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


  ip a
  add_empty_line
  echo "Please provide the name of the network interface card (NIC) from the list above"
   while [ -z $NIC ]
        do
            read NIC
            if [ -z $NIC ]; then
                echo "NIC is required. Please provide the NIC"
            fi
        done

  echo "Please provide the name of the host you are configuring
Default: $(hostname)"
  read HOSTNAME
  HOSTNAME=${HOSTNAME:-$(hostname)}

   echo "Please provide the IP of the nameserver
Default: 192.168.0.2"
   read NS_IP
   NS_IP=${NS_IP:-"192.168.0.2"}

  echo "Please provide the name of the nameserver
Default: mainframe"
  read NS_NAME
  NS_NAME=${NS_NAME:-mainframe}

  echo "Please provide the domain of the nameserver
Default: homelan.com"
  read NS_DOMAIN_NAME
  NS_DOMAIN_NAME=${NS_DOMAIN_NAME:-homelan.com}

  echo "Do you want to configure this host to dynamically update the DNS server $NS_NAME with the ip address and name of this host i.e. $HOSTNAME?
Default: y"
  print_confirmation_instructions
  read CONFIRM_CONFIGURE_DDNS_UPDATES
  CONFIRM_CONFIGURE_DDNS_UPDATES=${CONFIRM_CONFIGURE_DDNS_UPDATES:-y}

  if  is_true "$CONFIRM_CONFIGURE_DDNS_UPDATES" ; then
     echo "Do you want to try and copy the dynamic DNS update key from the DNS server (i.e $NS_NAME)
Default: y"

     print_confirmation_instructions
     read TRY_COPY_DDNS_UPDATE_KEY
     TRY_COPY_DDNS_UPDATE_KEY=${TRY_COPY_DDNS_UPDATE_KEY:-y}

     if is_true $TRY_COPY_DDNS_UPDATE_KEY ; then
       echo "Please provide the username used to copy the dynamic DNS key from the DNS server i.e the user used to access $NS_NAME"
       read NS_USER

          while [ -z $NS_USER ]
               do
                   read NS_USER
                   if [ -z $NS_USER ]; then
                       echo "The DNS server user is required"
                   fi
               done

       echo "Please provide the password of user $NS_USER "
       # Dont echo password
       read -s NS_PASS

          while [ -z $NS_PASS ]
               do
                   # Dont echo password
                   read -s NS_PASS
                   if [ -z $NS_PASS ]; then
                       echo "The password for DNS server user $NS_USER is required"
                   fi
               done

       echo "Please provide the full path to the dynamic DNS update key on the DNS server where the DNS Key should be copied from i.e $NS_NAME
Default: /etc/named/ddnsupdate.key"
       read DDNS_UPDATE_KEY_ON_NS_SERVER
    DDNS_UPDATE_KEY_ON_NS_SERVER=${DDNS_UPDATE_KEY_ON_NS_SERVER:-/etc/named/ddnsupdate.key}

       echo "Please provide the full file path to location where the dynamic update key will be stored on this host i.e $HOSTNAME
Default: /etc/named/ddnsupdate.key"

       read DDNS_UPDATE_KEY
       DDNS_UPDATE_KEY=${DDNS_UPDATE_KEY:-/etc/named/ddnsupdate.key}
     else
       echo "*******************"
       echo "As you have opted not try to obtain the dynamic DNS update key from the DNS server, please make sure that there is a valid dynamic dns update key file at location /etc/named/ddnsupdate.key otherwise dynamic DNS updates will not work!!!!"
       echo "*******************"
     fi

  fi
}

main() {

  require_root_access
  print_os_flavour
  configure_user_provided_input_and_initialise_vars
  add_empty_line
  install_git
  add_empty_line
  install_zsh_and_oh_my_zsh "$USER_UNDER_CONFIG" "$USER_UNDER_CONFIG_HOME" "$VCONSOLE_CONF"
  install_zsh_and_oh_my_zsh "root" "/root" "$VCONSOLE_CONF"

  configure_networking "$NIC" "$HOSTNAME" --local_nameserver_ip="${NS_IP}" --local_dns_domain_name="${NS_DOMAIN_NAME}"
  configure_user_shell "$USER_UNDER_CONFIG"
  configure_user_shell "root"
  if is_true "$CONFIRM_CONFIGURE_DDNS_UPDATES"; then
    configure_dynamic_dns_client "$NS_IP" "$NS_NAME" "$NS_DOMAIN_NAME" "$NIC" "$TRY_COPY_DDNS_UPDATE_KEY" "$NS_USER" "$NS_PASS" "$DDNS_UPDATE_KEY" "$DDNS_UPDATE_KEY_ON_NS_SERVER"
  fi

  add_empty_line
  print_system_setup_completion_message 1

}

# Call main
main

# Fix NetworkManager overriding /etc/resolv.conf in clients

# Unset
#   set +e  DO NOT Exit/stop if a command exits with a non-zero status.
set +e
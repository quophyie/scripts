#Centos/RHEL/Fedora Server Post New install script

This directory contains a number of scripts 
The first is to help with the initial configuration of a Fedora derived server OS (i.e.CenOS, RHEL, Fedora Server, OEL etc)
on a home setup post installation of the new OS (Used to configure mainframe)

The script first script (i.e `configure_centos_linux_mainframe_post_new_install_config_script.sh`)  will perform the following tasks
1) Configures the Keybaord mapping (i.e. KEYMAP). Defaults to us
2) Install **`wget`**
3) Install [Google Chrome](https://www.google.co.uk/chrome/)
4) Configure the hostname for the server / machine
5) Add **`/etc/resolv.conf`** with google and cloudflare DNS as the nameservers. It also updates the /etc/resolv.conf with the details of the local DNS if the Bind9 DNS is configured as part of running this script
6) Setup a default gateway with 
7) Set up a static ip for your selected network interface card (NIC)
8) Configure **`wpa_supplicant`**
9) Configures NIC with static IP for NetworkManger 
10) Configures the Raid contoller
11) Install [git](https://git-scm.com/about)
12) Install **`zsh`**
13) Installs Powerline Fonts for Terminal Apps such iTerm in MacOs and the terminal apps found in Desktop environments such as Gnome in the various Linux distros
14) Installs Powerline TTY terminal consoles (i.e Alt F1 - F6) fonts and sets the default TTY font to the powerline TTY font `ter-powerline-v14n`
15) Install [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) with [Spaceship Prompt](https://spaceship-prompt.sh/) as the default them. It also installs the [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md). See `~/.zshrc` for more info
16) Installs Bind9 (named) DNS server for name resolution on a local network. The DNS server can be configured to allow dynamic DNS 
updates if you select the options to allow other hosts / clients to dynamically the DNS server (i.e the mainframe host being configured) with their IPs and names
17) It gives you the opportunity to set the default run level of the server (multi-user.target is recommended for advanced server admins)
18) Provides functions to configure auto started VMWare virtual machines

## Usage

The first script (i.e `configure_centos_linux_mainframe_post_new_install_config_script.sh`) must be run with **`sudo`** i.e. 

You may have to `chmod` with execution permissions but assuming that you
have execution permissions, run the script like so

```shell
# Copy the script and the library that it depends on (i.e. shared_funcs.sh) to the server you are configuring with a tool such as scp
# scp configure_centos_linux_mainframe_post_new_install_config_script.sh <USERNAME>@<REMOTE_HOST>:<LOCATION_ON_REMOTE_HOST>
scp shared_funcs.sh configure_centos_linux_mainframe_post_new_install_config_script.sh dman@192.168.0.10:/home/dman/Downloads

# SSH to the remote host
# ssh USERNAME@REMOTE_HOST

ssh dman@192.168.0.10

#On the remote host, execute the script
# You may have to chmod the script to make it executable
cd ~/Downloads/
sudo ./configure_centos_linux_mainframe_post_new_install_config_script.sh

# Once the script has completed, you will need to use the static ip 
# address that you configured with script to ssh to the remote 
# server. For example, if accepted the default static ip (192.168.0.2) when running 
# the script, we would ssh to the remote server as follows

ssh dman@192.168.0.2

```


The second script (i.e `configure_linux_vm_host.sh`) is used to configure hosts that do NOT need to be the mainframe (e.g. the machine hosting the VMs)
This script performs the following tasks
1) Configure the hostname for the host / machine
2) Update **`/etc/resolv.conf`** with google and cloudflare DNS as the nameservers. It also updates the /etc/resolv.conf with the details of the local DNS nameserver (e.g. mainframe) if that local DNS option is selected (e.g. if mainframe is configured as the local the DNS nameserver) 
3) Configures a systemd timer and service that sends dynamic DNS updates to the local DNS server e.g. mainframe 


This second script (i.e `configure_linux_vm_host.sh`) must be run with **`sudo`** i.e.

You may have to `chmod` with execution permissions but assuming that you
have execution permissions, run the script like so

```shell
# Copy the script and the library that it depends on (i.e. shared_funcs.sh) to the server you are configuring with a tool such as scp
# scp configure_centos_linux_mainframe_post_new_install_config_script.sh <USERNAME>@<REMOTE_HOST>:<LOCATION_ON_REMOTE_HOST>
scp shared_funcs.sh configure_linux_vm_host.sh dman@192.168.0.12:/home/dman/Downloads

# SSH to the remote host
# ssh USERNAME@REMOTE_HOST

ssh dman@192.168.0.12

# On the remote host, execute the script
# You may have to chmod the script to make it executable
cd ~/Downloads/
sudo ./configure_linux_vm_host.sh

# Once the script has completed, you will need to use the static ip 
# address that you configured with script to ssh to the remote 
# server. For example, if accepted the default static ip (192.168.0.2) when running 
# the script, we would ssh to the remote server as follows

ssh dman@192.168.0.3

```
Thats all folks!!

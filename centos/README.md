#Centos/RHEL/Fedora Server Post New install script

This script  is provided to help with the initial configuration of a Fedora derived server OS (i.e.CenOS, RHEL, Fedora Server, OEL etc)
on a home setup post installation of the new OS

The script will perform the following tasks
1) Configures the Keybaord mapping (i.e. KEYMAP). Defaults to us
2) Install **`wget`**
3) Install [Google Chrome](https://www.google.co.uk/chrome/)
4) Configure the hostname for the server / machine
5) Add **`/etc/resolv.conf`** with google and cloudflare DNS as the nameservers
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
16) It gives you the opportunity to set the default run level of the server (multi-user.target is recommended for advanced server admins)

## Usage

This script must be run with **`sudo`** i.e. 

You may have to `chmod` with execution permissions but assuming that you
have execution permissions, run the script like so

```shell
# Copy the script to the server you are configuring with a tool such as scp
# scp centos_linux_post_new_install_config_script.sh <USERNAME>@<REMOTE_HOST>:<LOCATION_ON_REMOTE_HOST>
scp centos_linux_post_new_install_config_script.sh dman@192.168.0.10:/home/dman/Downloads

# SSH to the remote host
# ssh USERNAME@REMOTE_HOST

ssh dman@192.168.0.10

#On the remote host, execute the script
# You may have to chmod the script to make it executable
cd ~/Downloads/
sudo ./centos_linux_post_new_install_config_script.sh

# Once the script has completed, you will need to use the static ip 
# address that you configured with script to ssh to the remote 
# server. For example, if accepted the default static ip (192.168.0.2) when running 
# the script, we would ssh to the remote server as follows

ssh dman@192.168.0.2

```

Thats all folks!!

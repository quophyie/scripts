#Centos/RHEL/Fedora Server Post New install script

This script  is provided to help with the initial configuration of a Fedora derived server OS (i.e.CenOS, RHEL, Fedora Server, OEL etc)
on a home setup post installation of the new OS

The script will perform the following tasks
1) Install **`wget`**
2) Install [Google Chrome](https://www.google.co.uk/chrome/)
3) Configure the hostname for the server / machine
4) Add **`/etc/resolv.conf`** with google and cloudflare DNS as the nameservers
5) Setup a default gateway with 
6) Set up a static ip for your selected network interface card (NIC)
7) Configure **`wpa_supplicant`**
8) Configures NIC with static IP for NetworkManger 
9) Configures the Raid contoller
10) Install [git](https://git-scm.com/about)
11) Install **`zsh`**
12) Install [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) with [Spaceship Prompt](https://spaceship-prompt.sh/) as the default them. It also installs the [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md). See `~/.zshrc` for more info
13) It gives you the opportunity to set the default run level of the server (multi-user.target is recommended for advanced server admins)

## Usage

This script must be run with **`sudo`** i.e. 

You may have to `chmod` with execution permissions but assuming that you
have execution permissions, run the script like so

```shell
sudo ./centos_linux_post_new_install_config_script.sh
```

Thats all folks!!

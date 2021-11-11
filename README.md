# Scripts

This project contains shared scripts such as shell / bash scripts and libraries that are shared by multiple
microservices and other projects


## Setup

1. Create a folder to setup your project

```bash
$ mkdir myproject

$ cd myproject

```

2. Clone the scripts project ``https://github.com/quophyie/scripts.git``. It contains scripts
that are required by the ``Quantal Infrastructure`` project

```bash
$ git clone https://github.com/quophyie/scripts.git .
```

3. Run the setup script of the **``scripts``** project

```bash
$  cd scripts

$ bin/setup

```

4. source either  **``~/.zshrc``**  or **``~/.bash_profile``** depending on your shell

```bash
# BASH
$  source ~/.bash_profile

# ZSH
$ source ~/.zshrc

```

Thats all folks!!
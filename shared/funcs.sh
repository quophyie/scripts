#!/usr/bin/env bash


# Finds a line containing a given string in a file and inserts the given new
# after the found line
# Args: $1 = the path to the file to search
#       $2 = the string to search for in the file
#       $3 = the string to insert after the found line
function insert_after # file line newText
{

  local file="$1" line="$2" newText="$3"
 # echo "inserting '${newText}' after line  "${line}" in file ${file}"

  if grep -q "${line}" "${file}"; then
    sed -i ".bak" -e "/^$line/a"$'\\\n\\\n'"$newText"$'\n' "$file"
  else
      echo -e "\n${newText}" >> ${file}
  fi
}

# Returns the profile file used in the shell
#   Arg:
#       $1: The profile file returned from this function. the caller of this function must provide a variable which
#           be set by this function to the file name of the profile
#
get_profile_file() {

    local  __resultvar=$1
    bashProfile=~/.bash_profile
    zshProfile=~/.zshrc

    if [[ "${SHELL}" = "/bin/zsh" ]]; then

        profile=${zshProfile}

    elif [[ "${SHELL}" = "/bin/bash" ]]; then

        profile=${bashProfile}
    fi

    # this is the value that is returned to the caller of this function

    eval $__resultvar="'${profile}'"

}

# Returns the subshell that a script or executinng command is being run in
# Args:
#       $1: the value returned from this function i.e. the subshell
function get_sub_shell(){

    local  __resultvar=$1
    local profileShell

    if test -n "$ZSH_VERSION"; then
      profileShell=zsh
    elif test -n "$BASH_VERSION"; then
      profileShell=bash
    elif test -n "$KSH_VERSION"; then
      profileShell=ksh
    elif test -n "$FCEDIT"; then
      profileShell=ksh
    elif test -n "$PS3"; then
      profileShell=unknown
    else
      profileShell=sh
    fi

    # this is the value that is returned to the caller of this function

    eval $__resultvar="'${profileShell}'"

}

# configures the QUANTAL_SHARED_SCRIPTS_DIR environment variables
function configure_quantal_shared_scripts_dir_env_var() {

 echo "configuring variable QUANTAL_SHARED_SCRIPTS_DIR ..."
 if [ -z "${QUANTAL_SHARED_SCRIPTS_DIR}" ]; then

# get the correct absolute full name of the scripts-infra  directory (i.e. the directory containing this script)
# this makes sure that no matter where this file is sourced from,
# INFRA_SCRIPTS_ROOT will always be set to the correct absolute directory i.e. the directory containing
# this file


    local source
    local homeDir=~
    local shell
    # Get the shell executing the script
     local profileFile
     get_profile_file profileFile
     get_sub_shell shell

#     if [[  "${profileFile}" = "${homeDir}/.bash_profile" ]]; then
#         # see https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
#        # for more info
#        source="${BASH_SOURCE[0]}"
#
#     elif [[ "${profileFile}" = "${homeDir}/.zshrc"  ]]; then
#         source="$( cd "$(dirname "${funcfiletrace[1]}")">/dev/null 2>&1 ; pwd -P )"
#     fi

 if [[  "${shell}" = "bash" ]]; then
         # see https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
        # for more info
        source="${BASH_SOURCE[0]}"

     elif [[ "${shell}" = "zsh"  ]]; then
         source="$( cd "$(dirname "${funcfiletrace[1]}")">/dev/null 2>&1 ; pwd -P )"
     fi

    local isSymLink=false

    # if this file has been symlinked the code in the while loop will resolve until
    # we the actual directory containing this file is reached
    while [ -h "$source" ]; do # resolve $SOURCE until the file is no longer a symlink
      isSymLink=true
      DIR="$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )"
      source="$(readlink "$source")"
      [[ $source != /* ]] && source="$DIR/$source" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done


#    if [[ ${isSymLink} == "true" ]]; then
#        INFRA_SCRIPTS_ROOT="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
#    else
#        INFRA_SCRIPTS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#    fi

    QUANTAL_SHARED_SCRIPTS_DIR="$( cd -P "$( dirname "$source" )"/../ >/dev/null 2>&1 && pwd )"

   echo "successfully configured variable QUANTAL_SHARED_SCRIPTS_DIR as ${QUANTAL_SHARED_SCRIPTS_DIR} "

 fi

}


# Checks whether this script is sourced by  the shell initializatiion
# profile config file such as ~/.bash_profile or ~/.zshrc. If this script is sourced
# by a shell initialization script such  ~/.bash_profile or ~/.zshrc, it will be in
# the call stack. If you simply call and NOT SOURCE this script from
# a shell initialization script such  ~/.bash_profile or ~/.zshrc
# (e.g. if you have this line (e.g.  'sh ~/config_env_file.sh' in ~/.bash_profile or ~/.zshrc),
# it will executed in a subshell and hence will not be found in call stack of the calling
# script (e.g. ~/.bash_profile or ~/.zshrc)
#   Args:
#       $1: the result of this function call. Will contain the value 'true' if the profile file is in the call stack
#           and 'false' if not
function is_sourced_by_shell_init_profile_config_file (){


    local  __resultvar=${1}
    local res

    local profileFile
    local callStack
    local homeDir=~

    get_profile_file profileFile
      local shell

    # Get the shell executing the script
     get_sub_shell shell

    if [[ ${shell} = "zsh" ]]; then
            callStack=${funcsourcetrace}

            # printf "\n\nFUNCNAME\n\n"
            # printf "$funcfiletrace - $funcsourcetrace - $funcstack - $functrace"

           # echo "${funcsourcetrace}"

          else

              # printf "\n\nBASH_SOURCE\n\n"
              # printf "$BASH_SOURCE \n"
              get_bash_callstack callStack
              # echo "bashCallStack -> ${callStack[@]}"

          fi

    # Iterate the arr variable using for loop
    for callStackItem in ${callStack[@]}; do


      if grep -q "${profileFile}" <<< "${callStackItem}"; then
        res=true
        break
      else
        res=false
      fi
    done

    eval $__resultvar="'${res}'"
}

# will return the call stack in a BASH shell
# Args:
#   $1: the return value of this function. This will hold the call stack

function get_bash_callstack() {

  local  __resultvar=${1}
  local frame=0
  local res
  local callstack=()
  while caller ${frame}; do
    # add stack item to call stack
    local stackItem=$(eval caller ${frame})
    callstack+=("${stackItem}")
    ((frame++));
  done

  # return the stach here
  eval $__resultvar="'${callstack[@]}'"

}
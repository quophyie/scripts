#!/usr/bin/env bash

# Please Use Google Shell Style: https://google.github.io/styleguide/shell.xml

# ---- Start unofficial bash strict mode boilerplate
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
#set -o errexit  # always exit on error
#set -o errtrace # trap errors in functions as well
#set -o pipefail # don't ignore exit codes when piping output
#set -o posix    # more strict failures in subshells
# set -x          # enable debugging

# IFS="$(printf "\n\t")"
# ---- End unofficial bash strict mode boilerplate


SHARED_SCRIPTS_DIR=$( cd "$(dirname ${BASH_SOURCE[0]})"/.. >/dev/null 2>&1 ; pwd -P )
SHARED_FUNCS_DIR=$( cd "${SHARED_SCRIPTS_DIR}"/shared >/dev/null 2>&1 ; pwd -P )
SHARED_FUNCS="${SHARED_FUNCS_DIR}/funcs.sh"

# Source shared funcs
source ${SHARED_FUNCS}

# Get the result of sourcing (i.e. was the sourcing successful)
sourceRes=$?

# is_sourced_by_shell_init_profile_config_file is defined in ${SHARED_FUNCS_DIR}/shared/funcs.sh file i.e. [THIS_PROJECT_DIR]/shared/funcs.sh
isThisScriptSourcedBeingByProfileFile=
is_sourced_by_shell_init_profile_config_file isThisScriptSourcedBeingByProfileFile

if [[ ${sourceRes} -ne 0 ]]; then
    # Naive try catch

    {

     printf "\n${BASH_SOURCE[0]}"
     printf "\nQuantal shared scripts functions not found!\n"
     printf "Please run command below to configure this project and then run your last command again !\n\n"
     printf "${SHARED_SCRIPTS_DIR}/bin/setup \n\n"

     if [[ "${isThisScriptSourcedBeingByProfileFile}" = "false" ]]; then
        printf "this execution of this script is not being sourced from a shell config profile file.\n stopping script execution\n"
        exit 1
     fi

    }

fi

#source  ${QUANTAL_SHARED_SCRIPTS_DIR}/shared/funcs.sh
#cd "$(dirname "${BASH_SOURCE[0]}")/.."
envFilenameOnly=./.env

# Creates an env file using vars found in the .env.example provided as the 2nd arg to this function
# If the .env file does not exist. it will be created using an .env.example file passed as the 1st arg to this function
# The .env.example file can also be supplied even if the .env file does exists. In such a situation, all keys which
# exist in the .env.example but not in .env file will be added to the .env file. The .env.example cannot be used to
# cannot be used to update key values in the .env file
# Args:
#     $1: The path to the directory containing / should contain the env file  e.g. (~/myproj)
#     $2: The example env file used to create or update the .env file. This Defaults to '$1/.env.example'
#         e.g. ~/myproj/.env.example. The default .example.env file is created by concatenating the  directory specified by the
#         1st arg (i.e. $1 e.g. ~/myproj) and the default file name of '.example.env' e.g. (~/myproj/.example.env)
#         The .env.example ($2) file can also be supplied even if the .env file does exists. In such a situation,
#         all keys which exist in the .env.example ($2) but not in .env file will be added to the .env file.
#
#         **** The .env.example cannot be used to update key values in the .env file. *****
#
#         The .env file and the .env.example file must contain key value pairs of the form
#
#         KEY=VALUE
#
#         AN example of a .env or .env.example
#
#         MY_KEY_1=hello
#         MY_KEY_2=world
function create_env_file() {
  set -e

  local envFileDir=$1
  local exampleEnvFile=$2

  if [[ ! -d ${envFileDir} ]]; then
    echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: The .env file directory must be provided as the 1st argument"
    exit 1
  fi

  if [[ -z exampleEnvFile ]]; then
    exampleEnvFile="${envFileDir}/.env.example"
  fi

  add_new_env_vars_to_env_file ${envFileDir} ${exampleEnvFile}
}

# Constructs the full path to the env file or the example.env file
# Args:
#     $1: The full path to the directory that will contain the env file
#     $2: the name of the env file e.g. example.env
#     $3: The return value of this faction i.e. a variable supplied by the caller of this function
#         that will be set to the value of the constructed file name.
#         This is the return value of this function
function construct_env_file_path() {

  local __envFileDir=$1
  local __envFileName=$2

  local __result=$3

   if [[ ! -d ${__envFileDir} ]]; then
    echo "${BASH_SOURCE[1]}: line ${BASH_LINENO[1]}: ${FUNCNAME[1]}:"
    echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: The .env file directory must be provided as the 1st argument"
    exit 1
  fi

   if [[ -z ${__envFileName} ]]; then
    echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: The env file name (e.g. '.env') is required. The env file name (excluding directory name) must be provided as the 2nd argument"
    exit 1
  fi

  local __constructedFileName=${__envFileDir}/${__envFileName}
  eval ${__result}="'${__constructedFileName}'"

}

function file_ends_with_newline() {
  local envFile=$1

  if [[ ! -f ${envFile} ]]; then
     echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: .env file not provided. The .env file is required"
     exit 1
  fi

  [[ $(tail -c1 "${envFile}" | wc -l) -gt 0 ]]
}

# Adds the env vars found in the .env.example to .env file
# If the .env file does not exist. it will be created using an .env.example file passed as the 1st arg to this function
# The .env.example file can also be supplied even if the .env file does exists. In such a situation, all keys which
# exist in the .env.example but not in .env file will be added to the .env file. The .env.example cannot be used to
# cannot be used to update key values in the .env file
# Args:
#     $1: The path to the directory containing / should contain the env file  e.g. (~/myproj)
#     $2: The example env file used to create or update the .env file. This Defaults to '$1/.env.example'
#         e.g. ~/myproj/.env.example. The default .example.env file is created by concatenating the  directory specified by the
#         1st arg (i.e. $1 e.g. ~/myproj) and the default file name of '.example.env' e.g. (~/myproj/.example.env)
#         The .env.example ($2) file can also be supplied even if the .env file does exists. In such a situation,
#         all keys which exist in the .env.example ($2) but not in .env file will be added to the .env file.
#
#         **** The .env.example cannot be used to update key values in the .env file. *****
#
#         The .env file and the .env.example file must contain key value pairs of the form
#
#         KEY=VALUE
#
#         AN example of a .env or .env.example
#
#         MY_KEY_1=hello
#         MY_KEY_2=world
function add_new_env_vars_to_env_file() {


  local envFileDir=$1

   if [[ ! -d ${envFileDir} ]]; then
    echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: The .env file directory must be provided as the 1st argument"
    exit 1
  fi

  local exampleEnvFile=$2

  if [[ -z ${exampleEnvFile} ]]; then
    exampleEnvFile="${envFileDir}/.env.example"
  fi

  # local envFile=${envFileDir}/.env

  # the env file full path will be constructed and stored in the local variable envFile
  local envFile
  construct_env_file_path ${envFileDir} ".env" envFile

  # create .env and set perms if it does not exist
  [[ ! -f "${envFile}" ]] && {
    touch "${envFile}"
    chmod 0600 "${envFile}"
  }

  # if the file does not end with new line add a new line to it
  if ! file_ends_with_newline ${envFile}; then
    echo "" >> "${envFile}"
  fi

echo "finding ${exampleEnvFile}"
  find ${envFileDir} -name ${exampleEnvFile} -type f -print0 |
    (xargs -0 grep -Ehv '^\s*#' || true) |
    sort |
    {
      while IFS= read -r var; do

        if [[ -z "${var}" ]]; then
          continue
        fi
        key="${var%%=*}" # get var key
        # only eval for dynamic vars if the value has a dollar sign
        if [[ "${var}" =~ "$" ]]; then
          var="$(eval echo "${var}")" # generate dynamic values
        fi
        # If .env doesn't contain this env key, add it
        if ! grep -qLE "^${key}=" "${envFile}"; then
          echo "Adding $key to .env"
          echo "$var" >>"${envFile}"
        fi
      done
    }
}

# Exports the env vars found in the .env file to the environment
# If the .env file does not exist. it will be created using an .env.example file passed as the 1st arg to this function
# The .env.example file can also be supplied even if the .env file does exists. In such a situation, all keys which
# exist in the .env.example but not in .env file will be added to the .env file. The .env.example cannot be used to
# cannot zbe used to update key values in the .env file
# Args:
#     $1: The path to the directory containing / should contain the env file  e.g. (~/myproj)
#     $2: The example env file used to create or update the .env file. This Defaults to '$1/.env.example'
#         e.g. ~/myproj/.env.example. The default .example.env file is created by concatenating the  directory specified by the
#         1st arg (i.e. $1 e.g. ~/myproj) and the default file name of '.example.env' e.g. (~/myproj/.example.env)
#         The .env.example ($2) file can also be supplied even if the .env file does exists. In such a situation,
#         all keys which exist in the .env.example ($2) but not in .env file will be added to the .env file.
#
#         **** The .env.example cannot be used to update key values in the .env file. *****
#
#         The .env file and the .env.example file must contain key value pairs of the form
#
#         KEY=VALUE
#
#         AN example of a .env or .env.example
#
#         MY_KEY_1=hello
#         MY_KEY_2=world

function export_env_vars_in_env_file() {

  local envFileDir=$1
  local exampleEnvFile=$2

  if [[ ! -d ${envFileDir} ]]; then
    echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: The .env file directory must be provided as the 1st argument"
    exit 1
  fi

  if [[ -z ${exampleEnvFile} ]]; then
    exampleEnvFile="${envFileDir}/.env.example"
  else
    add_new_env_vars_to_env_file ${envFileDir} ${exampleEnvFile}
  fi

  # the env file full path will be constructed and stored in the local variable envFile
  local envFile
  construct_env_file_path ${envFileDir} ".env" envFile

  # create .env and set perms if it does not exist
  if [[ ! -f "${envFile}" ]];  then
    create_env_file ${envFileDir} ${exampleEnvFile}
  fi


  find ${envFileDir} -name ".env" -type f -print0 |
    (xargs -0 grep -Ehv '^\s*#' || true) |
    sort |
    {

    EXPORTS_FILE=${envFileDir}/tmp
     if [[ -f  ${EXPORTS_FILE} ]]; then
        rm "${EXPORTS_FILE}"
     fi;

      touch "${EXPORTS_FILE}"
      echo "#!/usr/bin/env bash" >>"${EXPORTS_FILE}"
      echo "echo \"exporting environment variables ...\" ">>"${EXPORTS_FILE}"
      chmod 777 "${EXPORTS_FILE}"

      while IFS= read -r var; do
      # skip empty vars
        if [[ -z "${var}" ]]; then
          continue
        fi
        key="${var%%=*}" # get var key
        # only eval for dynamic vars if the value has a dollar sign
        if [[ "${var}" =~ "$" ]]; then
          var="$(eval echo "${var}")" # generate dynamic values
        fi

        echo "key is ${key}"
        echo "var is ${var}"

        # add all the keys in the env file to the tmp env exports file
        if grep -qLE "^${key}=" "${envFile}"; then
          # write to the tmp exports file
          echo "echo \"exporting $key\" " >>"${EXPORTS_FILE}"
          echo "adding ${key} to exports file"

          # echo export command to the tmp exports file
          echo "export $var" >>"${EXPORTS_FILE}"
        fi
      done

      if [[ -f  ${EXPORTS_FILE} ]]; then
          # remove the tmp env file after it has been sourced

          local isScriptSourcedByProfileFile
          is_sourced_by_shell_init_profile_config_file isInProfileCallStack

          if [[ ${isScriptSourcedByProfileFile} = "false" ]]; then

              echo "echo \"finished exporting env vars\" ">>"${EXPORTS_FILE}"
              echo "echo \"deleting ${EXPORTS_FILE} ...\" ">>"${EXPORTS_FILE}"
              echo "rm " ${EXPORTS_FILE}>>"${EXPORTS_FILE}"
              echo ""
              echo "Please source file ${EXPORTS_FILE} to complete environment variable exports i.e. "
              echo ""
              echo "*****************************"
              echo "!!! PLEASE COPY AND RUN COMMAND BELOW TO COMPLETE EXPORTS !!!"
              echo ""
              echo "source ${EXPORTS_FILE}"
              echo ""
          fi

      fi

    }

}

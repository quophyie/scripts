
check_and_source_variables_file(){

   if [ -z "$1" ]; then
       echo "the container specific variable file has not been provided.
       Please provide the path to the container specific variable file (usually called 'variables.sh')
       as the first argument to the called function)"
       return 1
    else
       check_and_source_file $1
        return $?
    fi

}

check_and_source_file(){

   if [ -f "$1" ]; then
     echo "sourcing file $1 ..."
     source $1
     return $?

    else
      echo "could not source file $1. please check and make sure that file $1 exists"
      return 1
    fi

}

start_db_container(){
  check_and_source_variables_file $1
  START_DB_COMMAND="WEB_APP_PORT=${WEB_APP_PORT} docker-compose -f ../docker/compose/docker-compose.yml up -d ${DB_CONTAINER_NAME}"

  echo "executing command: ${START_DB_COMMAND}"

    # Start the Db
    eval "${START_DB_COMMAND}; START_DB_COMMAND_RESULT=$?"

    if [ ${START_DB_COMMAND_RESULT} -eq 0 ]; then
        echo "start database container command on ${DB_CONTAINER_NAME} executed successfully!!"

    else
        echo "Oops!. start database container command on ${DB_CONTAINER_NAME} failed"
    fi

    echo "Start database container command on ${DB_CONTAINER_NAME} returned status code:${START_DB_COMMAND_RESULT}"

    # Bring logs to the front
    #docker-compose -f ../docker/compose/docker-compose.yml logs -f ${DB_CONTAINER_NAME}

    return ${START_DB_COMMAND_RESULT}
}

# Starts the service.
#
#Arguments
#    $1 = variables.sh - a file that contains container specific variables
#    $2 = MS_SERVICE_TYPE - The microservice type. must be one of 'java' or 'node' or 'nodejs'
#    $3 = BUILD_CONTAINER - a boolean (either true of false) that determines whether the services containers will be
#                           built before starting
#
start_service_container(){
    check_and_source_variables_file $1
    MS_SERVICE_TYPE=$(echo "$2" | tr '[:upper:]' '[:lower:] | xargs')

    JAVA_MS_SERVICE_TYPE="java"
    NODE_MS_SERVICE_TYPE="node"
    NODEJS_MS_SERVICE_TYPE="nodejs"

     if [ -z "${MS_SERVICE_TYPE}" ]; then
        echo "The microservice type is required argument. Please supply one of 'java' or 'node' as the microservice type as the second argument in 'start_service_container' function"
        BUILD_CONTAINER=false
    fi


     BUILD_CONTAINER_COMMAND=
    # We set BUILD_CONTAINER to true if $2 is empty because by default we want to build the container

    if [ -z "$3" ]; then
        BUILD_CONTAINER=false
    else
        # Covert input to lower case and trim leading and trailing white spaces
        BUILD_CONTAINER=$(echo "$3" | tr '[:upper:]' '[:lower:] | xargs')
    fi

    echo "MICROSERVICE_TYPE: ${MS_SERVICE_TYPE}"
    echo "BUILD_CONTAINER: ${BUILD_CONTAINER}"


    if [ "${BUILD_CONTAINER}" == "true" ]; then
        if [ "${MS_SERVICE_TYPE}" == "${JAVA_MS_SERVICE_TYPE}" ]; then

            BUILD_CONTAINER_COMMAND="${BUILD_CONTAINER_COMMAND} DB_PORT=${DB_PORT_EXPOSED_ON_HOST} cd ../ && mvn package && cd ./scripts && WEB_APP_PORT=${WEB_APP_PORT} docker-compose -f ../docker/compose/docker-compose.yml build --no-cache &&"

        elif [ "${MS_SERVICE_TYPE}" == "${NODE_MS_SERVICE_TYPE}" ] || [ "${MS_SERVICE_TYPE}" == "${NODEJS_MS_SERVICE_TYPE}" ]; then

            BUILD_CONTAINER_COMMAND="${BUILD_CONTAINER_COMMAND} WEB_APP_PORT=${WEB_APP_PORT} docker-compose -f ../docker/compose/docker-compose.yml build --no-cache &&"
        fi
    fi

    START_BUILD_CONTAINER_COMMAND="${BUILD_CONTAINER_COMMAND} yes | DB_PORT=${DB_PORT_EXPOSED_ON_DB_CONTAINER} WEB_APP_PORT=${WEB_APP_PORT} NODE_ENV=${NODE_ENV} docker-compose -f ../docker/compose/docker-compose.yml up ${COMPOSE_UP_OPTS}"

     # Start the container

    echo "starting ${MS_NAME} by executing command: ${START_BUILD_CONTAINER_COMMAND}"

    local START_BUILD_CONTAINER_COMMAND_RESULT=
    eval "${START_BUILD_CONTAINER_COMMAND}; START_BUILD_CONTAINER_COMMAND_RESULT=$?"

    if [ "${START_BUILD_CONTAINER_COMMAND}" -eq 0 ]; then
        echo "executed start container command on  ${MS_NAME} successfully!!"

    fi

    return ${START_BUILD_CONTAINER_COMMAND_RESULT}
}

# Starts the microservice by default.
#if you wanna build the container before starting without trying to start the container 1st, then make sure that the second argument passed to
#the function is true
#
#Arguments
#    $1 = variables.sh - a file that contains container specific variables
#    $2 = BUILD_CONTAINER - a boolean (either true of false) that determines whether the services containers will be
#                           built before starting
#    $3 = COMPOSE_UP_OPTS - the options that are supplied to the docker-compose up command e.g. '-d'
#
build_start_microservice_containers (){

    MS_VARIABLES_FILE=$1
    check_and_source_variables_file ${MS_VARIABLES_FILE}

    MS_SERVICE_TYPE=$2

    # If BUILD_CONTAINER variable is not set to 'true', then the containers will only be run and not built
    # By default if there is no argument passed to this script, the BUILD_CONTAINER variable will set to 'true'
    # This means that default behaviour of this script is to build and run the container
    # i.e. `$ ./build_run_docker_containers.sh` without any arguments will build and run the container
    # If you dont want to build the container and you only want to run the container, you can run the
    # script with the first argument as anything other than 'true'. For instance pass 'false' as the first argument
    # e.g. `$ ./build_run_docker_containers.sh false`
    BUILD_CONTAINER=$3
    COMPOSE_UP_OPTS=$4

    # Start the containers

    start_db_container ${MS_VARIABLES_FILE}
    start_service_container ${MS_VARIABLES_FILE} ${MS_SERVICE_TYPE}

    # Get status returned when start_service_container was called
    START_SERVICE_CONTAINER_RES=$?

    echo "Start container command on ${MS_NAME} returned status code: ${START_SERVICE_CONTAINER_RES}"
    if [ ${START_SERVICE_CONTAINER_RES} -ne 0 ]; then

        echo "Oops!. container failed to start... will try to build and starting the container again"
        #BUILD_CONTAINER=true
        start_service_container ${MS_VARIABLES_FILE} ${MS_SERVICE_TYPE} true
    fi
}

# builds a nodejs docker image
# Args:
#   dockerHubUsername ($1) - The dockerhub username
#
build_nodejs_docker_image() {
  dockerHubUsername=${1:-${DOCKERHUB_USERNAME}}
  imageName=$(cat "project.json" | jq '.name')

  if [ -z "${dockerHubUsername}" ]; then
    echo "Error: The dockerhub username is required"
  fi

  docker build . -t "${dockerHubUsername}"/"${imageName}"
}


# Pushes a nodejs docker image to docker hub
# Args:
#   dockerHubUsername ($1) - The dockerhub username
#   dockerHubPassword ($2) - The dockerhub password
#   imageVersion: ($3) - image version to be used a tag. If not supplied, will be set to "latest"
#
push_nodejs_docker_image_to_dockerhub() {
  dockerHubUsername=${1:-${DOCKERHUB_USERNAME}}
  dockerHubPassword=${2:-${DOCKERHUB_PASSWORD}}
  imageVersion=${3:-latest}
  imageName=$(cat "project.json" | jq '.name')

  if [ -z "${dockerHubUsername}" ]; then
    echo "Error: The dockerhub username is required"
  fi

  if [ -z "${dockerHubPassword}" ]; then
      echo "Error: The dockerhub password is required"
  fi


  docker login --username "${dockerHubUsername}" --password "${dockerHubPassword}"

  # docker tag "${dockerHubUsername}"/"${imageName}" "${dockerHubUsername}"/"${imageName}:$imageVersion"

  docker push "${dockerHubUsername}"/"${imageName}:$imageVersion"
}
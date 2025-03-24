#!/bin/bash
# suit-deploy-docker-compose-local.sh
# Autor: Jorge Reyes
#
# Dependencias:
# - Docker instalado y en ejecución.
# - Docker Compose instalado.
# - El archivo .env en la raíz del proyecto.

set -e  # Salir inmediatamente si un comando falla

# Incluir funciones de utilidad
source scripts/commands/main.sh

######################################
# Declarar variables con valores por defecto
######################################
: "${SUITE_PROJECT_NAME:=ms_suite}"  # Nombre del proyecto por defecto si no está definido

######################################
# Validar y cargar variables de entorno
######################################
validate_environment() {
    if [ ! -f ".env" ]; then
        log "Archivo .env no encontrado. Abortando."
        exit 1
    fi
}

source_env_vars() {
    local env_file="$1"
    export $(grep -v '^#' "$env_file" | xargs)
}

######################################
# Inicializar contenedores
######################################
init_suite_containers() {
    init_docker_containers \
        "${SUITE_PROJECT_NAME}" \
        "./docker/docker-compose-smartpos.yml" \
        "$1" \
        "Servicios Pagos Iniciados." \
        "No se pudo iniciar Servicios Pagos. Verifica el archivo docker-compose."
}

######################################
# Función para estado de contenedores
######################################
status_suite_containers() {
    status_docker_containers \
        "${SUITE_PROJECT_NAME}" \
        "./scripts/docker/docker-compose-smartpos.yml"
}

######################################
# Función principal
######################################
main() {
    # validate_environment
    # source_env_vars ".env"

    validate_environment_docker

    if [[ "$1" == "--status" ]]; then
        status_suite_containers
        exit 0
    fi

    init_suite_containers "$1"
    log "Inicialización de Servicios Pagos completada exitosamente."
}

# Ejecutar función principal
main "$@"

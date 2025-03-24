#!/bin/bash
# Autor: Jorge Reyes
#
# Descripción:
# Este script valida el entorno de Docker/Docker Compose, permite limpiar
# contenedores (y volúmenes), inicializarlos y mostrar su estado detallado.
# Utiliza los comandos de Docker Compose para manejar los servicios
# definidos en un archivo docker-compose.yml.
#
# Dependencias:
# - Docker instalado y en ejecución.
# - Docker Compose instalado.

# ----------------------------------------------------------------------------
# Validar Docker y Docker Compose
# ----------------------------------------------------------------------------
validate_environment_docker() {
    warning "Validando Docker y Docker Compose..."
    breakline
    validate_docker_and_compose
    info "Validación completa."
    breakline
}

# ----------------------------------------------------------------------------
# Función para validar Docker y Docker Compose
# ----------------------------------------------------------------------------
validate_docker_and_compose() {
    # Validar si el comando 'docker' existe
    if ! command -v docker &>/dev/null; then
        critical_error "Docker no está instalado. Instálalo antes de continuar."
        return
    fi

    # Dependiendo del sistema operativo, verificar si Docker está activo
    case "$OSTYPE" in
        linux-gnu*)
            systemctl is-active --quiet docker || critical_error "Docker no está activo. Inícialo antes de continuar."
            ;;
        darwin*)
            pgrep -x "Docker" >/dev/null || critical_error "Docker no está activo. Inícialo antes de continuar."
            ;;
        msys*)
            docker info >/dev/null 2>&1 || critical_error "Docker no está activo. Inícialo antes de continuar."
            ;;
        *)
            critical_error "Sistema operativo no compatible."
            return
            ;;
    esac

    # Validar si el comando 'docker-compose' existe
    if ! command -v docker-compose &>/dev/null; then
        critical_error "docker-compose no está instalado. Consulta la documentación para instalarlo."
        return
    fi

    # Si todo está correcto, mostrar mensaje de éxito
    info "Docker y docker-compose están instalados y funcionando correctamente."
    breakline
}

# ----------------------------------------------------------------------------
# Limpiar contenedores y volúmenes
# ----------------------------------------------------------------------------
cleanup_docker() {
    local project_name="$1"
    local build_flag="$2"
    local compose_file="$3"

    warning "Iniciando limpieza de contenedores..."
    breakline

    # Si se especificó el flag '--build', se eliminan contenedores, volúmenes y orfanatos
    if [ "$build_flag" == "--build" ]; then
        docker-compose -p "${project_name}" -f "${compose_file}" down --volumes --remove-orphans
        info "Contenedores, volúmenes y orfanatos limpiados."
    else
        # En caso contrario, solo se eliminan contenedores
        docker-compose -p "${project_name}" -f "${compose_file}" down
        info "Contenedores limpiados."
    fi

    breakline
}

# ----------------------------------------------------------------------------
# Inicializar contenedores usando docker-compose
# ----------------------------------------------------------------------------
init_docker_containers() {
    local project_name="$1"
    local compose_file="$2"
    local build_flag="$3"
    local success_message="$4"
    local failure_message="$5"

    warning "Iniciando contenedores de ${project_name}..."
    breakline

    # Primero se limpian contenedores/volúmenes según corresponda
    cleanup_docker "$project_name" "$build_flag" "$compose_file"

    # Se levantan los contenedores en modo 'detached'
    docker-compose -p "${project_name}" -f "${compose_file}" up ${build_flag} -d || {
        critical_error "${failure_message}"
    }

    breakline
    success "${success_message}"
    breakline
}

# ----------------------------------------------------------------------------
# Mostrar el estado detallado de los contenedores (docker compose ps)
# ----------------------------------------------------------------------------
status_docker_containers() {
    local project_name="$1"
    local compose_file="$2"

    warning "Consultando el estado de los contenedores para el proyecto '${project_name}'..."
    breakline

    # Se muestra la información detallada de los contenedores activos
    docker-compose -p "${project_name}" -f "${compose_file}" ps || {
        critical_error "No se pudo obtener el estado de los contenedores de '${project_name}'."
    }

    breakline
    info "Estado de contenedores consultado con éxito."
    breakline
}

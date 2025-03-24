#!/bin/bash
# terminal_utils.sh

# === Sección: Declaración de colores ===
# Colores para la terminal
declare COLOR_RESET="\e[0m"          # Resetear color al finalizar
declare COLOR_BOLD="\e[1m"           # Texto en negrita
declare COLOR_INFO="\e[36m"          # Cyan para información
declare COLOR_LOG="\e[94m"           # Azul claro para mensajes generales
declare COLOR_SUCCESS="\e[92m"       # Verde para éxito
declare COLOR_WARNING="\e[33m"       # Amarillo para advertencias
declare COLOR_ERROR="\e[91m"         # Rojo para errores

# === Sección: Funciones de mensajes ===
# Función para imprimir mensajes informativos
info() {
    echo -e "${COLOR_INFO}[INFO] ${COLOR_BOLD}$1${COLOR_RESET}"
}

# Función para imprimir mensajes generales
log() {
    echo -e "${COLOR_LOG}[LOG] ${COLOR_BOLD}$1${COLOR_RESET}"
}

# Función para imprimir mensajes de éxito
success() {
    echo -e "${COLOR_SUCCESS}[SUCCESS] ${COLOR_BOLD}$1${COLOR_RESET}"
}

# Función para imprimir mensajes de advertencia
warning() {
    echo -e "${COLOR_WARNING}[WARNING] ${COLOR_BOLD}$1${COLOR_RESET}"
}

# Función para imprimir mensajes de error
error() {
    echo -e "${COLOR_ERROR}[ERROR] ${COLOR_BOLD}$1${COLOR_RESET}"
}

# Función para imprimir mensajes de error crítico y salir
critical_error() {
    echo -e "${COLOR_ERROR}[CRITICAL ERROR] ${COLOR_BOLD}$1${COLOR_RESET}"
    exit 1
}

# Función para imprimir mensajes de depuración (solo si DEBUG_MODE está activado)
debug() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "${COLOR_INFO}[DEBUG] ${COLOR_BOLD}$1${COLOR_RESET}"
    fi
}

# === Sección: Funciones de utilidad ===
# Función para imprimir líneas de separación
breakline() {
    local lines=${1:-1}
    for ((i = 0; i < lines; i++)); do
        echo ""
    done
}

# Función para cargar variables de entorno desde el archivo .env
source_env_vars() {
    local env_file="$1"
    
    if [ -f "$env_file" ]; then
        # Cargar variables de entorno desde el archivo
        export $(grep -v '^#' "$env_file" | xargs)
        
        # Mensaje de éxito
        info "Variables de entorno cargadas desde $env_file."
        breakline
    else
        # Mensaje de error crítico
        critical_error "Archivo $env_file no encontrado. Verifica su existencia y ubicación."
    fi
}



# Función para registrar un mensaje en un archivo de registro
log_file() {
    local log_file="script.log"
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') - $1" >>"$log_file"
}

# Función para verificar versión de comandos instalados
check_command_version() {
    local command=$1
    local label=$2
    
    if command -v $command &>/dev/null; then
        # Obtener la versión del comando
        local version=$($command --version)
        
        # Mensaje informativo con la versión
        log "$label: $version"
    else
        # Mensaje de advertencia si el comando no está instalado
        log "$label no está instalado. Por favor, instálalo para asegurar el correcto funcionamiento del sistema."
    fi
}

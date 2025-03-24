#!/bin/bash
# minikube-control.sh
# Autor: Jorge Reyes
#
# Descripción:
# Este script permite:
#  - Subir Minikube con --minikube=up (elige el driver más compatible y arranca el clúster)
#  - Bajar Minikube con --minikube=down (detiene Minikube)
#  - Eliminar Minikube con --minikube=reset (ejecuta minikube delete)
#  - Mostrar ayuda con --minikube=help
#
# Requisitos:
# - Docker Desktop (recomendado) o Hyper-V configurado con un Virtual Switch
#
# Uso:
#   chmod +x minikube-control.sh
#   ./minikube-control.sh --minikube=up
#   ./minikube-control.sh --minikube=down
#   ./minikube-control.sh --minikube=up --driver=docker
#   ./minikube-control.sh --minikube=reset
#   ./minikube-control.sh --minikube=help

set -e  # Salir si algún comando falla

# Incluir funciones de utilidad
source scripts/commands/main.sh

# Configuración de recursos para el clúster Minikube
MINIKUBE_DRIVER="hyperv"       # Valor por defecto (puede ser sobrescrito con --driver=)
MINIKUBE_ACTION=""             # up, down, reset, help
MINIKUBE_DOCKER_STATIC_IP=192.168.250.200
MINIKUBE_DOCKER_SUBNET=192.168.250.0/24
MINIKUBE_DOCKER_GATEWAY=192.168.250.1
MINIKUBE_DOCKER_NETWORK_NAME="minikube-static-net"
MINIKUBE_CPUS=4
MINIKUBE_MEMORY=8192
MINIKUBE_DISK="40g"
HYPERV_SWITCH="minikube-external"

######################################
# Procesa argumentos y sobrescribe variables globales
######################################
parse_args() {
  for arg in "$@"; do
    case $arg in
      --driver=*)
        MINIKUBE_DRIVER="${arg#*=}"
        ;;
      --minikube=*)
        MINIKUBE_ACTION="${arg#*=}"
        ;;
      *)
        warning "⚠️ Argumento no reconocido: $arg"
        ;;
    esac
  done
}

######################################
# Verifica que Minikube esté disponible en el sistema
######################################
validate_minikube() {
  log "[CMD] command -v minikube"
  if ! command -v minikube &>/dev/null; then
    critical_error "Minikube no está instalado o no está en el PATH."
  fi
  info "✔ Minikube está instalado."
  breakline
}

######################################
# Verifica que Docker esté disponible y funcional
######################################
validate_docker() {
  log "[CMD] command -v docker && docker info"
  if command -v docker &>/dev/null && docker info &>/dev/null; then
    return 0
  else
    return 1
  fi
}

######################################
# Valida que el Virtual Switch de Hyper-V exista
######################################
validate_hyperv_switch() {
  log "[CMD] powershell.exe -Command \"Get-VMSwitch -Name '${HYPERV_SWITCH}'\""
  powershell.exe -Command "Get-VMSwitch -Name '${HYPERV_SWITCH}'" &>/dev/null || {
    critical_error "❌ No se encontró el Virtual Switch '${HYPERV_SWITCH}' en Hyper-V. Revisa con: Get-VMSwitch"
  }
  breakline
}

######################################
# Configura el driver para Minikube basado en MINIKUBE_DRIVER
######################################
set_driver() {
  DRIVER="$MINIKUBE_DRIVER"

  if [[ "$DRIVER" == "docker" ]]; then
    if validate_docker; then
      info "🧩 Usando driver Docker según configuración (--driver=docker)"
    else
      critical_error "Docker no está disponible aunque se especificó como driver."
    fi
  elif [[ "$DRIVER" == "hyperv" ]]; then
    validate_hyperv_switch
    info "🧩 Usando driver Hyper-V según configuración (--driver=hyperv o por defecto)"
  else
    critical_error "Driver no válido: '$DRIVER'. Usa --driver=docker o --driver=hyperv"
  fi

  log "[CMD] minikube config set driver $DRIVER"
  minikube config set driver "$DRIVER"
  breakline
}

######################################
# Inicia el clúster Minikube con los parámetros definidos
######################################
start_minikube() {
  info "🚀 Iniciando Minikube con driver '$DRIVER'..."

  if [[ "$DRIVER" == "hyperv" ]]; then
    log "[CMD] minikube start --driver=hyperv --hyperv-virtual-switch=\"$HYPERV_SWITCH\" --cpus=$MINIKUBE_CPUS --memory=$MINIKUBE_MEMORY --disk-size=$MINIKUBE_DISK"
    minikube start \
      --driver=hyperv \
      --hyperv-virtual-switch="${HYPERV_SWITCH}" \
      --cpus="$MINIKUBE_CPUS" \
      --memory="$MINIKUBE_MEMORY" \
      --disk-size="$MINIKUBE_DISK"
  else
    # Crear red personalizada de Docker si no existe
    if ! docker network inspect "$MINIKUBE_DOCKER_NETWORK_NAME" &>/dev/null; then
      info "🧱 Creando red Docker '$MINIKUBE_DOCKER_NETWORK_NAME' con subnet $MINIKUBE_DOCKER_SUBNET..."
      log "[CMD] docker network create --subnet=$MINIKUBE_DOCKER_SUBNET --gateway=$MINIKUBE_DOCKER_GATEWAY $MINIKUBE_DOCKER_NETWORK_NAME"
      docker network create --subnet="$MINIKUBE_DOCKER_SUBNET" --gateway="$MINIKUBE_DOCKER_GATEWAY" "$MINIKUBE_DOCKER_NETWORK_NAME"
    else
      info "📡 La red Docker '$MINIKUBE_DOCKER_NETWORK_NAME' ya existe."
    fi

    log "[CMD] minikube start --driver=docker --static-ip=$MINIKUBE_DOCKER_STATIC_IP --subnet=$MINIKUBE_DOCKER_SUBNET --network=$MINIKUBE_DOCKER_NETWORK_NAME --cpus=$MINIKUBE_CPUS --memory=$MINIKUBE_MEMORY --disk-size=$MINIKUBE_DISK"
    minikube start \
      --driver=docker \
      --static-ip="$MINIKUBE_DOCKER_STATIC_IP" \
      --subnet="$MINIKUBE_DOCKER_SUBNET" \
      --network="$MINIKUBE_DOCKER_NETWORK_NAME" \
      --cpus="$MINIKUBE_CPUS" \
      --memory="$MINIKUBE_MEMORY" \
      --disk-size="$MINIKUBE_DISK"
  fi

  breakline
  success "✅ Minikube iniciado correctamente con driver '$DRIVER'."
}

######################################
# Detiene el clúster Minikube si está corriendo
######################################
stop_minikube() {
  info "🛑 Deteniendo Minikube..."

  log "[CMD] minikube stop"
  minikube stop || warning "⚠️ Minikube no pudo detenerse normalmente."

  breakline
  success "✅ Minikube detenido correctamente."
}

######################################
# Elimina el clúster Minikube
######################################
reset_minikube() {
  info "🧨 Eliminando clúster Minikube..."

  log "[CMD] minikube delete --all"
  minikube delete --all

  breakline
  success "🧼 Minikube eliminado completamente."
}

######################################
# Elimina y purgar el clúster Minikube
######################################
reset_minikube() {
  info "🧨 Eliminando clúster Minikube..."

  log "[CMD] minikube delete --all"
  minikube delete --all --purge

  breakline
  success "🧼 Minikube eliminado completamente."
}

######################################
# Muestra ayuda de uso
######################################
show_help() {
  echo "🆘 Uso del script minikube-control.sh:"
  echo ""
  echo "  --minikube=up       Inicia Minikube (driver por defecto: hyperv)"
  echo "  --minikube=down     Detiene Minikube"
  echo "  --minikube=reset    Elimina Minikube completamente"
  echo "  --minikube=help     Muestra esta ayuda"
  echo "  --driver=docker     (opcional) Usa Docker como driver"
  echo "  --driver=hyperv     (opcional) Usa Hyper-V como driver (default)"
  echo ""
}

######################################
# Función principal
######################################
main() {
  parse_args "$@"           # Procesar --driver y --minikube
  validate_minikube

  case "$MINIKUBE_ACTION" in
    up)
      set_driver
      start_minikube
      ;;
    down)
      set_driver
      stop_minikube
      ;;
    reset)
      reset_minikube
      ;;
    purge)
      reset_minikube
      ;;
    help)
      show_help
      ;;
    "")
      warning "⚠️ No se especificó acción. Usa --minikube=up, --minikube=down, --minikube=reset o --minikube=help"
      ;;
    *)
      warning "⚠️ Acción no válida: '$MINIKUBE_ACTION'. Usa --minikube=up, --minikube=down, --minikube=reset o --minikube=help"
      ;;
  esac
}

# Ejecutar función principal
main "$@"

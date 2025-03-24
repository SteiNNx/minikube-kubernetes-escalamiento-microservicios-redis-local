#!/bin/bash

# Script para crear, eliminar o reemplazar un Virtual Switch externo en Hyper-V
# Ejecutar desde Git Bash con permisos de administrador

set -e  # Salir si algún comando falla

# ✅ Importar utilidades
source scripts/commands/main.sh

# 🔧 Variables fijas
SWITCH_NAME="minikube-external"
SWITCH_ACTION=""
NET_ADAPTER_NAME="$(powershell.exe -Command "(Get-NetAdapter | Where-Object { \$_.Status -eq 'Up' -and \$_.Virtual -eq \$false })[0].Name" | tr -d '\r')"

######################################
# Procesa argumentos del script
######################################
parse_args() {
  for arg in "$@"; do
    case $arg in
      --switch=create|--switch=delete|--switch=recreate)
        SWITCH_ACTION="${arg#*=}"
        ;;
      *)
        warning "⚠️ Argumento no reconocido: $arg"
        ;;
    esac
  done
}

######################################
# Crear switch
######################################
create_switch() {
  info "🧩 Verificando si ya existe un Virtual Switch llamado '$SWITCH_NAME'..."
  if powershell.exe -Command "Get-VMSwitch -Name '$SWITCH_NAME'" &>/dev/null; then
    warning "⚠️ Ya existe un Virtual Switch llamado '$SWITCH_NAME'. Usa --switch=delete o --switch=recreate si quieres reemplazarlo."
    return
  fi

  info "🌐 Creando Virtual Switch '$SWITCH_NAME' con adaptador '$NET_ADAPTER_NAME'..."
  powershell.exe -Command "New-VMSwitch -Name '$SWITCH_NAME' -NetAdapterName '$NET_ADAPTER_NAME' -AllowManagementOS \$true" > /dev/null
  success "✅ Switch '$SWITCH_NAME' creado correctamente."
  breakline
}

######################################
# Eliminar switch
######################################
delete_switch() {
  info "🗑️ Eliminando Virtual Switch '$SWITCH_NAME'..."
  powershell.exe -Command "Remove-VMSwitch -Name '$SWITCH_NAME' -Force" > /dev/null
  success "✅ Switch '$SWITCH_NAME' eliminado correctamente."
  breakline
}

######################################
# Mostrar uso
######################################
usage() {
  echo "Uso: $0 --switch=[create|delete|recreate]"
  echo ""
  echo "Ejemplos:"
  echo "  $0 --switch=create"
  echo "  $0 --switch=delete"
  echo "  $0 --switch=recreate"
  exit 1
}

######################################
# Función principal
######################################
main() {
  parse_args "$@"

  if [[ -z "$SWITCH_ACTION" ]]; then
    usage
  fi

  case "$SWITCH_ACTION" in
    create)
      create_switch
      ;;
    delete)
      delete_switch
      ;;
    recreate)
      delete_switch
      create_switch
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"

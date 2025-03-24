#!/bin/bash
# suit-deploy-k8s-local.sh
# Autor: Jorge Reyes
#
# Descripción:
# Este script permite:
#  - Desplegar los recursos (MS y Redis) en Kubernetes con --k8s=deploy (y en este caso construye las imágenes MS).
#  - Eliminar los recursos desplegados con --k8s=down (sin reconstruir imágenes).
#  - Obtener las URLs/IPs de los servicios desplegados con --k8s=ips.
#  - Obtener los logs de las aplicaciones MS y Redis con --k8s=logs.
#
# Dependencias:
# - Docker, Docker Compose
# - Minikube
# - kubectl

set -e  # Salir inmediatamente si un comando falla

# Incluir funciones de utilidad
source scripts/commands/main.sh

MINIKUBE_DRIVER_ACTUAL=$(minikube config get driver 2>/dev/null || echo "$MINIKUBE_DRIVER")
K8S_ACTION=""

######################################
# Procesa argumentos del script
######################################
parse_args() {
  for arg in "$@"; do
    case $arg in
      --k8s=deploy|--k8s=down|--k8s=ips|--k8s=logs)
        K8S_ACTION="${arg#*=}"
        ;;
      *)
        warning "⚠️ Argumento no reconocido: $arg"
        ;;
    esac
  done
}

######################################
# Validar existencia de Minikube
######################################
validate_minikube() {
    if ! command -v minikube &>/dev/null; then
        critical_error "Minikube no está instalado o no se encuentra en el PATH. Por favor, instálalo antes de continuar."
    fi
    info "Minikube está instalado."
}

######################################
# Construir Imágenes MS
######################################
init_build_images_ms() {
    log "[CMD] docker context use default"
    docker context use default

    info "Construyendo imagen ms-api-pos..."
    log "[CMD] docker build -t ms-api-pos:local -f docker/Dockerfile.ms-api-pos ."
    docker build -t ms-api-pos:local -f docker/Dockerfile.ms-api-pos .
    minikube image load ms-api-pos:local
    breakline

    info "Construyendo imagen ms-api-pos-pagos-ms..."
    log "[CMD] docker build -t ms-api-pos-pagos-ms:local -f docker/Dockerfile.ms-api-pos-pagos-ms ."
    docker build -t ms-api-pos-pagos-ms:local -f docker/Dockerfile.ms-api-pos-pagos-ms .
    minikube image load ms-api-pos-pagos-ms:local
    breakline
}

######################################
# Desplegar recursos en Kubernetes (MS y Redis)
######################################
deploy_k8s_manifests_all() {
    info "Desplegando ms-api-pos en Kubernetes..."
    kubectl apply -f kubernetes/minikube/ms-api-pos/deployment.yaml
    kubectl apply -f kubernetes/minikube/ms-api-pos/service.yaml
    breakline

    info "Desplegando ms-api-pos-pagos-ms en Kubernetes..."
    kubectl apply -f kubernetes/minikube/ms-api-pos-pagos-ms/deployment.yaml
    kubectl apply -f kubernetes/minikube/ms-api-pos-pagos-ms/service.yaml
    breakline

    info "Desplegando Redis en Kubernetes..."
    kubectl apply -f kubernetes/minikube/redis/deployment.yaml
    kubectl apply -f kubernetes/minikube/redis/service.yaml
    breakline

    success "Todos los recursos fueron desplegados. Verifica con: kubectl get pods"
}

######################################
# Eliminar recursos de Kubernetes (MS y Redis)
######################################
down_k8s_manifests_all() {
    info "Eliminando despliegue ms-api-pos..."
    kubectl delete -f kubernetes/minikube/ms-api-pos/service.yaml || warning "Problema eliminando Service"
    kubectl delete -f kubernetes/minikube/ms-api-pos/deployment.yaml || warning "Problema eliminando Deployment"
    breakline

    info "Eliminando despliegue ms-api-pos-pagos-ms..."
    kubectl delete -f kubernetes/minikube/ms-api-pos-pagos-ms/service.yaml || warning "Problema eliminando Service"
    kubectl delete -f kubernetes/minikube/ms-api-pos-pagos-ms/deployment.yaml || warning "Problema eliminando Deployment"
    breakline

    info "Eliminando despliegue de Redis..."
    kubectl delete -f kubernetes/minikube/redis/service.yaml || warning "Problema eliminando Service"
    kubectl delete -f kubernetes/minikube/redis/deployment.yaml || warning "Problema eliminando Deployment"
    breakline

    success "Recursos eliminados. Verifica con: kubectl get pods, kubectl get svc"
}

######################################
# Obtener URLs/IPs de servicios MS y Redis
######################################
get_ips_all() {
    info "Obteniendo servicios Kubernetes (MS y Redis)..."
    kubectl get svc ms-api-pos-service ms-api-pos-pagos-ms-service redis-service
    breakline

    if [[ "$MINIKUBE_DRIVER_ACTUAL" == "docker" ]]; then
        info "🐳 Usando Docker como driver. Ejecutando minikube service..."
        minikube service ms-api-pos-service
        breakline
        minikube service ms-api-pos-pagos-ms-service
        breakline
        minikube service redis-service
        breakline
    else
        info "🌐 URLs expuestas:"
        info "ms-api-pos-service:"
        minikube service ms-api-pos-service --url
        breakline
        info "ms-api-pos-pagos-ms-service:"
        minikube service ms-api-pos-pagos-ms-service --url
        breakline
        info "redis-service:"
        minikube service redis-service --url
        breakline
    fi

    breakline
    success "IPs obtenidas correctamente."
}

######################################
# Obtener logs de MS y Redis
######################################
get_logs_all() {
    info "Logs de ms-api-pos..."
    kubectl logs deployment/ms-api-pos --all-containers=true --tail=50
    breakline

    info "Logs de ms-api-pos-pagos-ms..."
    kubectl logs deployment/ms-api-pos-pagos-ms --all-containers=true --tail=50
    breakline

    info "Logs de Redis..."
    kubectl logs deployment/redis --all-containers=true --tail=50
    breakline

    success "Logs obtenidos."
}

######################################
# Función principal
######################################
main() {
    # Validación previa
    validate_minikube
    validate_environment_docker

    # Parsear argumentos
    parse_args "$@"

    case "$K8S_ACTION" in
        deploy)
            init_build_images_ms
            deploy_k8s_manifests_all
            breakline
            ;;
        down)
            down_k8s_manifests_all
            breakline
            ;;
        ips)
            get_ips_all
            breakline
            ;;
        logs)
            get_logs_all
            breakline
            ;;
        "")
            warning "No se solicitó acción. Usa: --k8s=deploy | --k8s=down | --k8s=ips | --k8s=logs"
            ;;
        *)
            warning "Acción no válida: $K8S_ACTION. Usa: --k8s=deploy | --k8s=down | --k8s=ips | --k8s=logs"
            ;;
    esac
}

# Ejecutar función principal
main "$@"

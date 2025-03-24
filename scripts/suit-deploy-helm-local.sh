#!/bin/bash
# suit-deploy-helm-local.sh
# Autor: Jorge Reyes

# Requiere:
# - Docker, Helm, Minikube, kubectl

set -e

source scripts/commands/main.sh

validate_minikube() {
    if ! command -v minikube &>/dev/null; then
        critical_error "Minikube no está instalado. Instálalo y vuelve a intentar."
    fi
    info "Minikube está disponible."
}

# =========================
# Build imágenes locales
# =========================
build_images() {
    docker context use default

    info "Construyendo imagen ms-api-pos..."
    docker build -t ms-api-pos:local -f docker/Dockerfile.ms-api-pos .
    minikube image load ms-api-pos:local
    breakline

    info "Construyendo imagen ms-api-pos-pagos-ms..."
    docker build -t ms-api-pos-pagos-ms:local -f docker/Dockerfile.ms-api-pos-pagos-ms .
    minikube image load ms-api-pos-pagos-ms:local
    breakline

    success "Imágenes construidas y cargadas a Minikube."
}

# =========================
# Helm install
# =========================
helm_install_all() {
    info "Desplegando Redis con Helm..."
    helm upgrade --install redis kubernetes/helm/redis
    breakline

    info "Desplegando ms-api-pos con Helm..."
    helm upgrade --install ms-api-pos kubernetes/helm/ms-api-pos
    breakline

    info "Desplegando ms-api-pos-pagos-ms con Helm..."
    helm upgrade --install ms-api-pos-pagos-ms kubernetes/helm/ms-api-pos-pagos-ms
    breakline

    success "Todos los charts desplegados con éxito."
}

# =========================
# Helm uninstall
# =========================
helm_uninstall_all() {
    info "Eliminando charts Helm..."

    helm uninstall ms-api-pos || warning "ms-api-pos no fue encontrado"
    helm uninstall ms-api-pos-pagos-ms || warning "ms-api-pos-pagos-ms no fue encontrado"
    helm uninstall redis || warning "redis no fue encontrado"

    breakline
    success "Todos los charts fueron eliminados."
}

# =========================
# Obtener URLs
# =========================
get_services_urls() {
    info "Servicios desplegados:"
    kubectl get svc redis-service ms-api-pos-service ms-api-pos-pagos-ms-service
    breakline

    DRIVER_ACTUAL=$(minikube config get driver 2>/dev/null || echo "$MINIKUBE_DRIVER")

    if [[ "$DRIVER_ACTUAL" == "docker" ]]; then
        minikube service redis-service
        minikube service ms-api-pos-service
        minikube service ms-api-pos-pagos-ms-service
    else
        info "URL Redis:"
        minikube service redis-service --url
        breakline

        info "URL ms-api-pos:"
        minikube service ms-api-pos-service --url
        breakline

        info "URL ms-api-pos-pagos-ms:"
        minikube service ms-api-pos-pagos-ms-service --url
        breakline
    fi

    breakline
    success "URLs obtenidas correctamente."
}

# =========================
# Logs
# =========================
get_logs_all() {
    kubectl logs deployment/redis --all-containers=true --tail=50 || warning "Sin logs de Redis"
    kubectl logs deployment/ms-api-pos --all-containers=true --tail=50 || warning "Sin logs de ms-api-pos"
    kubectl logs deployment/ms-api-pos-pagos-ms --all-containers=true --tail=50 || warning "Sin logs de ms-api-pos-pagos-ms"
    breakline
    success "Logs obtenidos."
}

# =========================
# Main
# =========================
main() {
    validate_minikube
    validate_environment_docker

    case "$1" in
        --helm=deploy)
            build_images
            helm_install_all
            ;;
        --helm=down)
            helm_uninstall_all
            ;;
        --helm=ips)
            get_services_urls
            ;;
        --helm=logs)
            get_logs_all
            ;;
        *)
            warning "Comando no reconocido. Usa: --helm=deploy, --helm=down, --helm=ips, --helm=logs"
            ;;
    esac
}

main "$@"

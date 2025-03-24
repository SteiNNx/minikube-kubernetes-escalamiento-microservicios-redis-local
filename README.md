# 🚀 Minikube Kubernetes: Escalamiento de Microservicios + Redis en Entorno Local

Este proyecto permite desplegar microservicios y Redis sobre un clúster local de **Minikube** utilizando **Kubernetes**, ideal para pruebas y desarrollo en entorno Windows con **Hyper-V**.

---

## 📋 Requisitos Previos

### 🖥️ Sistema Operativo
- **Windows 10 Pro/Enterprise** o **Windows 11** (ediciones que soportan **Hyper-V**).

### ⚙️ Configuración del Sistema
- **Virtualización habilitada** en BIOS (Intel VT-x o AMD-V).
- **Permisos de administrador** para instalar componentes del sistema y crear redes virtuales.

---

## 🧰 Instalación de Herramientas

### 1. Habilitar Hyper-V
1. Abre el panel de **"Activar o desactivar características de Windows"**.
2. Marca las siguientes opciones:
   - ✅ Hyper-V  
   - ✅ Plataforma de Máquina Virtual  
   - ✅ Herramientas de administración de Hyper-V  
3. Reinicia tu equipo para aplicar los cambios.
4. Ejecutar script set-manage-hyperv-switch.sh para configurar virtual machine

### 2. Instalar Minikube y Kubectl
- **Minikube:** [Descargar minikube-installer.exe](https://storage.googleapis.com/minikube/releases/latest/minikube-installer.exe)  
- **Kubectl:** [Descargar kubectl.exe](https://dl.k8s.io/release/v1.32.0/bin/windows/amd64/kubectl.exe)
- **Helm:** [Releases](https://github.com/helm/helm/releases)
   - [Windows](https://get.helm.sh/helm-v3.17.2-windows-amd64.zip)

---

## 🚦 Inicialización del Entorno

### ▶️ Configurar VirtualMachine con Hyper-V

```bash
# Crear VM para Hyper-V Minikube
sh scripts/set-manage-hyperv-switch.sh --switch=create

# Borrar VM para Hyper-V Minikube
sh scripts/set-manage-hyperv-switch.sh --switch=delete

# Borrar/Crear VM para Hyper-V Minikube
sh scripts/set-manage-hyperv-switch.sh --switch=recreate

```

### ▶️ Iniciar/Detener Minikube

```bash
# Subir Minikube usando el driver por defecto (hyperv)
sh scripts/minikube-control.sh --minikube=up

# Bajar (detener) Minikube
sh scripts/minikube-control.sh --minikube=down

# Subir Minikube usando el driver Docker
sh scripts/minikube-control.sh --minikube=up --driver=hyperv

# Subir Minikube usando el driver Docker
sh scripts/minikube-control.sh --minikube=up --driver=docker

# Eliminar completamente el clúster Minikube
sh scripts/minikube-control.sh --minikube=reset

# Mostrar la ayuda de uso
sh scripts/minikube-control.sh --minikube=help
```

---

## 🧩 Despliegue de Microservicios y Redis - Minikube

### Microservicios y Redis

```bash
# Desplegar MS y Redis
sh scripts/suit-deploy-minikube-local --k8s=deploy

# Obtener IPs de los MS y Redis
sh scripts/suit-deploy-minikube-local --k8s=ips

# Ver logs de los MS y Redis
sh scripts/suit-deploy-minikube-local --k8s=logs

# Eliminar despliegue de MS y Redis
sh scripts/suit-deploy-minikube-local --k8s=down
```

---

## 🔗 Recursos Útiles

- [Guía de herramientas de Kubernetes](https://kubernetes.io/es/docs/tasks/tools/)
- [Documentación oficial de Minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download)
- [Configuración de Minikube con Hyper-V](https://minikube.sigs.k8s.io/docs/drivers/hyperv/)

#!/bin/bash

# Colores para mensajes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar mensajes de error y salir
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Verificar si se está ejecutando como root
if [ "$EUID" -eq 0 ]; then
    error_exit "Este script no debe ejecutarse como root directamente. Usa 'sudo' cuando el script lo solicite."
fi

echo -e "${YELLOW}Desinstalando el servicio WAHA Secure API...${NC}"
echo -e "${YELLOW}Se solicitará tu contraseña para ejecutar comandos con sudo.${NC}"

# Detener el servicio si está en ejecución
if sudo systemctl is-active --quiet waha-secure-api.service; then
    echo -e "${YELLOW}Deteniendo el servicio...${NC}"
    sudo systemctl stop waha-secure-api.service || error_exit "No se pudo detener el servicio."
fi

# Deshabilitar el servicio
echo -e "${YELLOW}Deshabilitando el servicio...${NC}"
sudo systemctl disable waha-secure-api.service || error_exit "No se pudo deshabilitar el servicio."

# Eliminar el archivo de servicio
echo -e "${YELLOW}Eliminando el archivo de servicio...${NC}"
sudo rm -f /etc/systemd/system/waha-secure-api.service || error_exit "No se pudo eliminar el archivo de servicio."

# Recargar systemd
echo -e "${YELLOW}Recargando systemd...${NC}"
sudo systemctl daemon-reload || error_exit "No se pudo recargar systemd."

echo -e "${GREEN}Servicio desinstalado correctamente.${NC}"

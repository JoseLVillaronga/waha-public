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

# Obtener el directorio actual (donde se encuentra el proyecto)
PROJECT_DIR=$(pwd)
echo -e "${YELLOW}Instalando servicio desde: $PROJECT_DIR${NC}"

# Verificar que los archivos necesarios existen
if [ ! -f "$PROJECT_DIR/main.py" ]; then
    error_exit "No se encontró el archivo main.py en el directorio actual. Asegúrate de estar en el directorio del proyecto."
fi

if [ ! -f "$PROJECT_DIR/waha-secure-api.service" ]; then
    error_exit "No se encontró el archivo waha-secure-api.service en el directorio actual."
fi

# Verificar que el entorno virtual existe
if [ ! -d "$PROJECT_DIR/venv" ]; then
    echo -e "${YELLOW}No se encontró el entorno virtual. Creando uno nuevo...${NC}"
    python3 -m venv venv || error_exit "No se pudo crear el entorno virtual."
    source venv/bin/activate
    pip install -r requirements.txt || error_exit "No se pudieron instalar las dependencias."
else
    echo -e "${GREEN}Entorno virtual encontrado.${NC}"
fi

# Crear un archivo de servicio personalizado con la ruta actual
USERNAME=$(whoami)
SERVICE_FILE="$PROJECT_DIR/waha-secure-api-$USERNAME.service"

# Copiar el archivo de servicio y reemplazar las variables
cat "$PROJECT_DIR/waha-secure-api.service" | \
    sed "s|%i|$USERNAME|g" | \
    sed "s|%d|$PROJECT_DIR|g" > "$SERVICE_FILE"

echo -e "${YELLOW}Instalando el servicio systemd...${NC}"
echo -e "${YELLOW}Se solicitará tu contraseña para ejecutar comandos con sudo.${NC}"

# Desinstalar el servicio si ya existe
if [ -f "/etc/systemd/system/waha-secure-api.service" ]; then
    echo -e "${YELLOW}El servicio ya existe. Desinstalando versión anterior...${NC}"

    # Detener el servicio si está en ejecución
    if sudo systemctl is-active --quiet waha-secure-api.service; then
        sudo systemctl stop waha-secure-api.service
    fi

    # Deshabilitar el servicio
    sudo systemctl disable waha-secure-api.service

    # Eliminar el archivo de servicio
    sudo rm -f /etc/systemd/system/waha-secure-api.service

    # Recargar systemd
    sudo systemctl daemon-reload

    echo -e "${GREEN}Servicio anterior desinstalado correctamente.${NC}"
fi

# Copiar el archivo de servicio a systemd
sudo cp "$SERVICE_FILE" /etc/systemd/system/waha-secure-api.service || error_exit "No se pudo copiar el archivo de servicio."

# Recargar systemd
sudo systemctl daemon-reload || error_exit "No se pudo recargar systemd."

# Habilitar el servicio para que se inicie al arrancar
sudo systemctl enable waha-secure-api.service || error_exit "No se pudo habilitar el servicio."

echo -e "${GREEN}Servicio instalado correctamente.${NC}"
echo -e "${YELLOW}Para iniciar el servicio:${NC} sudo systemctl start waha-secure-api.service"
echo -e "${YELLOW}Para detener el servicio:${NC} sudo systemctl stop waha-secure-api.service"
echo -e "${YELLOW}Para ver el estado del servicio:${NC} sudo systemctl status waha-secure-api.service"
echo -e "${YELLOW}Para ver los logs del servicio:${NC} sudo journalctl -u waha-secure-api.service -f"

# Preguntar si desea iniciar el servicio ahora
read -p "¿Deseas iniciar el servicio ahora? (s/n): " START_SERVICE
if [[ "$START_SERVICE" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Iniciando el servicio...${NC}"
    sudo systemctl start waha-secure-api.service || error_exit "No se pudo iniciar el servicio."
    echo -e "${GREEN}Servicio iniciado correctamente.${NC}"

    # Mostrar el estado del servicio
    sudo systemctl status waha-secure-api.service
fi

echo -e "${GREEN}¡Instalación completada!${NC}"

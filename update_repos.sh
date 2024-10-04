#!/bin/bash

# Definir colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Iniciar el agente SSH
eval "$(ssh-agent -s)"

# Añadir la clave privada al agente SSH (te pedirá la clave solo una vez)
ssh-add "$HOME/.ssh/id_rsa"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al agregar la clave privada. Asegúrate de que la ruta a la clave sea correcta y que la clave sea válida.${NC}"
    exit 1
fi

# Ruta a la carpeta de los módulos personalizados
MODULES_DIR="$HOME/ruta/de/tu/carpeta/de/repositorios"

# Cambiar al directorio donde están los módulos
cd "$MODULES_DIR" || { echo -e "${RED}No se pudo encontrar la carpeta $MODULES_DIR${NC}"; exit 1; }

# Recorrer cada subcarpeta (asumiendo que son repositorios)
for repo in */; do
    cd "$repo" || continue

    # Mostrar la ruta actual
    echo "Cambiando a directorio: $(pwd)"

    # Verificar si es un repositorio git
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${BLUE}Repositorio: ${YELLOW}$repo${NC}"
        # Obtener la rama actual
        current_branch=$(git branch --show-current)

        echo -e "${BLUE}Rama actual: ${GREEN}$current_branch${NC}"

        # Hacer git pull en la rama actual
        git pull origin "$current_branch"

        if [ $? -ne 0 ]; then
            echo -e "${RED}Problema al hacer pull en la rama $current_branch en el repositorio $repo${NC}"
            read -p "Presiona cualquier tecla para continuar..."
            cd ..
            continue
        fi

        echo -e "${GREEN}Rama $current_branch actualizada correctamente.${NC}"
    else
        echo -e "${YELLOW}No es un repositorio Git: $repo. Contenido:${NC}"
        ls -a # Muestra el contenido para verificar la existencia de .git
    fi

    # Volver al directorio principal
    cd ..
done

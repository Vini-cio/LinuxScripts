#!/bin/bash

# Definición de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Ruta a la carpeta de los módulos personalizados
MODULES_DIR="$HOME/Documentos/egob-adm/trytond-egob/trytond/custom_modules"

# Cambiar al directorio donde están los módulos
cd "$MODULES_DIR" || { echo -e "${RED}No se pudo encontrar la carpeta $MODULES_DIR${NC}"; exit 1; }

# Comprobar si se pasó un argumento para el repositorio
SPECIFIC_REPO=""
if [[ "$1" == "-r" && ! -z "$2" ]]; then
    SPECIFIC_REPO="$2/"
fi

# Iniciar el agente SSH
eval "$(ssh-agent -s)"

# Añadir la clave privada al agente SSH (te pedirá la clave solo una vez)
ssh-add "$HOME/.ssh/id_rsa"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al agregar la clave privada. Asegúrate de que la ruta a la clave sea correcta y que la clave sea válida.${NC}"
    exit 1
fi

# Encabezado
echo -e "${BLUE}Estado de los Repositorios:${NC}"

# Variable para encontrar el repositorio específico
found_repo=false

# Recorrer cada subcarpeta (asumiendo que son repositorios)
for repo in */; do
    # Si se especificó un repositorio, solo ejecutar en ese
    if [[ -n "$SPECIFIC_REPO" && "$repo" != "$SPECIFIC_REPO" ]]; then
        continue
    fi

    cd "$repo" || continue

    # Verificar si es un repositorio git
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        found_repo=true
	    current_branch=$(git rev-parse --abbrev-ref HEAD)
        # Verificar cambios en el repositorio
        if [[ $(git status --porcelain) ]]; then
            # Hay cambios no comiteados
            echo -e "${YELLOW}Repositorio: ${GREEN}$repo${NC}"
            echo -e "${YELLOW}Rama: ${GREEN}$current_branch${NC}"
            echo -e "${YELLOW}Estado: ${RED}Cambios no comiteados${NC}"
        else
            # Verificar si hay cambios pendientes de commit
            if [[ $(git log --oneline --pretty=format:"%h" origin/$(git rev-parse --abbrev-ref HEAD)..HEAD) ]]; then
                # Hay cambios comiteados pero no enviados
                echo -e "${YELLOW}Repositorio: ${GREEN}$repo${NC}"
                echo -e "${YELLOW}Rama: ${GREEN}$current_branch${NC}"
		        echo -e "${YELLOW}Estado: ${RED}Cambios comiteados no enviados${NC}"
            else
                # No hay cambios, realizar git pull
                echo -e "${YELLOW}Repositorio: ${GREEN}$repo${NC}"
                echo -e "${YELLOW}Rama: ${GREEN}$current_branch${NC}"
		        echo -e "${YELLOW}Estado: ${BLUE}Sin cambios, realizando git pull...${NC}"
                git pull origin "$(git rev-parse --abbrev-ref HEAD)" > /dev/null 2>&1

                if [ $? -ne 0 ]; then
                    echo -e "${RED}Problema al hacer pull en el repositorio $repo${NC}"
                    read -p "Presiona cualquier tecla para continuar..."
                else
                    echo -e "${GREEN}Rama actualizada correctamente...${NC}"
                fi
            fi
        fi
    else
        echo -e "${YELLOW}No es un repositorio Git: $repo${NC}"
    fi

    echo -e "${BLUE}------------------------------------------------------------${NC}"

    # Volver al directorio principal
    cd ..
done

if ! $found_repo; then
    echo -e "${RED}No se encontró el repositorio: ${SPECIFIC_REPO%.} ${NC}"
fi

# Detener el agente SSH al finalizar
ssh-agent -k > /dev/null 2>&1

echo -e "${BLUE}Actualización de repositorios: ${GREEN}COMPLETA${NC}"

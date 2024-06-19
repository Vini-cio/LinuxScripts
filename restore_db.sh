#!/bin/bash

# Nos posicionamos en la carpeta vinicio
cd /home

# Variables para poder imprimir en pantalla
red='\033[1;31m'
yellow='\033[1;33m'
green='\033[1;32m'
blue='\033[1;34m'
cyan='\e[01;36m'
bold='\e[01;3m'
bold2='\e[01;39m'
NC='\033[0m'

# Variables adicionales
owner='vinicio'
dir_db='/home/vinicio/Documentos/bases_datos/'
new_db='_2'

# Texto de ayuda
help="
RESTAURAR BASE DE DATOS:
===========================================================================
Para poder restaurar una base de datos debe ingresar los siguientes argumentos:

${green}'--help'${green}            Ayuda
${blue}'-d'${NC}                Nombre de la base de datos, sino existe la crea automáticamente
${blue}'-t'${NC}                Nombre del archivo .tar
${blue}'--cron'${NC}            Comando para omitir la eliminación de CRON's

${yellow}Información adicional:${NC}

Formato del archivo de restore ${green}-->${NC} db_prueba_${blue}2024-01-01_03-00-01.tar${NC}
Restaurar base con un nombre de base de datos definido ${green}-->${NC} ${blue}-d${NC} prueba ${blue}-t${NC} prueba.tar
Restaurar base con el nombre de base de datos por defecto ${green}-->${NC} ${blue}-t${NC} prueba.tar
Restaurar base con el nombre de base de datos por defecto pero sin eliminar los CRON's ${green}-->${NC} ${blue}-t${NC} prueba.tar ${blue}--cron${NC}
"

# Muestra el texto de ayuda si se ingresa el comando --help o si no se ingresa nada
if [ "$1" == "--help" ] || [ "$1" == "" ]; then
    echo -e "$help"
    exit
fi

# Método para validar si los argumentos ingresados son válidos
function check_arguments() {
    if [[ ("$#" -ge 4 && "$1" == "-d" && "$3" == "-t") ||
        ("$#" -ge 2 && "$1" == "-t") ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Verificamos que los parámetros ingresados sean correctos
if [ "$(check_arguments "$@")" == "true" ]; then

    # Verificamos cual formato de argumentos fue ingresado
    if [ "$1" == "-d" ]; then
        db_name=$2
        tar_name=$4
    else
        tar_name=$2
        db_name=${tar_name::-13}
        db_name=$(echo $db_name | sed 's/-/_/g')
    fi

    tar_dir=$dir_db$tar_name

    # Verificar si la ruta existe
    if [ ! -f "$tar_dir" ]; then
        echo -e "LA RUTA ${blue}$tar_dir${NC} NO ES UN ARCHIVO O NO EXISTE"
        exit 1
    fi

    # Verificar si el archivo es un .tar
    if [ "${tar_name: -4}" != ".tar" ]; then
        echo -e "EL ARCHIVO ${blue}$tar_name${NC} NO ES UN ARCHIVO .tar"
        exit 1
    fi

    # Verificamos si la base de datos existe o no
    if psql -l | grep -qw "$db_name"; then
        echo -e "BASE DE DATOS ${blue}'${db_name}'${NC} ENCONTRADA"
        echo "¿Deseas eliminar la base encontrada y crear una nueva? (y/n)"
        read respuesta
        if [ "$respuesta" == "y" ]; then
            echo -e "${red}ELIMINANDO${NC} BASE DE DATOS ${blue}'${db_name}'${NC}"
            sleep 2
            res=$(psql -d "postgres" -c "DROP DATABASE $db_name" 2>&1)
            if [ $? -eq 0 ]; then
                echo -e "BASE DE DATOS ${blue}'${db_name}'${NC} HA SIDO ${red}ELIMINADA${NC}"
            else
                echo -e "${red}ERROR DE POSTGRES:${NC} $res"
                exit 1
            fi
        elif [ "$respuesta" == "n" ]; then
            echo -e "SE AGREGARÁ UN ${green}${new_db}${NC} AL NOMBRE DE LA NUEVA BASE PARA EVITAR CONFUSIONES"
            db_name=$db_name$new_db
        else
            echo "Respuesta no válida"
            exit 1
        fi
    else
        echo -e "BASE DE DATOS ${blue}'${db_name}'${NC} ${red}NO${NC} EXISTE"
    fi

    echo -e "${blue}CREANDO${NC} NUEVA BASE DE DATOS ${blue}'${db_name}'${NC}"
    sleep 2
    res=$(psql -d "postgres" -c "CREATE DATABASE $db_name OWNER $owner" 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "BASE DE DATOS ${blue}'${db_name}'${NC} HA SIDO ${green}CREADA${NC}"
    else
        echo -e "${red}ERROR DE POSTGRES:${NC} $res"
        exit 1
    fi

    echo -e "RESTAURANDO BASE DE DATOS..."
    sleep 1
    pg_restore -d "$db_name" -v "$tar_dir" >/dev/null 2>&1
    echo -e "RESTORE ${green}TERMINADO${NC}"

    echo -e "EJECUTANDO ANONIMIZACIÓN DE DATOS"
    psql -d "$db_name" -c "UPDATE res_partner SET email = email||'temp';" >/dev/null 2>&1
    psql -d "$db_name" -c "UPDATE res_users SET password = 'admin';" >/dev/null 2>&1
    echo -e "ANONIMIZACIÓN DE DATOS ${green}TERMINADO${NC}"

    echo -e "EJECUTANDO LIMPIEZA DATOS SINCRONIZACIÓN"
    psql -d "$db_name" -c "UPDATE oa_entacademic_institution SET host = '127.0.0.1', port = 8069, protocol = 'http', password = 'admin';" >/dev/null 2>&1
    psql -d "$db_name" -c "UPDATE oa_ent_user_man_cli_connection SET host = '127.0.0.1', port = 8069, protocol = 'http', password = 'admin';" >/dev/null 2>&1
    psql -d "$db_name" -c "UPDATE oa_cloud_client_connection_settings SET enabled = TRUE, oa_cloud_server_url = 'http://localhost:8080';" >/dev/null 2>&1
    psql -d "$db_name" -c "UPDATE res_company SET logo_web = NULL;" >/dev/null 2>&1

    # Verificar si se deben omitir la eliminación de correos o CRONs
    omit_email=false
    omit_cron=false
    for arg in "$@"; do
        if [ "$arg" == "--email" ]; then
            omit_email=true
        elif [ "$arg" == "--cron" ]; then
            omit_cron=true
        fi
    done

    # Ejecuta solo si en los argumentos no viene el comando "--cron"
    if [ "$omit_email" == "false" ]; then
        echo -e "Eliminando servidor de correos salientes"
        psql -d "$db_name" -c "DELETE FROM ir_mail_server;" >/dev/null 2>&1
    else
        echo -e "${red}OMITIDA${NC} eliminación servidor de correos salientes"
    fi

    # Ejecuta solo si en los argumentos no viene el comando "--cron"
    if [ "$omit_cron" == "false" ]; then
        echo -e "Eliminando acciones automatizadas ${blue}(cron)${NC}"
        psql -d "$db_name" -c "DELETE FROM ir_cron WHERE name NOT IN ('AutoVacuum osv_memory objects','Update Notification','Check Action Rules');" >/dev/null 2>&1
    else
        echo -e "${red}OMITIDA${NC} eliminación de acciones automatizadas ${blue}(cron)${NC}"
    fi

    echo -e "LIMPIEZA DATOS SINCRONIZACIÓN ${green}TERMINADO${NC}"

else
    echo -e "${red}ERROR DE ARGUMENTOS:${NC} Si necesita ayuda, escriba ${blue}'--help'${NC}"
    exit 1
fi

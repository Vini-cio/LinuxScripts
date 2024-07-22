#!/bin/bash

# Nos posicionamos en la carpeta de Descargas
cd /home/vinicio/Descargas

# Variables para poder imprimir en pantalla
red='\033[1;31m'
yellow='\033[1;33m'
green='\033[1;32m'
blue='\033[1;34m'
cyan='\e[01;36m'
bold='\e[01;3m'
bold2='\e[01;39m'
NC='\033[0m'

# Texto de ayuda
help="
	EJECUTAR TIME DOCTOR:
	===========================================================================
	Para poder ejecutar el time doctor solo debemos llamar a este script y lo ejecutara con el --no-sandbox
	
	${green}'--help'${NC} 			Ayuda
	
"

# Muestra el texto de ayuda si se ingresa el comando --help o si no se ingresa nada
if [ "$1" == "--help" ]; then
    echo -e "$help"
    exit
fi

# Ejecutar el time doctor
./timedoctor-desktop_latest_linux-x86_64.AppImage --no-sandbox
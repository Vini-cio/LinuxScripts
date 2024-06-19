#!/bin/bash

# Listado de teclas presionables
KEYS_LIST=("Caps_Lock" "Up" "Down" "Left" "Right")

# Tiempo de espera entre actividades (en segundos)
SLEEP_INTERVAL=$(shuf -i 20-50 -n 1)

# Coordenadas de la cabecera de aplicaciones
X_COORD=900
Y_COORD=40

while true; do

    # Obtener los ID's de las ventanas del TimeDoctor
    TIME_DOCTOR_IDS=$(xdotool search --all "time doctor")

    # Obtener ID de ventana activa
    ACTIVE_WINDOW_ID=$(xdotool getactivewindow)

    # Iterar sobre cada ID encontrado del TimeDoctor
    TIME_DOCTOR=false
    for id in $TIME_DOCTOR_IDS; do
        # Verificar si la ventana activa es la de TimeDoctor
        if [ "$ACTIVE_WINDOW_ID" -eq "$id" ]; then
            TIME_DOCTOR=true
            break
        fi
    done

    # Si la ventana activa es del TimeDoctor realiza el proceso de control
    if [ "$TIME_DOCTOR" = true ]; then

        echo "Detectado TimeDoctor"

        xdotool key "Shift"
        xdotool key "Ctrl"
        sleep 2
        xdotool key "Shift"
        xdotool key "Ctrl"
        sleep 2
        xdotool key "Shift"
        xdotool key "Ctrl"
        sleep 3

        echo "Minimizando ventana del TimeDoctor"

        xdotool windowminimize "$ACTIVE_WINDOW_ID"

        echo "---------"
    fi

    # Generar un número aleatorio de iteraciones
    numero_iteraciones=$(shuf -i 0-"$((${#KEYS_LIST[@]} - 1))" -n 1)

    # Iterar desde 0 hasta el número aleatorio
    for ((i = 0; i < numero_iteraciones; i++)); do
        numero_tecla=$(shuf -i 0-"$((${#KEYS_LIST[@]} - 1))" -n 1)
        tecla="${KEYS_LIST[numero_tecla]}"
        xdotool key "$tecla"
        sleep 5
    done

    # Movimiento de mouse
    xdotool mousemove "$X_COORD" "$Y_COORD"

    sleep 1

    # Click de mouse
    xdotool click 1

    xdotool keydown "Alt"

    for ((i = 0; i < numero_iteraciones; i++)); do
        xdotool key "Tab"
        sleep 2
    done

    xdotool keyup "Alt"

    # Dormir por el intervalo especificado antes de la siguiente acción
    sleep "$SLEEP_INTERVAL"
done

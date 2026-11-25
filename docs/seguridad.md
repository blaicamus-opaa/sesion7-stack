# Endurecimiento y seguridad del stack WordPress (Sesión 12)

## Tabla comparativa Antes / Después

| Comprobación (`http://localhost:8080`) | Antes del endurecimiento | Después del endurecimiento | Medida aplicada |
|---|---|---|---|
| `curl -I http://localhost:8080` (`Server` y cabeceras) | `HTTP/1.1 200 OK` · `Server: nginx/1.30.5` · sin cabeceras de seguridad | `HTTP/1.1 200 OK` · `Server: nginx` · `X-Content-Type-Options: nosniff` · `X-Frame-Options: SAMEORIGIN` | `server_tokens off;` y `add_header ... always;` en `nginx/default.conf` |
| `curl -i http://localhost:8080/xmlrpc.php` | `HTTP/1.1 405 Method Not Allowed` (`Allow: POST`) | `HTTP/1.1 403 Forbidden` | `location = /xmlrpc.php { deny all; }` |
| `curl -i http://localhost:8080/wp-config.php` | `HTTP/1.1 200 OK` | `HTTP/1.1 403 Forbidden` | `location = /wp-config.php { deny all; }` |
| `curl -i http://localhost:8080/wp-content/uploads/test.php` | `HTTP/1.1 200 OK` (ejecutaba código PHP en `uploads`) | `HTTP/1.1 403 Forbidden` (archivo eliminado tras la prueba) | `location ~* ^/wp-content/uploads/.*\.php$ { deny all; }` |
| `curl -s http://localhost:8080/wp-json/wp/v2/users` | `HTTP/1.1 200 OK` · `[]` | `HTTP/1.1 200 OK` · `[]` | Sin exposición de autores sin entradas publicadas |

## Medidas adicionales en WordPress

- **Desactivación del editor de temas/plugins:** `WORDPRESS_CONFIG_EXTRA: "define('DISALLOW_FILE_EDIT', true);"` en el servicio `wordpress` de `docker-compose.yml`.
- **Usuario con privilegios mínimos:** creado el usuario `editor_arcade` (`editor@salon.local`) con rol `editor` mediante `wordpress:cli-php8.3`.
- **Protección contra fuerza bruta:** instalado y activado el plugin `limit-login-attempts-reloaded` (`3.4.7`) mediante `wordpress:cli-php8.3`.
- **Limpieza:** eliminado `/var/www/html/wp-content/uploads/test.php` del volumen `salon-recreativo_wp_data` tras confirmar el `403 Forbidden`.

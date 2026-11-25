# Salón Recreativo Retro — WordPress con Nginx, PHP-FPM y MariaDB (RA2)

Portal web del **Salón Recreativo Retro** desplegado con Docker Compose mediante una arquitectura desacoplada en tres servicios: servidor web y proxy FastCGI (`nginx:stable`), intérprete WordPress con PHP-FPM (`wordpress:6.7-php8.3-fpm`) y base de datos relacional (`mariadb:11`).

## 1. Stack y arquitectura

| Servicio | Imagen | Función | Puerto / Red |
|---|---|---|---|
| `nginx` | `nginx:stable` | Servidor web de ficheros estáticos y proxy FastCGI hacia `wordpress:9000` | Publica `8080:80` |
| `wordpress` | `wordpress:6.7-php8.3-fpm` | Motor CMS WordPress y ejecución de PHP 8.3 | Puerto interno `9000` |
| `db` | `mariadb:11` | Base de datos MariaDB (`wp_db` y usuario `wp_user`) | Puerto interno `3306` (no publicado en host) |

- **Volúmenes persistentes:**
  - `wp_data`: compartido entre `nginx` y `wordpress` en `/var/www/html` (código de WordPress, temas, plugins y `uploads`).
  - `db_data`: montado en `/var/lib/mysql` de `db` para persistir tablas, usuarios y contenidos.

## 2. Estructura de archivos

```text
salon-recreativo/
├── .env.example              # Plantilla de variables de entorno (sin contraseñas)
├── .gitignore                # Excluye .env del control de versiones
├── docker-compose.yml        # Definición de servicios nginx, wordpress y db
├── config/
│   └── uploads.ini           # Límites PHP (upload_max_filesize=64M, post_max_size=64M, memory_limit=256M)
├── nginx/
│   └── default.conf          # Virtual host HTTP, FastCGI y reglas de endurecimiento
├── docs/
│   ├── personalizacion.md    # Tema, plugins, ajustes y estructura de contenidos
│   ├── seguridad.md          # Pruebas antes/después y medidas de seguridad aplicadas
│   └── pruebas.md            # Verificación de persistencia, latencia y recursos
└── README.md                 # Documentación del proyecto
```

## 3. Despliegue desde cero

1. Clonar el repositorio y situarse en la carpeta del proyecto (`ra2-cms`):
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd sesion7-stack/salon-recreativo
   ```
2. Crear el archivo `.env` a partir de `.env.example` y rellenar las credenciales de MariaDB y WordPress (`MARIADB_*` y `WP_DB_*`):
   ```bash
   cp .env.example .env
   ```
3. Levantar el stack completo en segundo plano:
   ```bash
   docker compose up -d
   docker compose ps
   ```
4. En MariaDB, asegurarse de que existen la base de datos `${WP_DB_NAME}` (`wp_db`) y el usuario `${WP_DB_USER}` (`wp_user`) con privilegios sobre ella.

## 4. Acceso al sitio

- **Local:** [http://localhost:8080](http://localhost:8080)
- **Proxy inverso / GitHub Codespaces:** `WORDPRESS_CONFIG_EXTRA` en `docker-compose.yml` detecta automáticamente `HTTP_X_FORWARDED_HOST` / `HTTP_HOST` y `HTTP_X_FORWARDED_PROTO` para construir `WP_HOME` y `WP_SITEURL` en `http` o `https` sin romper enlaces ni estilos.

## 5. Resumen de personalización y seguridad

- **Personalización ([docs/personalizacion.md](docs/personalizacion.md)):**
  - Idioma `es_ES`, zona horaria `Europe/Madrid`, enlaces permanentes `/%postname%/` y moderación de comentarios activada.
  - Tema **Astra** (`4.14.3`) y plugin **Contact Form 7** (`6.0.6`) integrados mediante `wordpress:cli-php8.3`.
  - Portada estática en `Inicio`, páginas `Sobre el proyecto`, `Tecnologías` (hija) y `Contacto`, menú `Menu Principal` anidado, categorías `Novedades` y `Tutoriales` con 3 entradas.
  - Límites de subida de `64M` configurados en `config/uploads.ini` y `client_max_body_size 64M;` en `nginx/default.conf`.
- **Seguridad ([docs/seguridad.md](docs/seguridad.md)):**
  - `server_tokens off;`, `X-Content-Type-Options: nosniff` y `X-Frame-Options: SAMEORIGIN` en Nginx.
  - Bloqueo `deny all;` (HTTP `403 Forbidden`) en `/xmlrpc.php`, `/wp-config.php` y ejecución PHP en `^/wp-content/uploads/.*\.php$`.
  - `DISALLOW_FILE_EDIT` activado en `WORDPRESS_CONFIG_EXTRA`.
  - Usuario dedicado con rol Editor (`editor_arcade`), plugin `limit-login-attempts-reloaded` (`3.4.7`) activo y `.env` excluido de Git mediante `.gitignore`.
- **Pruebas y rendimiento ([docs/pruebas.md](docs/pruebas.md)):**
  - Persistencia verificada tras `docker compose down` + `up -d`, respuestas HTTP `200` en ~`72–151 ms` tras calentamiento y consumo total inferior a `185 MiB` de RAM entre los tres contenedores.

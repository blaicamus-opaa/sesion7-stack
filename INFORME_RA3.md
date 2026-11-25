# Informe RA3 — Administración, roles personalizados y módulos

## 1. Infraestructura de administración añadida

- **Carpetas de trabajo en `salon-recreativo/`:** `logs/`, `datos/`, `backups/` y `scripts/`.
- **Persistencia de logs de Nginx:** montado `./logs:/var/log/nginx` en el servicio `nginx` de `docker-compose.yml` (generando `access.log` y `error.log` en el host, excluidos de Git mediante `**/logs/` en `.gitignore`).
- **Servicio `wpcli`:** añadido en `docker-compose.yml` con la imagen `wordpress:cli-php8.3`, perfil `herramientas`, usuario `"33:33"`, `working_dir: /var/www/html`, volumen compartido `wp_data:/var/www/html`, `HOME: /tmp`, variables `WORDPRESS_DB_*` y `depends_on: [db]`.
- **Script atajo `./wp`:** script ejecutable (`chmod +x`) que encapsula `docker compose run --rm wpcli wp "$@"`.

## 2. Tabla de usuarios y roles

| ID | Usuario (`user_login`) | Correo | Rol | Función en el proyecto |
|---|---|---|---|---|
| 1 | `a` | `blaicamus@gmail.com` | `administrator` | Administración técnica global del sitio y configuración del sistema |
| 3 | `editor_arcade` | `editor@salon.local` | `editor` | Edición y mantenimiento general de contenidos de WordPress |
| 4 | `coord.web` | `coord.web@salon.local` | `editor` | Coordinación editorial: revisión, edición y publicación de páginas y entradas |
| 5 | `profe.redes` | `profe.redes@salon.local` | `author` | Redacción y publicación de entradas propias de actualidad y difusión |
| 6 | `alumna.fct` | `alumna.fct@salon.local` | `contributor` | Redacción de borradores de entradas pendientes de revisión y publicación |
| 7 | `familia.garcia` | `familia.garcia@salon.local` | `subscriber` | Acceso autenticado de lectura y gestión básica de perfil |
| 8 | `revisor.fp` | `revisor.fp@salon.local` | `revisor` | Revisión, moderación de comentarios y publicación sin permiso para borrar contenidos ni alterar categorías |

## 3. Rol personalizado `revisor`

Creado clonando el rol `editor` (`wp role create revisor "Revisor" --clone=editor`) y eliminando **9 capacidades** (`manage_categories` y todas las capacidades `delete_*`: `delete_posts`, `delete_others_posts`, `delete_published_posts`, `delete_private_posts`, `delete_pages`, `delete_others_pages`, `delete_published_pages` y `delete_private_pages`).

### Capacidades activas en `revisor`

- **Edición y publicación:** `edit_posts`, `edit_others_posts`, `edit_published_posts`, `edit_private_posts`, `publish_posts`, `edit_pages`, `edit_others_pages`, `edit_published_pages`, `edit_private_pages`, `publish_pages`.
- **Lectura y moderación:** `read`, `read_private_posts`, `read_private_pages`, `moderate_comments`.
- **Medios, enlaces y marcado:** `upload_files`, `manage_links`, `unfiltered_html`.
- **Niveles heredados de compatibilidad:** `level_0` a `level_7`.

## 4. Plugins instalados y justificación

| Plugin | Versión | Estado | Justificación |
|---|---|---|---|
| `contact-form-7` | `6.0.6` | Activo | Gestiona el formulario de contacto y reservas en la página **Contacto** mediante shortcode validado. |
| `flamingo` | `2.6.4` | Activo | Almacena en la base de datos de WordPress los mensajes enviados a través de Contact Form 7 para no perder consultas aunque falle el correo saliente. |
| `cookie-law-info` | `3.5.9` | Activo | Proporciona el banner de consentimiento y aviso de cookies para cumplimiento RGPD/LSSI. |
| `simple-history` | `5.36.0` | Activo | Registra un historial de auditoría con los cambios de usuarios, publicaciones, plugins y ajustes para trazabilidad administrativa. |
| `limit-login-attempts-reloaded` | `3.4.7` | Activo | Protege `wp-login.php` y la autenticación frente a ataques de fuerza bruta limitando intentos fallidos. |

### Plugins eliminados

- `akismet` y `hello` (`Hello Dolly`) fueron desinstalados y eliminados del volumen `wp_data` por resultar innecesarios y reducir la superficie de mantenimiento y ataque.

## 5. Copias de seguridad automatizadas y simulacro de recuperación

### Funcionamiento de `scripts/backup.sh` y `scripts/restore.sh`

- **`scripts/backup.sh`:** carga las variables de `.env`, realiza el volcado de la base de datos `${WP_DB_NAME}` mediante `mariadb-dump --single-transaction` en el servicio `db` (`backups/db_YYYYMMDD_HHMMSS.sql.gz`), empaqueta `/var/www/html/wp-content` desde el volumen `wp_data` (`backups/wpcontent_YYYYMMDD_HHMMSS.tar.gz`), valida ambos archivos con `gzip -t` y aplica rotación conservando únicamente las 7 copias más recientes de cada tipo.
- **`scripts/restore.sh`:** recibe la marca temporal (`YYYYMMDD_HHMMSS`) o las rutas a ambos archivos de copia, verifica su integridad con `gzip -t`, restaura la base de datos en `db` sobre `${WP_DB_NAME}` y extrae `wp-content` en `wp_data` restableciendo la propiedad `33:33` (`www-data`).

### Salida real de `backup.sh`

```text
[1/4] Generando volcado comprimido de la base de datos (wp_db)...
[2/4] Generando copia comprimida de wp-content desde el volumen wp_data...
[3/4] Verificando integridad con gzip -t...
Integridad OK: db_20261125_190630.sql.gz y wpcontent_20261125_190630.tar.gz
[4/4] Aplicando rotación (conservando las 7 copias más recientes)...
db_20261125_190630.sql.gz      185100 bytes (181K)
wpcontent_20261125_190630.tar.gz  31510495 bytes (31M)
```

### Simulacro de desastre y recuperación (`restore.sh 20261125_190630`)

1. **Destrucción controlada con WP-CLI:**
   - `wp post delete 11 --force` -> `Success: Deleted post 11.` (*Torneo mensual de juegos retro*).
   - `wp plugin deactivate flamingo` y `wp plugin delete flamingo` -> `Deleted 'flamingo' plugin.`
   - Comprobación tras el desastre: `wp post list` solo mostraba las entradas `12` y `10`, y `wp plugin list` ya no incluía `flamingo`.
2. **Restauración con `./scripts/restore.sh 20261125_190630`:**
   ```text
   [1/3] Verificando integridad de los archivos de copia...
   [2/3] Restaurando base de datos wp_db desde db_20261125_190630.sql.gz...
   [3/3] Restaurando wp-content en wp_data desde wpcontent_20261125_190630.tar.gz con permisos 33:33...
   Restauración completada correctamente.
   ```
3. **Verificación posterior:**
   - `wp post list --post_type=post --post_status=publish` vuelve a mostrar las entradas `12`, `11` (*Torneo mensual de juegos retro*) y `10`.
   - `wp plugin list` muestra de nuevo `flamingo` en estado `active` (`2.6.4`), `/var/www/html/wp-content` mantiene `www-data:www-data` (`33:33`) y `http://localhost:8080/` responde `HTTP/1.1 200 OK`.


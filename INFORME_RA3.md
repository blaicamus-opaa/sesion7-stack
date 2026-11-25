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

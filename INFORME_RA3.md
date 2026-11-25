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

## 6. Importación y exportación (WXR, CSV, JSON y SQL)

### Exportación WXR completa (`exportaciones/sitio_20261125.xml`)

- Generada con `./wp export --stdout > exportaciones/sitio_20261125.xml` usando `-T` en `docker compose run --rm -T wpcli` para evitar retornos de carro en el XML (`57K`).
- Elementos exportados antes de la importación de ASIR:
  - `8` elementos `flamingo_contact`
  - `6` `page`
  - `4` `post`
  - `4` `nav_menu_item`
  - `1` `wp_navigation`
  - `1` `wpcf7_contact_form`
  - `1` autor, `3` categorías y `1` menú (`Menu Principal`).

### Importación WXR y CSV desde `datos/`

- Instalado y activado `wordpress-importer` (`0.9.7`) y montado `./datos:/datos:ro` en `wpcli`.
- Importado `/datos/contenidos_asir.xml` con `--authors=create`: importados 8 elementos (`#101` a `#108`: 6 entradas en `Noticias`, `Eventos` y `Prácticas`, más 2 páginas: *Horario del ciclo* y *Normas del aula técnica*).
- Importado `/datos/usuarios.csv` con `wp user import-csv`: actualizados `coord.web`, `profe.redes`, `profe.so`, `alumna.fct` y `familia.garcia`, y creados `profe.bd`, `alumno.fct` y `exalumno.2025`.

### Exportaciones CSV, JSON, API REST y SQL

- **CSV (`exportaciones/entradas.csv`, `1.1K`):** exportadas las 10 entradas mediante `wp post list --post_type=post --format=csv`.
- **JSON (`exportaciones/usuarios.json`, `1.9K`):** exportados todos los usuarios mediante `wp user list --format=json`.
- **API REST:**
  - `GET /wp-json/wp/v2/posts`: devuelve en JSON las 9 entradas publicadas (arcade + ciclo ASIR).
  - `GET /wp-json/wp/v2/users`: devuelve los autores con entradas publicadas (`coord-web`, `profe-redes`, `profe-so`).
- **Volcado SQL (`exportaciones/wp_users.sql`):** generado con `mariadb-dump --single-transaction` sobre la tabla `wp_users`. En WordPress `6.7.2` los hashes almacenados comienzan por `$P$B...` (formato PHPass; el prefijo `$wp$2y$` aplica a partir de WordPress 6.8).

### Entrada de síntesis en categoría `Prácticas`

- Publicada la entrada `116` (*Comparativa de formatos: WXR, CSV, JSON y SQL*) dentro de la categoría `Prácticas` explicando la utilidad de cada formato en 5 líneas.

## 7. Tema hijo `iaw-hijo`, `theme.json` y plantillas del Editor del Sitio

- **Creación y activación:** generado con `wp scaffold child-theme iaw-hijo --parent_theme=twentytwentyfive --theme_name="IAW Hijo" --activate` (`iaw-hijo` `0.1.0` activo, padre `twentytwentyfive` `1.0`).
- **Paleta y estilos (`temas/iaw-hijo/theme.json`, esquema versión 3):**
  - Fondo (`background`): `#F4F7FA`
  - Texto (`text`): `#21295C`
  - Enlaces (`link`): `#065A82` y `:hover`: `#1C7293`
  - Encabezados (`heading`): `#21295C`
  - Copiado en `/var/www/html/wp-content/themes/iaw-hijo/theme.json` con propietario `www-data:www-data` (`33:33`).
- **Dónde se guardan las plantillas editadas en el Editor del Sitio (Site Editor / FSE):**
  - Las plantillas base del tema residen como archivos HTML en `templates/` y `parts/` dentro de la carpeta del tema, junto a `theme.json`.
  - Cuando un administrador modifica una plantilla, parte de plantilla o estilos globales desde el **Editor del Sitio** en WordPress, las personalizaciones **no sobrescriben los archivos del tema**, sino que se guardan en la base de datos MariaDB dentro de la tabla `wp_posts` con los tipos de entrada personalizados (`post_type`):
    - `wp_template` (plantillas completas modificadas)
    - `wp_template_part` (cabeceras, pies de página y partes de plantilla)
    - `wp_global_styles` (personalizaciones de estilos globales/`theme.json`)
  - Cada registro queda vinculado al tema activo (`iaw-hijo`) mediante la taxonomía `wp_theme` en `wp_terms` / `wp_term_relationships`.

## 8. Sindicación RSS 2.0 vs Atom 1.0 y página «Noticias del sector»

- **Configuración aplicada:** `posts_per_rss = 5` y `rss_use_excerpt = 1` mediante WP-CLI.
- **Validación:** guardado `/feed/` en `feed.xml` y validado como XML bien formado (`root=rss`, `version=2.0`, `5` elementos `<item>`).
- **Página publicada:** `Noticias del sector` (ID `117`, `/noticias-del-sector/`, HTTP `200 OK`) con un bloque Gutenberg `wp:rss` apuntando a `https://wordpress.org/news/feed/` (`itemsToShow: 5`, `displayDate: true`, `displayExcerpt: true`).

### Comparativa real RSS 2.0 (`/feed/`) vs Atom 1.0 (`/feed/atom/`)

| Aspecto | RSS 2.0 (`http://localhost:8080/feed/`) | Atom 1.0 (`http://localhost:8080/feed/atom/`) |
|---|---|---|
| `Content-Type` HTTP | `application/rss+xml; charset=UTF-8` | `application/atom+xml; charset=UTF-8` |
| Elemento raíz y contenedor | `<rss version="2.0"><channel>...</channel></rss>` | `<feed xmlns="http://www.w3.org/2005/Atom">...</feed>` |
| Descripción del sitio | `<description>Cultura arcade clásica...</description>` | `<subtitle type="text">Cultura arcade clásica...</subtitle>` |
| Elemento por entrada | `<item>` con `<guid>` y `<description>` | `<entry>` con `<id>` y `<link rel="alternate" ... />` |
| Formato de fecha (RFC) | **RFC 822 / 2822:** `<pubDate>Wed, 25 Nov 2026 18:16:44 +0000</pubDate>` | **RFC 3339 (ISO 8601):** `<published>2026-11-25T18:16:44Z</published>` |
| Fecha de actualización global | `<lastBuildDate>Wed, 25 Nov 2026 18:16:44 +0000</lastBuildDate>` | `<updated>2026-11-25T18:16:44Z</updated>` |

Fragmento real de `feed.xml` (RSS 2.0):
```xml
<item>
  <title>Comparativa de formatos: WXR, CSV, JSON y SQL</title>
  <link>http://localhost:8080/comparativa-de-formatos-wxr-csv-json-y-sql/</link>
  <pubDate>Wed, 25 Nov 2026 18:16:44 +0000</pubDate>
  <guid isPermaLink="false">http://localhost:8080/comparativa-de-formatos-wxr-csv-json-y-sql/</guid>
</item>
```

Fragmento real de `/feed/atom/` (Atom 1.0):
```xml
<entry>
  <title type="html"><![CDATA[Comparativa de formatos: WXR, CSV, JSON y SQL]]></title>
  <link rel="alternate" type="text/html" href="http://localhost:8080/comparativa-de-formatos-wxr-csv-json-y-sql/" />
  <id>http://localhost:8080/comparativa-de-formatos-wxr-csv-json-y-sql/</id>
  <updated>2026-11-25T18:16:44Z</updated>
  <published>2026-11-25T18:16:44Z</published>
</entry>
```

## 9. Actualizaciones controladas por capas (Práctica 5)

### Tabla comparativa de versiones (Antes / Después)

| Componente | Versión antes | Versión después | Notas |
|---|---|---|---|
| Imagen `wordpress` | `wordpress:6.7-php8.3-fpm` | `wordpress:6.7-php8.4-fpm` | `wordpress:7.1-php8.4-fpm` no existe en Docker Hub; `6.7-php8.4-fpm` actualiza PHP manteniendo la serie 6.7 |
| Imagen `wpcli` | `wordpress:cli-php8.3` | `wordpress:cli-php8.4` | Actualizada en `docker-compose.yml` |
| Imagen `nginx` | `nginx:stable` | `nginx:stable` | Sin cambios |
| Imagen `db` | `mariadb:11` | `mariadb:11` | Sin cambios |
| PHP | `8.3.20` | `8.4.6` | Actualizado al recrear los contenedores con la imagen PHP 8.4 |
| Núcleo WordPress | `6.7.2` | `6.7.12` | Actualizado mediante `wp core update --minor` + `wp core update-db` + `wp core verify-checksums` |
| `contact-form-7` | `6.0.6` (forzada `6.0.5` en prueba) | `6.0.6` | La `6.2.6` exige WordPress `7.1`, por lo que `plugin update --all` bloqueó el salto incompatible |
| `cookie-law-info` | `3.5.9` | `3.5.9` | Última versión disponible |
| `flamingo` | `2.6.4` | `2.6.4` | Última versión disponible |
| `limit-login-attempts-reloaded` | `3.4.7` | `3.4.7` | Última versión disponible |
| `simple-history` | `5.36.0` | `5.36.0` | Última versión disponible |
| `wordpress-importer` | `0.9.7` | `0.9.7` | Última versión disponible |
| Tema activo `iaw-hijo` / padre `twentytwentyfive` | `0.1.0` / `1.0` | `0.1.0` / `1.0` | Sin cambios en temas |

### Pruebas ejecutadas en las 3 capas

- **Copia previa y rama:** ejecutado `./scripts/backup.sh` (`db_20261125_193448.sql.gz` y `wpcontent_20261125_193448.tar.gz`) y creada la rama `ra3-actualizacion`.
- **Capa 1 (Plugins):** forzada la versión `6.0.5` de `contact-form-7`; tanto `wp plugin update --all --dry-run` como `wp plugin update --all` emitieron `Warning: contact-form-7: This update requires WordPress version 7.1, but the version installed is 6.7.2.`, demostrando la protección automática frente a actualizaciones incompatibles con el núcleo; se restableció a `6.0.6`.
- **Capa 2 (PHP 8.3 → 8.4):** al cambiar `docker-compose.yml` a `wordpress:6.7-php8.4-fpm` y `wordpress:cli-php8.4` (`pull` + `up -d`), `php -v` pasó a **`8.4.6`**, mientras que `wp core version` siguió marcando **`6.7.2`**.
- **Capa 3 (Núcleo WordPress):** `wp core check-update` detectó `6.7.12` (`minor`) y `7.1.5` (`major`); `wp core update --minor` actualizó a **`6.7.12`**, `wp core update-db` confirmó la versión de esquema `58975`, y `wp core verify-checksums` verificó la integridad de los archivos (`Success: WordPress installation verifies against checksums.`). La rama `ra3-actualizacion` se fusionó por *fast-forward* en `ra3-admin`.

### ¿Por qué sube PHP a 8.4 pero el volumen conserva la versión de WordPress?

El binario e intérprete **PHP** viven en la capa inmutable de la imagen del contenedor (`wordpress:6.7-php8.4-fpm`), por lo que al hacer `pull` y `up -d` se reemplaza inmediatamente por PHP `8.4.6`. En cambio, los archivos del **núcleo de WordPress** (`/var/www/html`) residen en el volumen persistente `wp_data`. El script `docker-entrypoint.sh` de la imagen oficial de WordPress solo copia los archivos de WordPress desde `/usr/src/wordpress` cuando el directorio `/var/www/html` está vacío; como `wp_data` ya contiene una instalación existente (`6.7.2`) con su `wp-config.php` y `wp-content`, el entrypoint respeta el volumen y **no sobrescribe** WordPress. Por eso el núcleo debe actualizarse explícitamente mediante WP-CLI (`wp core update`) o el panel web.

## 10. Análisis de tráfico, GoAccess y comparativa Nginx vs Simple History

### Tráfico generado y resumen de `scripts/informe-accesos.sh`

- Generadas peticiones `GET /?p=1..30`, `GET /no-existe` (`404`) y 3 intentos de login fallidos (`POST /wp-login.php`).
- Resumen real de `logs/access.log` (`319` líneas): `277` respuestas `200`, `25` `304`, `6` `404`, `6` `302`, `4` `301` y `1` `403`.
- Generado el informe HTML interactivo con `allinurl/goaccess` en `informes/informe_accesos_20261125_193947.html` (`1,9M`, excluido de Git mediante `**/informes/`).

### Comparativa: logs de Nginx (`logs/access.log`) vs Simple History (`wp_simple_history`)

| Criterio | Logs de Nginx (`logs/access.log`) | Simple History (`wp_simple_history`) |
|---|---|---|
| **Capa registrada** | Capa HTTP / servidor web (todas las peticiones que llegan a Nginx) | Capa de aplicación WordPress (acciones internas sobre usuarios, contenidos, plugins y traducciones) |
| **Ejemplo real con 404 (`/no-existe` y `/?p=1..5`)** | Registra cada petición con IP, fecha, método, URI, código `404`, bytes y User-Agent (`curl/8.22.0`) | No registra errores `404` ni peticiones a URLs inexistentes |
| **Ejemplo real con 3 logins fallidos (`POST /wp-login.php`)** | Solo ve `POST /wp-login.php HTTP/1.1" 200 12827`; no distingue si el login fue correcto o qué usuario se probó | Registra 3 eventos `warning` (`SimpleUserLogger`, `web_user`): `Failed to login with username "{failed_username}" (username does not exist)` (`admin_falso`) |
| **Cambios administrativos (actualizaciones/WP-CLI)** | No ve operaciones internas de `wpcli` | Registra `SH_Translations_Logger` (`wp_cli`) al actualizar traducciones de plugins y temas |
| **Almacenamiento** | Archivos planos en el host (`logs/access.log` y `error.log`) | Tablas en MariaDB (`wp_simple_history` / `wp_simple_history_contexts`) |





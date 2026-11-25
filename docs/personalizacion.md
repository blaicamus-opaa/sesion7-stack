# Personalización del sitio

- **Tema activo:** Astra (versión 4.14.3)
- **Por qué lo elegí:** Es uno de los temas más ligeros, rápidos y estables del ecosistema WordPress, con compatibilidad total con PHP 8.3 y WordPress 6.7. Permite personalizar cabecera, tipografías y menús desplegables multinivel en las ubicaciones `primary` y `mobile_menu` sin sobrecargar el servidor.
- **Plugin instalado:** Contact Form 7 (`contact-form-7`, versión 6.0.6, compatible con WordPress 6.7.2)
- **Por qué lo necesito:** Permite incorporar un formulario de contacto validado mediante shortcode (`[contact-form-7 id="17" title="Contact form 1"]`) en la página de **Contacto** para gestionar reservas de eventos, consultas de restauración e inscripciones a torneos sin recurrir a formularios HTML estáticos inseguros.

## Configuración general aplicada

Mediante un contenedor temporal `wordpress:cli-php8.3` conectado a la red `salon-recreativo_default` y al volumen `salon-recreativo_wp_data`:

- **Idioma del sitio:** `es_ES` (español de España).
- **Zona horaria:** `Europe/Madrid`.
- **Enlaces permanentes:** `/%postname%/`.
- **Moderación de comentarios:** activada (`comment_moderation = 1`).
- **Portada estática:** página `Inicio` (`show_on_front = page`).
- **Límites de PHP (`config/uploads.ini`):** `upload_max_filesize = 64M`, `post_max_size = 64M` y `memory_limit = 256M`, verificados dentro del contenedor `wordpress` con `php -i` y alineados con `client_max_body_size 64M` en `nginx/default.conf`.

## Estructura de contenidos

- **Páginas:**
  - `Inicio`: Portada estática de bienvenida al Salón Recreativo Retro con resumen de cabinas originales, torneos mensuales y taller de restauración.
  - `Sobre el proyecto`: Historia, misión y filosofía de preservación del hardware arcade clásico.
  - `Tecnologías` (página hija de `Sobre el proyecto`): Detalle técnico sobre el estándar JAMMA, monitores CRT de 15 kHz, controles Sanwa/Seimitsu y preservación FPGA.
  - `Contacto`: Información de horarios y formulario interactivo integrado con Contact Form 7.
- **Categorías:**
  - `Novedades`: Actualidad del salón, nuevas máquinas y campeonatos.
  - `Tutoriales`: Guías técnicas sobre hardware y controles arcade.
- **Entradas:**
  - `Novedades`: *Inauguración de nuevas máquinas arcade*
  - `Novedades`: *Torneo mensual de juegos retro*
  - `Tutoriales`: *Cómo configurar controles arcade paso a paso*
- **Menú:**
  - `Menu Principal` asignado a `primary` y `mobile_menu`: `Inicio` > `Sobre el proyecto` (con `Tecnologías` anidada como subelemento) > `Contacto`.

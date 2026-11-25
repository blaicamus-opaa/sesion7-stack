# Pruebas de verificación, rendimiento y persistencia (Sesión 13)

## 1. URL dinámica (`WP_HOME` / `WP_SITEURL`)

Se actualizó `WORDPRESS_CONFIG_EXTRA` en `docker-compose.yml` para definir `DISALLOW_FILE_EDIT` y calcular dinámicamente `WP_HOME` y `WP_SITEURL` a partir de `HTTP_X_FORWARDED_HOST` / `HTTP_HOST` y `HTTP_X_FORWARDED_PROTO` / `HTTPS`.

```bash
curl -s -H "X-Forwarded-Host: salon-retro.app.github.dev" -H "X-Forwarded-Proto: https" http://localhost:8080/ | grep "salon-retro.app.github.dev" | head -n 3
```

Salida real:
```html
<link rel='dns-prefetch' href='//salon-retro.app.github.dev' />
<link rel="alternate" type="application/rss+xml" title="Salón Recreativo Retro &raquo; Feed" href="https://salon-retro.app.github.dev/feed/" />
<link rel="alternate" type="application/rss+xml" title="Salón Recreativo Retro &raquo; Feed de los comentarios" href="https://salon-retro.app.github.dev/comments/feed/" />
```

## 2. Prueba de persistencia (`down` sin `-v` y `up -d`)

Comandos ejecutados desde `U1`:
```bash
docker compose --project-directory sesion7-stack/salon-recreativo down
docker compose --project-directory sesion7-stack/salon-recreativo up -d
docker run --rm --user 33:33 --network salon-recreativo_default -v salon-recreativo_wp_data:/var/www/html \
  -e WORDPRESS_DB_HOST=db -e WORDPRESS_DB_NAME=wp_db -e WORDPRESS_DB_USER=wp_user -e WORDPRESS_DB_PASSWORD=wp_pass_clase \
  wordpress:cli-php8.3 wp post list --post_type=page,post --post_status=publish --fields=ID,post_type,post_title,post_parent,post_name
```

Salida real (se conservan todas las páginas y entradas):
```text
ID	post_type	post_title	post_parent	post_name
10	post	Inauguración de nuevas máquinas arcade	0	inauguracion-de-nuevas-maquinas-arcade
11	post	Torneo mensual de juegos retro	0	torneo-mensual-de-juegos-retro
12	post	Cómo configurar controles arcade paso a paso	0	como-configurar-controles-arcade-paso-a-paso
8	page	Contacto	0	contacto
9	page	Tecnologías	7	tecnologias
6	page	Inicio	0	inicio
7	page	Sobre el proyecto	0	sobre-el-proyecto
```

## 3. Comprobación de seguridad (`curl -I http://localhost:8080/xmlrpc.php`)

```bash
curl -I http://localhost:8080/xmlrpc.php
```

Salida real:
```http
HTTP/1.1 403 Forbidden
Server: nginx
Date: Wed, 25 Nov 2026 17:53:37 GMT
Content-Type: text/html
Content-Length: 146
Connection: keep-alive
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
```

## 4. Mediciones de tiempo de respuesta (5 peticiones)

Comando ejecutado 5 veces consecutivas:
```bash
curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" http://localhost:8080/
```

Resultados reales:
```text
200 0.949944s
200 0.072508s
200 0.089093s
200 0.150952s
200 0.146061s
```

La primera petición (`0.950s`) refleja el calentamiento inicial de PHP-FPM tras recrear el contenedor; las siguientes responden entre `72 ms` y `151 ms`.

## 5. Consumo de recursos (`docker stats --no-stream`)

```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" \
  salon-recreativo-nginx-1 salon-recreativo-wordpress-1 salon-recreativo-db-1
```

Salida real:
```text
NAME                           CPU %     MEM USAGE / LIMIT     MEM %     NET I/O          BLOCK I/O
salon-recreativo-nginx-1       0.00%     15.09MiB / 7.608GiB   0.19%     520kB / 521kB    8.38MB / 4.1kB
salon-recreativo-wordpress-1   0.01%     62.13MiB / 7.608GiB   0.80%     344kB / 543kB    0B / 0B
salon-recreativo-db-1          0.04%     103.6MiB / 7.608GiB   1.33%     43.9kB / 435kB   26.4MB / 32.8kB
```

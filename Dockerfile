FROM php:8.3-apache

# Extensión para conectar con MariaDB
RUN docker-php-ext-install mysqli

# Ocultar versiones (nombre "zz-" para que cargue DESPUÉS de security.conf de Debian)
RUN printf 'ServerTokens Prod\nServerSignature Off\n' > /etc/apache2/conf-available/zz-hardening.conf \
    && a2enconf zz-hardening
RUN printf 'expose_php = Off\n' > /usr/local/etc/php/conf.d/hardening.ini

COPY src/ /var/www/html/

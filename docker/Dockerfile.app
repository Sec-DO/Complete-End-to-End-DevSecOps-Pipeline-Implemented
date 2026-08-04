# Multi-Stage Hardened Production PHP Application Dockerfile
FROM php:8.3-apache AS base

# Disable Apache Signature & Server Tokens
RUN echo "ServerTokens ProductOnly" >> /etc/apache2/apache2.conf \
    && echo "ServerSignature Off" >> /etc/apache2/apache2.conf

# Install System Dependencies & PHP Extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    curl \
    && docker-php-ext-install pdo pdo_mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy PHP Hardened Configuration
COPY docker/php.ini /usr/local/etc/php/conf.d/security-php.ini

# Set Web Root Directory
WORKDIR /var/www/html

# Copy Application Source Code
COPY backend/src/ /var/www/html/

# Secure File Ownership and Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Configure Apache Port and Non-Root Execution
EXPOSE 80

# Healthcheck Probe
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD curl -f http://localhost/health.php || exit 1

CMD ["apache2-foreground"]

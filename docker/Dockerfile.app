# Stage 1: Build & Security Verification Stage
FROM php:8.3-apache AS builder

# Set Working Directory
WORKDIR /var/www/html

# Install System Dependencies & PHP PDO MySQL Extension
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpdo-pgsql \
    unzip \
    curl \
    && docker-php-ext-install pdo pdo_mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy Application Source Code
COPY backend/src/ /var/www/html/

# Stage 2: Hardened Production Runtime Stage
FROM php:8.3-apache AS production

LABEL maintainer="SecDO DevSecOps Team <devsecops@secdo.internal>"
LABEL description="Production Hardened PHP Application Container for SecDO Pipeline"
LABEL version="1.0.0"

# Install Runtime Modules & Cleanup
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && docker-php-ext-install pdo pdo_mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable Apache Mod Rewrite & Security Configuration
RUN a2enmod rewrite headers

# Copy Hardened PHP Config
COPY docker/php.ini /usr/local/etc/php/conf.d/secdo-hardened.ini

# Copy Application Source from Builder Stage
COPY --from=builder --chown=www-data:www-data /var/www/html /var/www/html

# Set Proper Permissions & Non-Root Execution Setup
RUN chmod -R 755 /var/www/html \
    && chown -R www-data:www-data /var/www/html

# Configure Built-In Container Health Check
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health.php || exit 1

# Expose HTTP Port
EXPOSE 80

# Switch to Least Privilege Unprivileged User (www-data)
USER www-data

CMD ["apache2-foreground"]

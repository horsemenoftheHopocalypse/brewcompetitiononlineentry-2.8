# Use the official PHP Apache image as the base image
FROM php:7.3-apache

# Enable Apache modules (PHP is already enabled by default in php:7.3-apache)
RUN a2enmod rewrite headers ssl

RUN apt-get update && apt-get install -y default-mysql-client curl

# Update the Apache configuration to allow .htaccess overrides
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install mysqli extension
# Install required PHP extensions
RUN apt-get update && apt-get install -y \
  libcurl4-openssl-dev \
  libonig-dev \
  libxml2-dev \
  && docker-php-ext-install mysqli curl json mbstring

# Copy application files to the web server's root directory
COPY . /var/www/html

# Copy SSL certificates
COPY server.crt /etc/ssl/certs/
COPY server.key /etc/ssl/private/

# Add SSL to the existing default site (which already has PHP working)
RUN sed -i 's/<VirtualHost \*:80>/<VirtualHost *:80 *:443>/' /etc/apache2/sites-available/000-default.conf && \
  sed -i '/<VirtualHost/a \\tSSLEngine on\n\tSSLCertificateFile /etc/ssl/certs/server.crt\n\tSSLCertificateKeyFile /etc/ssl/private/server.key' /etc/apache2/sites-available/000-default.conf

# Expose both HTTP and HTTPS ports
EXPOSE 80 443

# Use the default production configuration for PHP runtime arguments
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Don't duplicate mysqli extension loading (it's already in php.ini-production)
# RUN echo "extension=mysqli" >> "$PHP_INI_DIR/php.ini"


# Set the entry point to start Apache in the foreground
ENTRYPOINT ["apache2-foreground"]
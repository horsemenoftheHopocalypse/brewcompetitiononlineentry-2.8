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

# Ensure Apache listens on both ports 80 and 443
RUN echo 'Listen 80\n\
  <IfModule ssl_module>\n\
  Listen 443\n\
  </IfModule>\n\
  <IfModule mod_gnutls.c>\n\
  Listen 443\n\
  </IfModule>' > /etc/apache2/ports.conf

# Replace default HTTP VirtualHost (remove SSL from port 80)
RUN echo '<VirtualHost *:80>\n\
  ServerAdmin webmaster@localhost\n\
  DocumentRoot /var/www/html\n\
  # Trust X-Forwarded-Proto header from CloudFlare/proxies\n\
  SetEnvIf X-Forwarded-Proto "https" HTTPS=on\n\
  ErrorLog ${APACHE_LOG_DIR}/error.log\n\
  CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
  </VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Create separate HTTPS VirtualHost for port 443
RUN echo '<VirtualHost *:443>\n\
  SSLEngine on\n\
  SSLCertificateFile /etc/ssl/certs/server.crt\n\
  SSLCertificateKeyFile /etc/ssl/private/server.key\n\
  ServerAdmin webmaster@localhost\n\
  DocumentRoot /var/www/html\n\
  ErrorLog ${APACHE_LOG_DIR}/error.log\n\
  CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
  </VirtualHost>' > /etc/apache2/sites-available/default-ssl.conf && a2ensite default-ssl.conf

# Expose both HTTP and HTTPS ports
EXPOSE 80 443

# Use the default production configuration for PHP runtime arguments
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Don't duplicate mysqli extension loading (it's already in php.ini-production)
# RUN echo "extension=mysqli" >> "$PHP_INI_DIR/php.ini"


# Set the entry point to start Apache in the foreground
ENTRYPOINT ["apache2-foreground"]
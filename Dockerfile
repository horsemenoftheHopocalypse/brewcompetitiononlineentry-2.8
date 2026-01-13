# Use the official PHP Apache image as the base image
FROM php:7.3-apache

# Enable mod_rewrite
RUN a2enmod rewrite headers ssl

RUN apt-get update && apt-get install -y default-mysql-client

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

# Configure Apache to use SSL
RUN echo "\
  <VirtualHost *:443>\n\
  DocumentRoot /var/www/html\n\
  SSLEngine on\n\
  SSLCertificateFile /etc/ssl/certs/server.crt\n\
  SSLCertificateKeyFile /etc/ssl/private/server.key\n\
  </VirtualHost>\n" > /etc/apache2/sites-available/default-ssl.conf

# Enable the default SSL site
RUN a2ensite default-ssl

# Expose both HTTP and HTTPS ports
EXPOSE 80 443

# Use the default production configuration for PHP runtime arguments
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Enable mysqli extension in php.ini
RUN echo "extension=mysqli" >> "$PHP_INI_DIR/php.ini"


# Set the entry point to start Apache in the foreground
ENTRYPOINT ["apache2-foreground"]
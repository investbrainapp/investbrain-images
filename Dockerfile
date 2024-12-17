FROM php:8.3-fpm

ENV DEBIAN_FRONTEND noninteractive

# Install common php extension dependencies
RUN apt-get update && apt-get install -y \
    libfreetype-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    zlib1g-dev \
    libzip-dev \
    unzip \
    libicu-dev \
    git \
    curl \
    supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
            gd \
            zip \
            pdo_mysql \
            mysqli \
            intl

# Set the working directory
COPY . /var/www/app
WORKDIR /var/www/app

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Copy over supervisor configuration
COPY ./docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set permissions
RUN chown -R www-data:www-data . \ 
    && chmod -R 775 ./storage \
    && chmod +x ./docker/entrypoint.sh 

# Install composer
COPY --from=composer:2.6.5 /usr/bin/composer /usr/local/bin/composer

# Serve on port 80
EXPOSE 80

# Set up healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost || exit 1

# Run everything else
ENTRYPOINT ["/bin/bash", "./docker/entrypoint.sh"]
CMD ["./docker/entrypoint.sh"]

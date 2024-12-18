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

RUN curl -s "https://api.github.com/repos/investbrainapp/investbrain/releases/latest" | \
        grep -o '"tarball_url": "[^"]*"' | \
        cut -d '"' -f 4 | \
        xargs curl -sL | \
        tar --strip-components=1 -xz -C . \
        && chown -R www-data:www-data . \ 
        && chmod +x ./docker/entrypoint.sh \
        && find . -type f -exec chmod 644 {} \; \
        && find . -type d -exec chmod 755 {} \; 

# Install composer
COPY --from=composer:2.6.5 /usr/bin/composer /usr/local/bin/composer

# Serve on port 80
EXPOSE 80

# Set up healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost || exit 1

# Run everything else
ENTRYPOINT ["/bin/bash", "./docker/entrypoint.sh"]
CMD ["./docker/entrypoint.sh"]

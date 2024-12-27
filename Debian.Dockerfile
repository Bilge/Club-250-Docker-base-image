# https://hub.docker.com/_/php/tags
FROM php:8.4.2-fpm

RUN apt-get update && \
    apt-get --assume-yes install libicu-dev libxslt1.1 libxslt1-dev libffi-dev libpq5 libpq-dev libgmp-dev unzip \
    && docker-php-ext-install opcache \
        # Number formatting in our own application templates requires intl.
        intl \
        # symfony/messenger requires PCNTL for graceful shutdown of queue workers.
        pcntl \
        # Pheanstalk requires sockets extension otherwise it throws SocketException with "Unknown error" (CLUB-250-B6).
        sockets \
        # lorenzo/pinky requires XSL extension.
        xsl \
        # amphp/hpack can benefit from FFI extension.
        ffi \
        # amphp/postgres requires either pecl-pq or ext-pgsql.
        pgsql \
        # Phinx requires pdo_pgsql extension.
        pdo_pgsql \
        # xpaw/steamid requires GMP extension.
        gmp \
    # All dev packages can be removed post-compile, however the main packages cannot.
    && apt-get --assume-yes purge libicu-dev libxslt1-dev libffi-dev libpq-dev libgmp-dev \
    && apt-get --assume-yes autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install Composer.
RUN curl https://raw.githubusercontent.com/composer/getcomposer.org/main/web/installer |\
    php -- --install-dir /usr/local/bin --filename composer

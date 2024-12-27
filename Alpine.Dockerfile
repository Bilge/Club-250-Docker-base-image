# https://hub.docker.com/_/php/tags?name=-fpm-alpine
FROM php:8.4.2-fpm-alpine AS prod

RUN \
	apk add icu icu-dev jemalloc libxslt libxslt-dev libffi libffi-dev libpq libpq-dev gmp gmp-dev \
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
	&& apk del icu-dev libxslt-dev libffi-dev libpq-dev gmp-dev

# Replace the slow musl allocator.
ENV LD_PRELOAD=libjemalloc.so.2

RUN \
	# Validate jemalloc preloaded.
	ldd `which php` | grep libjemalloc.so.2 && \
	# Install Composer.
	wget https://raw.githubusercontent.com/composer/getcomposer.org/main/web/installer -qO- |\
		php -- --install-dir /usr/local/bin --filename composer

FROM prod AS dev

RUN \
	apk add autoconf gcc libc-dev linux-headers make \
	&& pecl install xdebug \
	&& docker-php-ext-enable xdebug \
	&& apk del autoconf gcc libc-dev linux-headers make

RUN <<-'.'
	>>/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini echo -n '
		xdebug.mode=develop,debug,trace
		xdebug.client_host=host.docker.internal
		xdebug.trace_output_name=trace.%t.%R
		xdebug.log=/tmp/xdebug.log
	'
.

FROM mediawiki:1.45

COPY LocalSettings.php /var/www/html/LocalSettings.php
COPY init.sh /init.sh
RUN chmod +x /init.sh
COPY setup_database.php /tmp/setup_database.php
COPY disable-web-error-output.ini /usr/local/etc/php/conf.d/zz-disable-web-error-output.ini

COPY assets/favicon.ico /var/www/html/resources/assets/favicon.ico

ENTRYPOINT ["/init.sh"]
CMD ["apache2-foreground"]

FROM mediawiki:1.45

COPY LocalSettings.php /var/www/html/LocalSettings.php
COPY init.sh /init.sh
RUN chmod +x /init.sh
COPY setup_database.php /tmp/setup_database.php

ENTRYPOINT ["/init.sh"]
CMD ["apache2-foreground"]

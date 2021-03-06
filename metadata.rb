name             'magento'
maintainer       'Ivan Chepurnyi'
maintainer_email 'ivan.chepurnyi@ecomdev.org'
license          'GPLv3'
description      'Installs/Configures server software for Magento app'
long_description 'Installs/Configures server software for Magento app'
version          '0.1.20'

depends 'vhost'
depends 'php_fpm'
depends 'mysql', '=5.6.1'
depends 'database', '=3.1.0'
depends 'logrotate'
depends 'ecomdev_common'
depends 'redisio', '1.7.1'
depends 'openssl'
depends 'composer'
depends 'n98-magerun'

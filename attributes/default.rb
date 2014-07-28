namespace 'magento', 'default' do
  namespace 'database' do
    encoding 'utf8'
    user :database_name
    password :database_name
    host '%'
    namespace 'connection_settings' do
      host 'localhost'
      user 'root'
    end
  end

  namespace 'user' do
    uid :system_default
    gid :system_default
  end

  namespace 'application' do
    user :system_default
    group :system_default
    uid :system_default

    status_path '/status'
    status_ips Array.new
    handler 'index.php'
    time_limit '60'
    memory_limit '256M'
    php_extensions Hash.new
    cache_static '30d'
    http_port '80'
    https_port '443'
    log_dir 'var/log'
    vhost 'nginx'
    deny_paths %w(/app/ /includes/ /lib/ /media/downloadable/ /pkginfo/ /report/config.xml /var/)
    domain_map Hash.new
    database_options Hash.new

    namespace 'php_fpm_options' do
      socket true
      socket_user :system_default # Taken from nginx
      socket_group :system_default # Taken from nginx
      request_terminate_timeout :system_default # Taken from time limit

      namespace 'php_admin_flag' do
        log_errors 'on'
        display_errors 'off'
        display_startup_errors 'off'
      end

      namespace 'php_admin_value' do
        error_log :system_default
        error_reporting 'E_ALL'
        memory_limit :system_default
        max_execution_time :system_default
      end
    end
  end
end
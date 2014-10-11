
# Support whyrun
def whyrun_supported?
  true
end


action :create do
  run_context.include_recipe('magento::default')

  options = resource_options

  if options[:vhost] == 'nginx'
    run_context.include_recipe('vhost::nginx')
  end

  resource = []

  resource <<= magento_user options[:user] do
    uid options[:uid] unless options[:uid].nil?
    gid options[:gid] unless options[:gid].nil?
  end

  resource <<= php_fpm_pool options[:name] do
    options[:php_fpm_options].each_pair do |key, value|
      send(key, value)
    end
  end

  resource <<= directory options[:directory] do
    user options[:user]
    group options[:group]
    recursive true
    not_if { ::File.exists?(options[:directory]) }
  end

  resource <<= directory options[:log_dir] do
    user options[:user]
    group options[:group]
    recursive true
    not_if { ::File.exists?(options[:log_dir]) }
  end

  host_run_code = {}
  host_run_type = {}
  options[:domain_map].each_pair do |key, value|
    if value.is_a?(String)
      host_run_code[key.to_s] = value
    elsif value.is_a?(Hash) && value.key?(:store)
      host_run_code[key.to_s] = value[:store]
    elsif value.is_a?(Hash) && value.key?(:website)
      host_run_type[key.to_s] = 'website'
      host_run_code[key.to_s] = value[:website]
    end
  end

  if options[:vhost] == 'nginx'
    resource <<= create_vhost_nginx(options, host_run_code, host_run_type)
  end

  options[:php_extensions].each_pair  do |ext, ext_data|
    resource <<= php_pear ext.to_s do
      if ext_data.is_a?(Hash)
        ini_options = {}
        ext_data.each_pair do |key, value|
          if respond_to?(key.to_sym)
            send(key.to_sym, value)
          else
            ini_options[key.to_s] = value
          end
        end
        unless ini_options.empty?
          directives(ini_options)
        end
      end
    end
  end

  resource <<= magento_database options[:database_options][:name] do
    options[:database_options].each_pair do |key, value|
      if respond_to?(key)
        send(key, value)
      end
    end
  end

  logrotate_app 'magento-' + options[:name] do
    path      ::File.join(options[:log_dir], '*.log')
    frequency 'daily'
    rotate    8
    create    "644 #{options[:user]} #{options[:group]}"
  end

  if options[:composer]
    run_context.include_recipe 'composer::default'

    resource <<= composer_project options[:directory] do
      user options[:user]
      group options[:group]
      action :install
    end
  end

  new_resource.update_from_resources(resource)
end

action :delete do
  run_context.include_recipe('magento::default')
  Chef::Log.info('No resource deletion possibilities for now')
end

private

def create_vhost_nginx(options, host_run_code, host_run_type)
  vhost_nginx options[:main_domain] do
    action [:create, :enable]
    listen options[:http_port]
    if options[:ssl].is_a?(Hash)
      listen options[:https_port], %w(ssl)
      ssl options[:ssl]
    end
    document_root options[:directory]
    upstream("#{options[:name]}_fpm", [fpm: options[:name]])
    http_map("#{options[:name]}_mage_run_code", 'http_host', host_run_code, '')
    http_map("#{options[:name]}_mage_run_type", 'http_host', host_run_type, 'store')
    custom_directive(
        set: {
            '$my_ssl' => '""',
            '$my_port' => '"80"'
        }
    )
    custom_directive(
        if: '$http_x_forwarded_proto ~ "https"',
        op: {
            set: {
                '$my_ssl' => '"on"',
                '$my_port' => '"443"'
            }
        }
    )
    unless options[:status_path] == ''
      location(options[:status_path], [
          access_log: 'off',
          allow: ['127.0.0.1'].push(options[:status_ips]).flatten,
          deny: 'all',
          include: 'fastcgi_params',
          fastcgi_param: 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
          fastcgi_pass: "#{options[:name]}_fpm"
      ])
    end
    location('~ /\.',
             deny: 'all',
             access_log: 'off',
             log_not_found: 'off')
    options[:deny_paths].each do |path|
      location('^~ ' + path, 'deny all')
    end

    options[:custom_locations].each_pair do |name, value|
      location(name, value)
    end

    location('/',
             index: "index.html #{options[:handler]}",
             try_files: '$uri $uri/ @magento',
             expires: options[:cache_static])
    location('/',
             index: "index.html #{options[:handler]}",
             try_files: '$uri $uri/ @magento',
             expires: options[:cache_static])
    location('@magento', rewrite: "/ /#{options[:handler]}")
    location('~ ^.+\.php(/|$)',
             expires: 'off',
             fastcgi_split_path_info: '^((?U).+\.php)(/?.+)$',
             try_files: '$fastcgi_script_name =404',
             include: 'fastcgi_params',
             fastcgi_param: {
                 SCRIPT_FILENAME: '$document_root$fastcgi_script_name',
                 PATH_INFO: '$fastcgi_path_info',
                 PATH_TRANSLATED: '$document_root$fastcgi_path_info',
                 MAGE_RUN_CODE: "$#{options[:name]}_mage_run_code",
                 MAGE_RUN_TYPE: "$#{options[:name]}_mage_run_type",
                 SERVER_PORT: '$my_port',
                 HTTPS: '$my_ssl'
             },
             fastcgi_pass: "#{options[:name]}_fpm",
             fastcgi_read_timeout: options[:time_limit] + 's',
             fastcgi_index: options[:handler],
             fastcgi_buffers: options[:buffers],
             fastcgi_buffer_size: options[:buffer_size])
  end
end

def transform_keys!(hash, &block)
  if hash.is_a?(Hash)
    hash.keys.each do |key|
      new_key = block.call(key)
      hash[new_key] = hash.delete(key)
      transform_keys!(hash[new_key], &block)
    end
  elsif hash.is_a?(Array)
    hash.each { |v| transform_keys!(v, &block) }
  end
end

def resource_options
  options = new_resource.dump_attribute_values(node[:magento][:default][:application], :magento_default)
  transform_keys!(options) { |v| v.to_sym }

  if options[:user] == :system_default
    options[:user] = options[:name]
  end

  if options[:group] == :system_default
    options[:gid] = nil
    if options[:vhost] == 'nginx'
      options[:group] = node[:nginx][:group]
      options[:gid] = node[:nginx][:group]
    else
      options[:group] = options[:user]
    end
  else
    options[:gid] = options[:group]
  end

  options[:log_dir] = ::File.expand_path(options[:log_dir], options[:directory])

  if options[:php_fpm_options].is_a?(Hash)
    specify_php_fpm_options(options)
  end

  if options[:database_options][:name].nil?
    options[:database_options][:name] = options[:name]
  end

  options
end

def specify_php_fpm_options(options)
  if options[:php_fpm_options][:socket_user] == :system_default
    options[:php_fpm_options][:socket_user] = nil
  end

  if options[:php_fpm_options][:socket_group] == :system_default
    options[:php_fpm_options][:socket_group] = nil
  end

  if options[:vhost] == 'nginx'
    if options[:php_fpm_options][:socket_user] == nil
      options[:php_fpm_options][:socket_user] = node[:nginx][:user]
    end
    if options[:php_fpm_options][:socket_group] == nil
      options[:php_fpm_options][:socket_group] = node[:nginx][:group]
    end
  end

  options[:php_fpm_options][:user] = options[:user]
  options[:php_fpm_options][:group] = options[:group]

  if options[:php_fpm_options][:php_admin_value][:error_log] == :system_default
    options[:php_fpm_options][:php_admin_value][:error_log] = ::File.join(options[:log_dir], 'fpm-error.log')
  end

  if options[:php_fpm_options][:request_terminate_timeout] == :system_default
    options[:php_fpm_options][:request_terminate_timeout] = options[:time_limit] + 's'
  end

  if options[:php_fpm_options][:php_admin_value][:memory_limit] == :system_default
    options[:php_fpm_options][:php_admin_value][:memory_limit] = options[:memory_limit]
  end

  if options[:php_fpm_options][:php_admin_value][:max_execution_time] == :system_default
    options[:php_fpm_options][:php_admin_value][:max_execution_time] = options[:time_limit]
  end
end
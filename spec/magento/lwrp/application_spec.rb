require 'spec_helper'

describe 'magento_test::application' do

  before (:each) { allow_recipe('magento::default', 'vhost::nginx', 'php_fpm::default', 'php_fpm::fpm') }

  let(:chef_run) do
    chef_run_proxy.instance(step_into: 'magento_application') do |node|
      node.set[:test][:name] = 'test'
      node.set[:test][:directory] = '/var/www/test.magento.com'
      node.set[:test][:main_domain] = 'test.dev'
    end.converge(described_recipe)
  end

  let (:node) { chef_run.node }

  it 'should create a magento application named test' do
    expect(chef_run).to create_magento_application('test')
  end

  it 'should include magento::default recipe' do
    expect(chef_run).to include_recipe('magento::default')
  end

  it 'should include vhost::nginx recipe' do
    expect(chef_run).to include_recipe('vhost::nginx')
  end

  it 'should not include vhost::nginx recipe if not specified' do
    test_params do |params|
      params[:vhost] = 'apache'
    end

    expect(chef_run).not_to include_recipe('vhost::nginx')
  end

  it 'should create a system user for application' do
    expect(chef_run).to create_magento_user('test')
  end

  it 'should create a magento database' do
    expect(chef_run).to create_magento_database('test')
  end

  it 'should pass connection_settings to magento database creation' do
    test_params do |params|
      params[:database_options] = {
          connection_settings: {
              host: '192.168.0.1',
              user: 'root',
              password: 'password'
          }
      }
    end
    expect(chef_run).to create_magento_database('test').with(connection_settings: {
        host: '192.168.0.1',
        user: 'root',
        password: 'password'
    })
  end

  it 'should custom database name' do
    test_params do |params|
      params[:database_options] = {
          name: 'magento_test'
      }
    end
    expect(chef_run).to create_magento_database('magento_test')
  end

  it 'should create a system user with params' do
    test_params do |params|
      params[:user] = 'test-two'
      params[:group] = 'test-two'
      params[:uid] = 501
    end

    expect(chef_run).to create_magento_user('test-two').with(
        uid: 501,
        gid: 'test-two'
    )
  end

  it 'should create a php-fpm pool for user' do
    expect(chef_run).to create_php_fpm_pool('test').with(
                            socket: true,
                            socket_user: node[:nginx][:user],
                            socket_group: node[:nginx][:group],
                            user: 'test',
                            group: node[:nginx][:group]
                         )
  end

  it 'should create a directory for a document root' do
    expect(chef_run).to create_directory('/var/www/test.magento.com').with(
                             user: 'test',
                             group: node[:nginx][:group]
                         )
  end

  it 'should not create a directory for a document root if directory is already exists' do
    stub_file_exists('/var/www/test.magento.com')
    expect(chef_run).not_to create_directory('/var/www/test.magento.com')
  end


  it 'should create a directory for a magento logging ' do
    expect(chef_run).to create_directory('/var/www/test.magento.com/var/log').with(
                            user: 'test',
                            group: node[:nginx][:group]
                        )
  end


  it 'should not create a directory for a magento logging if it is already exists' do
    stub_file_exists('/var/www/test.magento.com/var/log')
    expect(chef_run).not_to create_directory('/var/www/test.magento.com/var/log')
  end

  it 'should create a php-fpm pool for user' do
    expect(chef_run).to create_php_fpm_pool('test').with(
       socket: true,
       socket_user: node[:nginx][:user],
       socket_group: node[:nginx][:group],
       user: 'test',
       group: node[:nginx][:group],
       request_terminate_timeout: node[:magento][:default][:application][:time_limit] + 's',
       php_admin_flag: {
           log_errors: 'on',
           display_errors: 'off',
           display_startup_errors: 'off'
       },
       php_admin_value: {
           error_log: '/var/www/test.magento.com/var/log/fpm-error.log',
           error_reporting: 'E_ALL',
           memory_limit: node[:magento][:default][:application][:memory_limit],
           max_execution_time: node[:magento][:default][:application][:time_limit]
       }
     )
  end

  it 'should create a custom user' do
    test_params do |params|
      params[:user] = 'www-user'
      params[:group] = 'www-group'
    end

    expect(chef_run).to create_magento_user('www-user').with(
                            gid: 'www-group'
                        )
  end

  it 'should create a php-fpm pool with a custom user' do
    test_params do |params|
      params[:user] = 'www-user'
      params[:group] = 'www-group'
    end

    expect(chef_run).to create_php_fpm_pool('test').with(
      user: 'www-user',
      group: 'www-group'
    )
  end

  it 'should create a vhost for an application' do
    test_params do |params|
      params[:status_ips] = ['192.168.0.0/16', '33.33.33.0/24']
      params[:deny_paths] = ['/app/', '/lib/']
    end

    expect(chef_run).to create_vhost_nginx('test.dev').with(
       listens: [
           {listen: '80', params: []}
       ],
       document_root: '/var/www/test.magento.com',
       upstreams: {
          'test_fpm' => {
             servers: [
                 {fpm: 'test'}
             ],
             custom: {}
          }
       },
       http_maps: {
          'test_mage_run_code' => {
            source: 'http_host',
            maps: {},
            default: '',
            hostnames: true
          },
          'test_mage_run_type' => {
            source: 'http_host',
            maps: {},
            default: 'store',
            hostnames: true
          }
       },
       custom_directives: [
          'set $my_ssl "";',
          'set $my_port "80";',
          'if ($http_x_forwarded_proto ~ "https") { ',
          '    set $my_ssl "on";',
          '    set $my_port "443";',
          '}'
       ],
       locations: {
          node[:magento][:default][:application][:status_path] => [
             'access_log off;',
             'allow 127.0.0.1;',
             'allow 192.168.0.0/16;',
             'allow 33.33.33.0/24;',
             'deny all;',
             'include fastcgi_params;',
             'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;',
             'fastcgi_pass test_fpm;',
          ],
          '~ /\.'  => [
             'deny all;',
             'access_log off;',
             'log_not_found off;'
          ],
          '^~ /app/' => ['deny all;'],
          '^~ /lib/' => ['deny all;'],
          '/' => [
           'index index.html ' + node[:magento][:default][:application][:handler] + ';',
           'try_files $uri $uri/ @magento;',
           'expires ' + node[:magento][:default][:application][:cache_static] + ';'
          ],
          '@magento' => [
             'rewrite / /' + node[:magento][:default][:application][:handler] + ';'
          ],
          '~ ^.+\.php(/|$)' => [
             'expires off;',
             'fastcgi_split_path_info ^((?U).+\.php)(/?.+)$;',
             'try_files $fastcgi_script_name =404;',
             'include fastcgi_params;',
             'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;',
             'fastcgi_param PATH_INFO $fastcgi_path_info;',
             'fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;',
             'fastcgi_param MAGE_RUN_CODE $test_mage_run_code;',
             'fastcgi_param MAGE_RUN_TYPE $test_mage_run_type;',
             'fastcgi_param SERVER_PORT $my_port;',
             'fastcgi_param HTTPS $my_ssl;',
             'fastcgi_pass test_fpm;',
             'fastcgi_read_timeout ' + node[:magento][:default][:application][:time_limit] + 's;',
             'fastcgi_index ' + node[:magento][:default][:application][:handler] + ';',
             'fastcgi_buffers ' + node[:magento][:default][:application][:buffers] + ';',
             'fastcgi_buffer_size ' + node[:magento][:default][:application][:buffer_size] + ';'
          ]
        }
      )
  end

  it 'should automatically add SSL options to nginx configuration' do
    test_params do |params|
      params[:ssl] = {
          :public => 'a public key',
          :private => 'a private key'
      }
    end

    expect(chef_run).to create_vhost_nginx('test.dev').with(
      listens: [
        {listen: '80', params: []},
        {listen: '443', params: ['ssl']}
      ],
      ssl: {
          public: 'a public key',
          private: 'a private key'
      }
    )
  end

  it 'allows to specify custom https and http ports' do
    test_params do |params|
      params[:http_port] = '8080'
      params[:https_port] = '4434'
      params[:ssl] = {
          :public => 'a public key',
          :private => 'a private key'
      }
    end

    expect(chef_run).to create_vhost_nginx('test.dev').with(
                            listens: [
                                {listen: '8080', params: []},
                                {listen: '4434', params: ['ssl']}
                            ],
                            ssl: {
                                public: 'a public key',
                                private: 'a private key'
                            }
                        )
  end

  it 'creates hostmaps based on attributes' do
    test_params do |params|
      params[:domain_map] = {
          'my.test.dev' => 'my',
          'my2.test.dev' => {store: 'my2'},
          'my3.test.dev' => {website: 'my3'}
      }
    end

    expect(chef_run).to create_vhost_nginx('test.dev').with(
                            http_maps: {
                                'test_mage_run_code' => {
                                    source: 'http_host',
                                    maps: {
                                        'my.test.dev' => 'my',
                                        'my2.test.dev' => 'my2',
                                        'my3.test.dev' => 'my3'
                                    },
                                    default: '',
                                    hostnames: true
                                },
                                'test_mage_run_type' => {
                                    source: 'http_host',
                                    maps: {
                                        'my3.test.dev' => 'website'
                                    },
                                    default: 'store',
                                    hostnames: true
                                }
                            },
                        )
  end

  it 'installs additional php_packages' do
    test_params do |params|
      params[:php_extensions] = {
          curl: true,
          xdebug: {
            preferred_state: 'beta',
            zend_extensions: ['xdebug.so']
          },
          intl: {
            preferred_state: 'beta',
            'php.ini_value' => 1
          }
      }
    end

    expect(chef_run).to install_php_pear('curl')
    expect(chef_run).to install_php_pear('xdebug').with(
                            preferred_state: 'beta',
                            zend_extensions: ['xdebug.so']
                        )
    expect(chef_run).to install_php_pear('intl').with(
                            preferred_state: 'beta',
                            directives: {
                                'php.ini_value' => 1
                            }
                        )
  end

  it 'allows adding custom locations' do
    test_params do |params|
      params[:status_ips] = ['192.168.0.0/16', '33.33.33.0/24']
      params[:deny_paths] = ['/app/', '/lib/']
      params[:custom_locations] = {
          '/en-us/' => {
              rewrite: '^/([a-z-]+)/.*+$ /$1/index.php?$args'
          }
      }
    end

    expect(chef_run).to create_vhost_nginx('test.dev').with(
                            locations: {
                                node[:magento][:default][:application][:status_path] => [
                                    'access_log off;',
                                    'allow 127.0.0.1;',
                                    'allow 192.168.0.0/16;',
                                    'allow 33.33.33.0/24;',
                                    'deny all;',
                                    'include fastcgi_params;',
                                    'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;',
                                    'fastcgi_pass test_fpm;',
                                ],
                                '~ /\.'  => [
                                    'deny all;',
                                    'access_log off;',
                                    'log_not_found off;'
                                ],
                                '^~ /app/' => ['deny all;'],
                                '^~ /lib/' => ['deny all;'],
                                '/en-us/' => ['rewrite ^/([a-z-]+)/.*+$ /$1/index.php?$args;'],
                                '/' => [
                                    'index index.html ' + node[:magento][:default][:application][:handler] + ';',
                                    'try_files $uri $uri/ @magento;',
                                    'expires ' + node[:magento][:default][:application][:cache_static] + ';'
                                ],
                                '@magento' => [
                                    'rewrite / /' + node[:magento][:default][:application][:handler] + ';'
                                ],
                                '~ ^.+\.php(/|$)' => [
                                    'expires off;',
                                    'fastcgi_split_path_info ^((?U).+\.php)(/?.+)$;',
                                    'try_files $fastcgi_script_name =404;',
                                    'include fastcgi_params;',
                                    'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;',
                                    'fastcgi_param PATH_INFO $fastcgi_path_info;',
                                    'fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;',
                                    'fastcgi_param MAGE_RUN_CODE $test_mage_run_code;',
                                    'fastcgi_param MAGE_RUN_TYPE $test_mage_run_type;',
                                    'fastcgi_param SERVER_PORT $my_port;',
                                    'fastcgi_param HTTPS $my_ssl;',
                                    'fastcgi_pass test_fpm;',
                                    'fastcgi_read_timeout ' + node[:magento][:default][:application][:time_limit] + 's;',
                                    'fastcgi_index ' + node[:magento][:default][:application][:handler] + ';',
                                    'fastcgi_buffers ' + node[:magento][:default][:application][:buffers] + ';',
                                    'fastcgi_buffer_size ' + node[:magento][:default][:application][:buffer_size] + ';'
                                ]
                            }
                        )
  end

  it 'installs composer and composer package in project directory if composer flag is set to true' do
    test_params do |params|
      params[:composer] = true
    end

    expect(chef_run).to include_recipe('composer::default')

    expect(chef_run).to install_composer_project('/var/www/test.magento.com')
                        .with(
                            user: 'test',
                            group: 'www-data',
                            dev: true,
                            quiet: false
                        )
  end

  it 'does not install composer if no flag is specified' do
    expect(chef_run).not_to include_recipe('composer::default')
    expect(chef_run).not_to install_composer_project('/var/www/test.magento.com')
  end

end
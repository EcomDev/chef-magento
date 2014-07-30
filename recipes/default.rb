include_recipe 'openssl::upgrade'

if node.recipe?('mysql::server')
  node.default[:magento][:default][:database][:connection_settings][:password] = node[:mysql][:server_root_password]
  node.default[:magento][:default][:database][:connection_settings][:port] = node[:mysql][:port].to_i
end
include_recipe 'magento::default'

directory node[:varnish][:config_dir] do
  action :create
  user 'root'
  group 'root'
end

remote_file ::File.join(node[:varnish][:config_dir], 'devicedetect.vcl') do
  source node[:magento][:varnish][:device_detect_file]

  notifies(:reload, {:service => 'varnish'}, :delayed)
  notifies(:reload, {:service => 'varnishlog'}, :delayed)
end

node.default[:varnish][:VARNISH_VCL_CONF] = ::File.join(node[:varnish][:config_dir], 'magento.vcl')
node.default[:varnish][:VARNISH_LISTEN_PORT] = node[:magento][:varnish][:port]

varnish_secret = secure_password

file node[:varnish][:VARNISH_SECRET_FILE] do
  content varnish_secret
  not_if { ::File.exists?(node[:varnish][:VARNISH_SECRET_FILE]) }
end

variables = Mash.new node[:magento][:varnish].to_hash

variables[:backend].each do |key, value|
  while value.is_a?(String) || value.is_a?(Symbol) do
    value = variables[:backend][value.to_s]
  end

  variables[:backend][key] = value
end

variables[:balancer].map! {|v| v.to_s }
variables[:balancer].keep_if { |v| variables[:backend].key?(v) }

variables[:ip_local_regexp] = ['127.0.0.1']
variables[:ip_admin_regexp] = ['127.0.0.1']
variables[:ip_refresh_regexp] = ['127.0.0.1']

variables[:ip_local].each { |ip| variables[:ip_local_regexp] << ip }
variables[:ip_admin].each { |ip| variables[:ip_admin_regexp] << ip }
variables[:ip_refresh].each { |ip| variables[:ip_refresh_regexp] << ip }

variables[:ip_admin_regexp].map! { |v| Regexp.escape(v) }
variables[:ip_local_regexp].map! { |v| Regexp.escape(v) }
variables[:ip_refresh_regexp].map! { |v| Regexp.escape(v) }

template ::File.join(node[:varnish][:config_dir], 'magento.vcl') do
  source 'varnish.vcl.erb'
  variables variables
  notifies(:reload, {:service => 'varnish'}, :delayed)
  notifies(:reload, {:service => 'varnishlog'}, :delayed)
end

include_recipe 'chef-varnish::default'

daemon_config = resources(:template => node[:varnish][:daemon_config])
daemon_config.notifies(:restart, {:service => 'varnish'}, :delayed)
daemon_config.notifies(:restart, {:service => 'varnishlog'}, :delayed)
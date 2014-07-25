include_recipe 'magento::default'

directives = {
   'opcache.memory_consumption' => 128,
   'opcache.interned_strings_buffer' => 8,
   'opcache.max_accelerated_files' => 4000,
   'opcache.revalidate_freq' => 60,
   'opcache.fast_shutdown' => 1,
   'opcache.enable_cli' => 1
}

current_directives = node.deep_fetch!('php', 'directives').to_hash
directives.merge!(current_directives)

node.set[:php][:directives] = directives
node.default[:php][:major_version] = '5.4'

include_recipe 'php_fpm::default'

unless constraint('~>5.5').satisfied_by?(node[:php][:major_version])
  php_pear 'zendopcache' do
    preferred_state 'beta'
  end
end

node.default[:magento][:application][:database_options] = node[:magento][:default][:database]

magento_application node[:magento][:application][:name] do
  node[:magento][:application].to_hash.each_pair do |key, value|
    send(key.to_sym, value)
  end
end

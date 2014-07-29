include_recipe 'magento::default'

require 'chef/mixin/deep_merge'

directives = {
   'opcache.memory_consumption' => 128,
   'opcache.interned_strings_buffer' => 8,
   'opcache.max_accelerated_files' => 4000,
   'opcache.revalidate_freq' => 60,
   'opcache.fast_shutdown' => 1,
   'opcache.enable_cli' => 1
}

current_directives = node.deep_fetch!('php', 'directives').to_hash
Chef::Mixin::DeepMerge.deep_merge!(current_directives, directives)

node.default[:php][:directives] = directives
node.default[:php][:major_version] = '5.4'

include_recipe 'php_fpm::default'

unless constraint('~>5.5').satisfied_by?(node[:php][:major_version])
  php_pear 'zendopcache' do
    preferred_state 'beta'
  end
end

database_options = node[:magento][:default][:database].to_hash

Chef::Mixin::DeepMerge.deep_merge!(node[:magento][:application][:database_options].to_hash, database_options)

puts 'chef attribute before set'
puts database_options
node.default[:magento][:application][:database_options] = database_options
puts 'chef attribute after set'
puts database_options

magento_application node[:magento][:application][:name] do
  node[:magento][:application].to_hash.each_pair do |key, value|
    send(key.to_sym, value)
  end
end

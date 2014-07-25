servers = []

node[:magento][:redis].each_pair do |key, value|
  if value.is_a?(Hash) && value.key?(:port)
    servers << {port: value[:port], name: key.to_s}
  end
end


node.set[:redisio] = {
    :servers => servers
}

include_recipe 'redisio::install'
include_recipe 'redisio::enable'
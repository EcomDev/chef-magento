require 'chef/mixin/deep_merge'

application_options = node.deep_fetch!('magento', 'default', 'application').to_hash

Chef::Mixin::DeepMerge.deep_merge!(
    {
        name: 'magento',
        main_domain: 'magento.dev',
        directory: '/vagrant'
    },
    application_options
)

unless node.deep_fetch('magento', 'application').nil?
  Chef::Mixin::DeepMerge.deep_merge!(node.deep_fetch('magento', 'application').to_hash, application_options)
end

namespace 'magento' do
  application application_options
end
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

namespace 'magento' do
  application application_options
end
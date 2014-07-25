namespace 'magento' do
  application node.deep_fetch!('magento', 'default', 'application')
end

node.default![:magento][:application][:name] = 'magento'
node.default![:magento][:application][:main_domain] = 'magento.dev'
node.default![:magento][:application][:directory] = '/vagrant'
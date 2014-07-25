require 'spec_helper'

describe 'magento::default' do
  before(:each) { allow_recipe('mysql::server') }

  let(:chef_run) do
    chef_run_proxy.instance(step_into: 'magento_database') do |node|
      node.set[:mysql][:server_root_password] = 'somerandompassword'
      node.set[:mysql][:port] = '3307'
    end
  end

  let(:connection_settings) { chef_run.node[:magento][:default][:database][:connection_settings] }

  it 'does not change connection attributes if recipe is not included' do
    chef_run.converge(described_recipe)
    expect(connection_settings[:password]).to eq('')
    expect(connection_settings.key?(:port)).to eq(false)
  end

  it 'changes connection attributes if recipe is included' do
    chef_run.converge(described_recipe, 'mysql::server')
    expect(connection_settings[:password]).to eq('somerandompassword')
    expect(connection_settings[:port]).to eq(3307)
  end
end
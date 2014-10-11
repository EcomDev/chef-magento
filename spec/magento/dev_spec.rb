require 'spec_helper'

describe 'magento::dev' do
  let(:chef_run) do
    chef_run_proxy.instance.converge(described_recipe)
  end

  it 'should include magerun tool recipe' do
    expect(chef_run).to include_recipe('n98-magerun::default')
  end

  it 'should install htop package' do
    expect(chef_run).to install_package('htop')
  end

  it 'should install vim package' do
    expect(chef_run).to install_package('vim')
  end
end
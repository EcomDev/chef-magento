require 'spec_helper'

describe 'magento::redis' do
  let(:chef_run) do
    chef_run_proxy.instance.converge(described_recipe)
  end

  def node(&block)
    chef_run_proxy.before(:converge) do |runner|
      if block.arity == 1
        block.call(runner.node)
      end
    end
  end


  it 'should set redis ports for cache and session' do
    expect(chef_run.node[:redisio][:servers]).to include({port: chef_run.node[:magento][:redis][:cache][:port],
                                                          name: 'cache'},
                                                         {port: chef_run.node[:magento][:redis][:session][:port],
                                                          name: 'session'})
  end

  it 'should include redisio::install' do
    expect(chef_run).to include_recipe('redisio::install')
  end

  it 'should include redisio::enable' do
    expect(chef_run).to include_recipe('redisio::install')
  end

end
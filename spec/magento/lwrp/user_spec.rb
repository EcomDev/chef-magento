require 'spec_helper'

describe 'magento_test::user' do
  before (:each) { allow_recipe('magento::default', 'vhost::nginx') }

  let(:chef_run) do
    chef_run_instance.converge(described_recipe)
  end

  def chef_run_instance(&block)
    chef_run_proxy.instance(step_into: 'magento_user') do |node|
      node.set[:test][:name] = 'test'
      unless block.nil?
        block.call(node)
      end
    end
  end

  let (:default_params) { chef_run.node.default[:magento][:default][:database] }

  let (:connection_settings) { default_params[:connection_settings] }

  let (:node) { chef_run.node }

  context 'In all systems' do
    it 'should invoke a magento_user resource with create action' do
      expect(chef_run).to create_magento_user('test')
    end

    it 'should invoke a system user creation' do
      expect(chef_run).to create_user('test').with(uid: nil, gid: nil, system: true, shell: '/bin/bash')
    end

    it 'should invoke a system user creation with uid' do
      test_params do |params|
        params[:uid] = 501
      end
      expect(chef_run).to create_user('test').with(uid: 501, gid: nil, system: true, shell: '/bin/bash')
    end

    it 'should invoke a system user creation with uid' do
      runner = chef_run_instance do |node|
        node.set[:test][:name] = 'test'
        node.set[:test][:uid] = 501
        node.set[:test][:gid] = :system_default
      end

      runner.converge(described_recipe, 'vhost::nginx')
      expect(runner).to create_user('test').with(uid: 501, gid: 'www-data', system: true, shell: '/bin/bash')
    end

    it 'should not change group to system default if no detection can be done' do
      test_params do |params|
        params[:uid] = 501
        params[:gid] = :system_default
      end

      expect(chef_run).to create_user('test').with(uid: 501, gid: nil, system: true, shell: '/bin/bash')
    end

    it 'should modify a system nginx user uid if there is an nginx user' do
      runner = chef_run_instance do |node|
        node.set[:test][:name] = 'www-data'
        node.set[:test][:uid] = 501
      end

      runner.converge('vhost::nginx', described_recipe)

      expect(runner).to create_magento_user('www-data')
      expect(runner).to modify_user('www-data').with(uid: 501)
    end

    it 'removes a user' do
      test_params do |params|
        params[:action] = 'delete'
      end
      expect(chef_run).to delete_magento_user('test')
      expect(chef_run).to remove_user('test')
    end
  end
end
require 'spec_helper'

describe 'magento_test::database' do
  before (:each) { allow_recipe('magento::default', 'database::mysql') }

  let(:chef_run) do
    chef_run_proxy.instance(step_into: 'magento_database') do |node|
      node.set[:test][:name] = 'test'
    end.converge(described_recipe)
  end

  let (:default_params) { {
      'encoding' => 'utf8',
      'connection_settings' => {
          'host' => 'localhost',
          'user' => 'root'
      }
  }}

  let (:connection_settings) { default_params['connection_settings'] }

  let (:node) { chef_run.node }

  it 'should include database' do
    expect(chef_run).to include_recipe('database::mysql')
  end

  it 'should invoke a magento_db resource with create action' do
    expect(chef_run).to create_magento_database('test')
  end

  it 'should invoke a mysql database resource with create action' do
    expect(chef_run).to create_mysql_database('test')
                         .with(
                             connection: connection_settings,
                             encoding: default_params['encoding']
                         )
  end

  it 'should invoke a mysql database user resource with create action' do
    expect(chef_run).to create_mysql_database_user('test')
                         .with(
                             connection: connection_settings,
                             username: 'test',
                             password: 'test',
                             host: '%',
                             database_name: 'test'
                         )
  end

  it 'should invoke a mysql database user resource with grant action' do
    expect(chef_run).to grant_mysql_database_user('test')
                         .with(
                             connection: connection_settings,
                             username: 'test',
                             password: 'test',
                             host: '%',
                             database_name: 'test'
                         )
  end

  it 'should invoke a mysql test database resource with create action' do
    test_params do |params|
      params[:create_test] = true
    end

    expect(chef_run).to create_mysql_database('test_test')
                        .with(
                            connection: connection_settings,
                            encoding: default_params['encoding']
                        )
  end

  it 'should invoke a mysql test database user resource with grant action' do
    test_params do |params|
      params[:create_test] = true
    end

    expect(chef_run).to grant_mysql_database_user('test_test')
                        .with(
                            connection: connection_settings,
                            username: 'test',
                            password: 'test',
                            host: '%',
                            database_name: 'test_test',
                        )
  end

  it 'should invoke a magento_db resource with delete action' do
    test_params do |params|
      params[:action] = :delete
    end

    expect(chef_run).to include_recipe('database::mysql')
    expect(chef_run).to include_recipe('magento::default')
    expect(chef_run).to delete_magento_database('test')

    expect(chef_run).to drop_mysql_database('test')
                         .with(
                             connection: connection_settings
                         )

    expect(chef_run).to drop_mysql_database_user('test')
                         .with(
                             connection: connection_settings,
                             username: 'test',
                             host: '%'
                         )
  end


end
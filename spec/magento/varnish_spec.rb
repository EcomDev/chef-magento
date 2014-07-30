require 'spec_helper'

describe 'magento::varnish' do
  let(:chef_run) do
    chef_run_proxy.instance(platform: 'ubuntu', version: '12.04').converge(described_recipe)
  end

  before(:each) do
    allow_recipe('apt', 'chef-varnish::default')
  end

  def node(&block)
    chef_run_proxy.block(:initialize) do |runner|
      if block.arity == 1
        block.call(runner.node)
      end
    end
  end

  it 'includes varnish recipe' do
    expect(chef_run).to include_recipe('chef-varnish::default')
  end

  it 'includes magento::default recipe' do
    expect(chef_run).to include_recipe('magento::default')
  end

  it 'creates a secret key file with secure password' do
    allow_any_instance_of(Chef::Recipe).to receive(:secure_password).and_return('password_key')
    expect(chef_run).to render_file(chef_run.node[:varnish][:VARNISH_SECRET_FILE]).with_content('password_key')
  end

  it 'does not create a secret key file if it is already exists' do
    stub_file_exists('varnish/secret')

    node do |n|
      n.set[:varnish][:VARNISH_SECRET_FILE] = 'varnish/secret'
    end

    expect(chef_run).not_to render_file('varnish/secret')
  end

  it 'downloads remote file of device detect library' do
    expect(chef_run).to create_remote_file(
                            ::File.join(chef_run.node[:varnish][:config_dir], 'devicedetect.vcl')
                        ).with(source: chef_run.node[:magento][:varnish][:device_detect_file])
  end

  it 'adds a notifier for template of varnish daemon' do
    template = chef_run.template(chef_run.node['varnish']['daemon_config'])

    expect(template).to notify('service[varnish]').to(:restart).delayed
    expect(template).to notify('service[varnishlog]').to(:restart).delayed
  end

  it 'adds a notifier for device detect file' do
    remote_file = chef_run.remote_file(::File.join(chef_run.node[:varnish][:config_dir], 'devicedetect.vcl'))

    expect(remote_file).to notify('service[varnish]').to(:reload).delayed
    expect(remote_file).to notify('service[varnishlog]').to(:reload).delayed
  end

  it 'should set varnish VCL attribute to Magento one' do
    expect(chef_run.node[:varnish][:VARNISH_VCL_CONF]).to eq(::File.join(chef_run.node[:varnish][:config_dir], 'magento.vcl'))
  end

  it 'should set varnish VCL port to a value from magento/varnish/port' do
    expect(chef_run.node[:varnish][:VARNISH_LISTEN_PORT]).to eq(chef_run.node[:magento][:varnish][:port])
  end

  it 'renders a magento varnish VCL file' do
    expect(chef_run).to render_file(::File.join(chef_run.node[:varnish][:config_dir], 'magento.vcl')).with_content(
                          ::File.read(::File.join(::File.dirname(__FILE__), 'varnish_vcl.expected'))
                        )
  end

  it 'renders a magento varnish VCL file with additional options' do
    node do |n|
      n.set[:magento][:varnish][:ip_local] = %w(192.168.6.1)
      n.set[:magento][:varnish][:ip_admin] = %w(192.168.5.1)
      n.set[:magento][:varnish][:ip_refresh] = %w(192.168.4.1)
      n.set[:magento][:varnish][:hide_varnish_header] = %w(X-Header-Additional)
    end

    expect(chef_run).to render_file(::File.join(chef_run.node[:varnish][:config_dir], 'magento.vcl')).with_content(
                            ::File.read(::File.join(::File.dirname(__FILE__), 'varnish_vcl.options.expected'))
                        )
  end

  it 'adds a notifier for template of magento varnish vcl' do
    template = chef_run.template(::File.join(chef_run.node[:varnish][:config_dir], 'magento.vcl'))

    expect(template).to notify('service[varnish]').to(:reload).delayed
    expect(template).to notify('service[varnishlog]').to(:reload).delayed
  end

  it 'creates varnish configuration directory' do
    expect(chef_run).to create_directory(chef_run.node[:varnish][:config_dir])
  end

  it 'does not create varnish configuration directory if it already exists' do
    node do |n|
      n.set[:varnish][:config_dir] = '/etc/varnish'
    end

    stub_file_exists('/etc/varnish')
    expect(chef_run).to create_directory(chef_run.node[:varnish][:config_dir])
  end

end
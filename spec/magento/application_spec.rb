require 'spec_helper'

describe 'magento::application' do
  before (:each) { allow_recipe('magento::default') }
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


  it 'should include magento::default recipe' do
    expect(chef_run).to include_recipe('magento::default')
  end

  it 'sets default php version to 5.4' do
    expect(chef_run.node[:php][:major_version]).to eq('5.4')
  end

  it 'installs php opcache extension zendopcache ' do
    expect(chef_run).to install_php_pear('zendopcache').with(preferred_state: 'beta')
  end

  it 'does not install php_opcode cache if php version is 5.5' do
    node do |n|
      n.set[:php][:major_version] = '5.5'
    end

    expect(chef_run).not_to install_php_pear('zendopcache')
  end

  it 'sets directives for php opcode cache' do
    expect(chef_run.node[:php][:directives]).to include(
      'opcache.memory_consumption' => 128,
      'opcache.interned_strings_buffer' => 8,
      'opcache.max_accelerated_files' => 4000,
      'opcache.revalidate_freq' => 60,
      'opcache.fast_shutdown' => 1,
      'opcache.enable_cli' => 1
    )
  end

  it 'sets default database configuration options from magento/default/database attributes' do
    expect(chef_run.node.default[:magento][:application][:database_options]).to eq(chef_run.node[:magento][:default][:database])
  end

  it 'makes possible to override default connection settings' do
    node do |n|
      n.set[:magento][:application][:database_options][:connection_settings][:user] = 'budy'
    end

    expect(chef_run.node[:magento][:application][:database_options][:connection_settings]).to include('user' => 'budy',
                                                                                                      'password' => '',
                                                                                                      'host' => 'localhost')
  end

  it 'creates a magento application with specified attributes' do
    expect(chef_run).to create_magento_application('magento')
                        .with(
                            main_domain: 'magento.dev',
                            user: :system_default,
                            group: :system_default,
                            handler: 'index.php'
                        )
  end
end
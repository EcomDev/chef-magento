
# Support whyrun
def whyrun_supported?
  true
end

action :create do
  run_context.include_recipe('database::mysql')
  run_context.include_recipe('magento::default')

  options = resource_options

  mysql_database options[:name] do
    connection options[:connection_settings]
    encoding options[:encoding] if options.key?(:encoding)
    collation options[:collation] if options.key?(:collation)
  end

  mysql_database_user options[:user] do
    connection options[:connection_settings]
    username options[:user]
    password options[:password]
    host options[:host]
    database_name options[:name]
    action [:create, :grant]
  end
end


action :delete do
  run_context.include_recipe('database::mysql')
  run_context.include_recipe('magento::default')

  options = resource_options

  mysql_database options[:name] do
    action :drop
    connection options[:connection_settings]
  end

  mysql_database_user options[:user] do
    action :drop
    host options[:host]
    connection options[:connection_settings]
  end
end

private

def resource_options
  options = new_resource.dump_attribute_values(node[:magento][:default][:database], :magento_default)

  if options[:user] == :database_name
    options[:user] = options[:name]
  end

  if options[:password] == :database_name
    options[:password] = options[:name]
  end

  options
end

# Support whyrun
def whyrun_supported?
  true
end

action :create do
  run_context.include_recipe('magento::default')

  options = resource_options

  user options[:name] do
    if node.recipe?('vhost::nginx') && node[:nginx][:user] == options[:name]
      action :modify
      uid options[:uid]
    else
      action :create
      uid options[:uid]
      gid options[:gid]
      system true
      shell "/bin/bash"
    end
  end
end

action :delete do
  run_context.include_recipe('magento::default')

  user new_resource.name do
    action :remove
  end
end

private

def resource_options
  options = new_resource.dump_attribute_values(node[:magento][:default][:user], :magento_default)

  if options[:uid] == :system_default
    options[:uid] = nil
  end

  if options[:gid] == :system_default
    options[:gid] = nil
    if node.recipe?('vhost::nginx')
      options[:gid] = node[:nginx][:group]
    end
  end

  options
end
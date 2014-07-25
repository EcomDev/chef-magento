
magento_user node[:test][:name] do
  if node[:test].attribute?(:action)
    action node[:test][:action]
  end
  attribute_names.each do |attribute|
    if node[:test].attribute?(attribute)
      send(attribute.to_sym, node[:test][attribute])
    end
  end
end
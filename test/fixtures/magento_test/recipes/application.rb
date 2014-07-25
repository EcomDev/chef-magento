
magento_application node[:test][:name] do
  if node[:test].attribute?(:action)
    action node[:test][:action]
  end
  attribute_names.each do |attribute|
    if node[:test].attribute?(attribute)
      if node[:test][attribute].is_a?(Hash)
        value = node[:test][attribute].to_hash
      elsif node[:test][attribute].is_a?(Array)
        value = node[:test][attribute].to_a
      else
        value = node[:test][attribute]
      end
      send(attribute.to_sym, value)
    end
  end
end
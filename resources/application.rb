actions :create, :delete

attribute :name, :kind_of => [String, Symbol], :name_attribute => true # Name of the database
attribute :vhost, :kind_of => [String, Symbol], :default => :magento_default # Type of Vhost
attribute :ssl, :kind_of => [Hash, Symbol], :default => :magento_default # Hash of private and public keys for ssl

attribute :directory, :kind_of => [String, Symbol], :default => :magento_default # Dirname that will be used for application
attribute :main_domain, :kind_of => [String, Symbol], :required => true # Main application domain name
attribute :domains, :kind_of => [Array, Symbol], :default => :magento_default # Additional application domain names
attribute :domain_map, :kind_of => [Hash, Symbol], :default => :magento_default # Additional application domain names
attribute :user, :kind_of => [String, Symbol], :default => :magento_default # Username that will be created for application
attribute :uid, :kind_of => [Integer, Symbol], :default => :magento_default # Username that will be created for application
attribute :group, :kind_of => [String, Symbol], :default => :magento_default # Group password that will be created for application
attribute :handler, :kind_of => [String, Symbol], :default => :magento_default # Magento main php handler
attribute :time_limit, :kind_of => [String, Symbol], :default => :magento_default # Magento time limit in seconds
attribute :memory_limit, :kind_of => [String, Symbol], :default => :magento_default # Magento memory limit in seconds
attribute :php_extensions, :kind_of => [Hash, Symbol], :default => :magento_default # Additional PHP extensions for Magento
attribute :status_path, :kind_of => [String, Symbol], :default => :magento_default # Magento status page (default is php-fpm status)
attribute :status_ips, :kind_of => [Array, Symbol], :default => :magento_default # Ips that allow status page discovery
attribute :store_map, :kind_of => [Hash, Symbol], :default => :magento_default # Map of store or website code to hostname
attribute :http_port, :kind_of => [String, Symbol], :default => :magento_default # Http port setting
attribute :https_port, :kind_of => [String, Symbol], :default => :magento_default # Https port setting
attribute :log_dir, :kind_of => [String, Symbol], :default => :magento_default # Magento log directory
attribute :php_fpm_options, :kind_of => [Hash, Symbol], :default => :magento_default # Magento log directory
attribute :deny_paths, :kind_of => [Array, Symbol], :default => :magento_default # Denied path in Magento configuration
attribute :cache_static, :kind_of => [String, Symbol], :default => :magento_default # Cache static files options
attribute :custom_locations, :kind_of => Hash, :default => {} # Custom locations for nginx
attribute :buffers, :kind_of => [String, Symbol], :default => :magento_default # Fastcgi buffers in nginx
attribute :buffer_size, :kind_of => [String, Symbol], :default => :magento_default # Fastcgi buffer size in nginx
attribute :database_options, :kind_of => [Hash, Symbol], :default => :magento_default # Database connection and creation options
attribute :composer, :kind_of => [TrueClass, FalseClass, Symbol], :default => :magento_default # Flag for auto-composer installation
attribute :composer_path, :kind_of => [String, Symbol], :default => :magento_default # Flag for auto-composer installation

def initialize(*args)
  super
  @action = :create
end
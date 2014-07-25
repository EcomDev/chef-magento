actions :create, :delete

attribute :name, :kind_of => [String, Symbol], :name_attribute => true # Name of the database

attribute :user, :kind_of => [String, Symbol], :default => :magento_default # Username that will be created for a database
attribute :password, :kind_of => [String, Symbol], :default => :magento_default # Password for database user
attribute :host, :kind_of => [String, Symbol], :default => :magento_default # Password for database user

attribute :encoding, :kind_of => [String, Symbol], :default => :magento_default # Password for database user
attribute :collation, :kind_of => [String, Symbol], :default => :magento_default # Password for database user

attribute :connection_settings, :kind_of => [Hash, Symbol], :default => :magento_default # User for php process, by default will take value from magento[database][default]

def initialize(*args)
  super
  @action = :create
end
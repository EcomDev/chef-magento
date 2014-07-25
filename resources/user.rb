actions :create, :delete

attribute :name, :kind_of => [String, Symbol], :name_attribute => true # Name of the database

attribute :uid,  :kind_of => [Integer, NilClass, Symbol], :default => :magento_default # UID of the user
attribute :gid,  :kind_of => [String, Integer, NilClass, Symbol], :default => :magento_default # GID of the user

def initialize(*args)
  super
  @action = :create
end
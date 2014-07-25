# Magento recipe resources
runner :magento_database
matcher :magento_database, :create
matcher :magento_database, :delete

runner :magento_application
matcher :magento_application, :create
matcher :magento_application, :delete

runner :magento_user
matcher :magento_user, :create
matcher :magento_user, :delete

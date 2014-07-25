# database::mysql recipe resources
runner [:mysql_database, :mysql_database_user]

matcher :mysql_database, :create
matcher :mysql_database, :drop

matcher :mysql_database_user, :create
matcher :mysql_database_user, :grant
matcher :mysql_database_user, :drop


#!/bin/bash

#=================================================
# RETRIEVE ARGUMENTS FROM THE MANIFEST
#=================================================

domain=$YNH_APP_ARG_DOMAIN
path_url=$YNH_APP_ARG_PATH

admin=$YNH_APP_ARG_ADMIN
is_public=$YNH_APP_ARG_IS_PUBLIC
app=$YNH_APP_INSTANCE_NAME

# Transfer the main SSO domain to the App:
ynh_current_host=$(cat /etc/yunohost/current_host)
__YNH_CURRENT_HOST__=${ynh_current_host}

#=================================================
# ARGUMENTS FROM CONFIG PANEL
#=================================================

# 'debug_enabled' -> '__DEBUG_ENABLED__' -> settings.DEBUG
debug_enabled="0"

# 'log_level' -> '__LOG_LEVEL__' -> settings.LOG_LEVEL
log_level="WARNING"

# 'admin_email' -> '__ADMIN_EMAIL__' add in settings.ADMINS
admin_email="${admin}@${domain}"

# 'default_from_email' -> '__DEFAULT_FROM_EMAIL__' -> settings.DEFAULT_FROM_EMAIL
default_from_email="${app}@${domain}"

#=================================================
# SET CONSTANTS
#=================================================

public_path=/var/www/$app
final_path=/opt/yunohost/$app
log_path=/var/log/$app
log_file="${log_path}/${app}.log"

#=================================================
# COMMON VARIABLES
#=================================================

# Needed base dependencies:
pkg_dependencies="build-essential python3-dev python3-pip python3-venv git"

# For pillow:
pkg_dependencies="${pkg_dependencies} libjpeg-dev"

# Postgres and Python's "psycopg2":
pkg_dependencies="${pkg_dependencies} libpq-dev postgresql postgresql-contrib"

# Needed for lxml: https://lxml.de/installation.html#requirements
pkg_dependencies="${pkg_dependencies} libxml2-dev libxslt-dev"

#=================================================
# Redis HELPERS
#=================================================

# get the first available redis database
#
# usage: ynh_redis_get_free_db
# | returns: the database number to use
ynh_redis_get_free_db() {
	local result max db
	result=$(redis-cli INFO keyspace)

	# get the num
	max=$(cat /etc/redis/redis.conf | grep ^databases | grep -Eow "[0-9]+")

	db=0
	# default Debian setting is 15 databases
	for i in $(seq 0 "$max")
	do
	 	if ! echo "$result" | grep -q "db$i"
	 	then
			db=$i
	 		break 1
 		fi
 		db=-1
	done

	test "$db" -eq -1 && ynh_die "No available Redis databases..."

	echo "$db"
}

# Create a master password and set up global settings
# Please always call this script in install and restore scripts
#
# usage: ynh_redis_remove_db database
# | arg: database - the database to erase
ynh_redis_remove_db() {
	local db=$1
	redis-cli -n "$db" flushall
}


#! /usr/bin/bash

#============ start initial information ============

echo
echo "========================== Create new database ========================="
echo

#============ end initial information ============

#============ start helper functions ============
database_exists() {
    local db_name="$1"
    if [[ -d "$engine_dir/.db-engine-users/$loggedInUser/$db_name" ]]; then
        return 0
    else
        return 1
    fi
}

validate_database() {
    local database="$1"
    if [[ $database =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        return 0
    else
        return 1
    fi
}

#============ end helper functions ============

#============ start script body ============

read -p "Enter database name: " db_name

if database_exists "$db_name"; then
    output_error_message "Database already exists"
    sleep 1
elif ! validate_database "$db_name"; then
    output_error_message "Invalid database name. Database name must start with a letter and contain only alphanumeric characters or underscores."
    sleep 1
else
    mkdir "$engine_dir/.db-engine-users/$loggedInUser/$db_name"
    output_success_message "Database created successfully"
    sleep 1
    break
fi
#============ end script body ============

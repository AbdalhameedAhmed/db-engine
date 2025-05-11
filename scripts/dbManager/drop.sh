#1 /usr/bin/bash

#============ start initial information ============

echo
echo "========================== Drop Database ========================="
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
#============ end helper functions ============

#============ start script body ============

read -p "Enter database name: " db_name
if [[ -n "$db_name" ]]; then
    if database_exists $db_name ;then
    rm -r "$engine_dir/.db-engine-users/$loggedInUser/$db_name"
    output_success_message "Database dropped successfully"
    sleep 1
    else
    output_error_message "Database does not exist"
    sleep 1
    fi
    else
    output_error_message "Enter an existing database name or exit to cancel"
    sleep 1
fi
fi

#============ end script body ============
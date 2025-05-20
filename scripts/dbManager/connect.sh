#! /usr/bin/bash


#============ start initial information ============

echo
echo "========================== connected to database ========================="
echo

#============ end initial information ============

#============ start global variables ============

connected_db=""

#============ end global variables ============

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
while true ; do
read -p "Enter database name: " db_name
    if [[ -n "$db_name" ]]; then
        if [[ "$db_name" == "exit" ]]; then
            break
        elif database_exists $db_name ;then
        connected_db="$db_name"
        output_success_message "connected to database successfully"
        source $script_dir/scripts/tbManager/main.sh
        break
        sleep 1
        else
        output_error_message "Database does not exist"
        sleep 1
        fi
        else
        output_error_message "Enter an existing database name or exit to cancel"
        sleep 1
    fi
done
#============ end script body ============

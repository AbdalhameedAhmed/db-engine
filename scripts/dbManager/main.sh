#! /usr/bin/bash

#============ start global variables ============

dbManager_options=("create database" "Connect to database" "list databases" "drop database" "logout")

#============ end global variables ============

#============ start helper functions ============

update_allowed_dbManager_options() {
allowed_dbManager_options=()
for option in "${dbManager_options[@]}"; do
    if [[ "$option" == "list databases" || "$option" == "drop database" || "$option" == "Connect to database" ]];then
        local allDbs=$(ls -F "$engine_dir/.db-engine-users/$loggedInUser" | grep '/$' | sed 's/\/$//')
        if [[ -n "$allDbs" ]]; then
            allowed_dbManager_options+=("Connect to database")
            allowed_dbManager_options+=("list databases")
            allowed_dbManager_options+=("drop database")
            break
        fi
    else
        allowed_dbManager_options+=("$option")        
    fi
done
    
}
#============ end helper functions ============

#============ start script body ============

while true ; do 
    update_allowed_dbManager_options
    select option in "${allowed_dbManager_options[@]}"; do
        case $option in 

            "create database")
                source $script_dir/scripts/dbManager/create.sh
                break
            ;;

            "list databases")
                source $script_dir/scripts/dbManager/list.sh
                break
            ;;
        esac
    done
done
#============ end script body ============
#! /usr/bin/bash

#============ start global variables ============

dbManager_options=("Create database" "Connect to database" "List databases" "Drop database" "Logout")
logout=""
connected_db=""

#============ end global variables ============

#============ start helper functions ============

update_allowed_dbManager_options() {
allowed_dbManager_options=()
for option in "${dbManager_options[@]}"; do
    if [[ "$option" == "List databases" || "$option" == "Drop database" || "$option" == "Connect to database" ]];then
        local allDbs=$(ls -F "$engine_dir/.db-engine-users/$loggedInUser" | grep '/$' | sed 's/\/$//')
        if [[ -n "$allDbs" ]]; then
            allowed_dbManager_options+=("Connect to database")
            allowed_dbManager_options+=("List databases")
            allowed_dbManager_options+=("Drop database")
            allowed_dbManager_options+=("Logout")
            break
        fi
    else
        allowed_dbManager_options+=("$option")        
    fi
done
    
}
#============ end helper functions ============

#============ start script body ============

while [[ -z "$logout" ]] ; do 
    update_allowed_dbManager_options
    select option in "${allowed_dbManager_options[@]}"; do
        case $option in 

            "Create database")
                source $script_dir/scripts/dbManager/create.sh
                break
            ;;

            "Connect to database")
                source $script_dir/scripts/dbManager/connect.sh
                break
            ;;

            "List databases")
                source $script_dir/scripts/dbManager/list.sh
                break
            ;;

            "Drop database")
                source $script_dir/scripts/dbManager/drop.sh
                break
            ;;
            "Logout")
            logout="true"
            loggedInUser=""
            PS3='Login/Register:'
            echo
            output_success_message "Logged out successfully"
            echo
            sleep 1
            break
            ;;
            "*")
                echo
                output_error_message "invalid option $REPLY"
                echo
                break
                ;;
        esac
    done
done
#============ end script body ============
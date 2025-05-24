#! /usr/bin/bash

#============ start global variables ============

dbManager_options=("Create database" "Connect to database" "List databases" "Drop database" "Logout")
logout=""
connected_db=""
passwd_path="$engine_dir/.db-engine-users/.passwd"
passwd_temp_path="$engine_dir/.db-engine-users/.passwd.temp"

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

remove_ps_id() {
    usersContent=$(get_users)
    local username="$1"
    cat $passwd_path >> $passwd_temp_path
    
    > $passwd_path

    IFS=$'\n' 
    read -d '' -r -a all_users_data_arr < <(printf %s "$usersContent")
    for user_row in "${all_users_data_arr[@]}"; do
        if [[ "$user_row" =~ ^$username:.*$ ]] ; then 
            split_string_to_array "$user_row" ":" user_data_array
            user_data_array[5]="null"
            user_row=$(IFS=":"; echo "${user_data_array[*]}") 
        fi
        echo "$user_row" >> $passwd_path
    done
    rm $passwd_temp_path
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
            if [[ -n "$loggedInUser" && -z "$admin_info" ]];then
            remove_ps_id $loggedInUser
            fi
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
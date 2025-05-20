#! /usr/bin/bash

#============ start script body ============

while true ; do
    read -e -p "Enter user name: " user_to_connect
    if [[ "$user_to_connect" == "exit" ]]; then
        break
    fi
    
    if user_exists "$user_to_connect" ; then 

        if [[ "$user_to_connect" == "$admin_info" ]];then
            output_error_message "Cannot connect to yourself"
        else
            echo 
            output_success_message "Connecting to $user_to_connect"
            echo 
            loggedInUser="$user_to_connect"
            PS3="$admin_info/$user_to_connect/dbManaging: "
            source $script_dir/scripts/dbManager/main.sh
            break;
        fi
    else 
    output_error_message "User does not exist"
    fi
    

done

#============ end script body ============

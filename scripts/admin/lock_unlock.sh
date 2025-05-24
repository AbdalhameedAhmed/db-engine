#! /usr/bin/bash

#============ start helper functions ============

lock_unlock_user() {
    local username="$1"
    local new_lock_value="$2"
    local message="$3"
    touch $passwd_temp_path
    cat $passwd_path >> $passwd_temp_path
    
    > $passwd_path

    IFS=$'\n' 
    read -d '' -r -a all_users_data_arr < <(printf %s "$usersContent")
    for user_row in "${all_users_data_arr[@]}"; do
        if [[ "$user_row" =~ ^$username:.*$ ]] ; then 
            split_string_to_array "$user_row" ":" user_data_array
            user_data_array[3]="$new_lock_value"
            if [[ -n "$message" ]] ; then 
            user_data_array[4]="$message"
            else
            user_data_array[4]="null"
            fi
            user_row=$(IFS=":"; echo "${user_data_array[*]}")  
        fi
        echo "$user_row" >> $passwd_path
    done
    rm $passwd_temp_path
}

#============ end helper functions ============

#============ start script body ============

get_users

while true ; do
    read -e -p "Enter user name: " user_to_lock
    if [[ "$user_to_connect" == "exit" ]]; then
        break
    fi
    
    if user_exists "$user_to_lock" ; then 
        if [[ "$user_to_lock" == "$admin_info" ]];then
            output_error_message "Cannot lock yourself"
        else
            user_data=$(get_user_info "$user_to_lock")
            lock_state=$(echo "$user_data" | cut -d ':' -f 4)
            if [[ "$lock_state" == "1" ]] ; then
                read -e -p "Enter your message: " message
                lock_unlock_user "$user_to_lock" "0" "$message"
                output_success_message "User $user_to_lock locked successfully"
            else
                lock_unlock_user "$user_to_lock" "1"
                output_success_message "User $user_to_lock unlocked successfully"
            fi
            break
        fi
    else 
    output_error_message "User does not exist"
    fi
    
done

#============ end script body ============

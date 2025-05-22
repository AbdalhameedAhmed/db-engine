#! /usr/bin/bash


#============ start initial information ============

echo
echo "========================== Login ========================="
echo

#============ end initial information ============

#============ start global variables ============

passwd_path="$engine_dir/.db-engine-users/.passwd"
passwd_temp_path="$engine_dir/.db-engine-users/.passwd.temp"

#============ end global variables ============

#============ start helper functions ============

hash_password() {
    local password="$1"
    echo -n "$password" | sha256sum | cut -d' ' -f1
}

get_user_info() {
    local username="$1"
    local result=$(grep "^$username:" "$engine_dir/.db-engine-users/.passwd")
    echo $result
}

user_dir_exists() {
    local username="$1"
    if [[ -d "$engine_dir/.db-engine-users/$username" ]]; then
        return 0
    else
        return 1
    fi
}

is_admin_user() {
    local username="$1"
    userInfo=$(get_user_info "$username")
    user_rule=$(echo "$userInfo" | cut -d':' -f3)
    if [[ $user_rule == "1" ]]; then
        return 0
    else
        return 1
    fi
}

# lock_unlock_user() {
#     local username="$1"
#     local new_lock_value="$2"
#     local message="$3"
#     touch $passwd_temp_path
#     cat $passwd_path >> $passwd_temp_path
    
#     > $passwd_path

#     IFS=$'\n' 
#     read -d '' -r -a all_users_data_arr < <(printf %s "$usersContent")
#     for user_row in "${all_users_data_arr[@]}"; do
#         if [[ "$user_row" =~ ^$username:.*$ ]] ; then 
#             split_string_to_array "$user_row" ":" user_data_array
#             user_data_array[3]="$new_lock_value"
#             if [[ -n "$message" ]] ; then 
#             user_data_array[4]="$message"
#             else
#             user_data_array[4]="null"
#             fi
#             user_row=$(IFS=":"; echo "${user_data_array[*]}")  
#         fi
#         echo "$user_row" >> $passwd_path
#     done
#     rm $passwd_temp_path
# }

set_ps_id() {
    local username="$1"
    cat $passwd_path >> $passwd_temp_path
    
    > $passwd_path

    IFS=$'\n' 
    read -d '' -r -a all_users_data_arr < <(printf %s "$usersContent")
    for user_row in "${all_users_data_arr[@]}"; do
        if [[ "$user_row" =~ ^$username:.*$ ]] ; then 
            ps_id=$(echo "$$")
            split_string_to_array "$user_row" ":" user_data_array
            user_data_array[5]="$ps_id"
            user_row=$(IFS=":"; echo "${user_data_array[*]}")  
        fi
        echo "$user_row" >> $passwd_path
    done
    rm $passwd_temp_path
}

#============ end helper functions ============

#============ start script body ============

read -p "Enter username: " username
read -s -p "Enter password: " password
echo
login_user_info=$(get_user_info "$username")

if [[ -n "$login_user_info" ]]; then

    login_user_hash_passwd=$(echo "$login_user_info" | cut -d':' -f2)
    input_hash_passwd=$(hash_password "$password")

    if [[ $login_user_hash_passwd == $input_hash_passwd ]]; then
   
        if ! user_dir_exists "$username" ; then
            mkdir "$engine_dir/.db-engine-users/$username"
            echo
            output_success_message "User directory created successfully"   
        fi
        echo
        echo

        if is_admin_user "$username" ;then 
            admin_info="$username"
            source $script_dir/scripts/admin/main.sh
            output_success_message "Login successful"

        else 

            lock_state=$(echo "$login_user_info" | cut -d ':' -f 4)
            if [[ $lock_state == "1" ]]; then
                set_ps_id "$username"
                loggedInUser="$username"
                PS3=$username"/dbManaging: "
                output_success_message "Login successful"
                source $script_dir/scripts/dbManager/main.sh
            else
                message=$(echo "$login_user_info" | cut -d ':' -f 5)
                output_error_message "Your account is locked"
                output_warning_message "$message"
                echo
            fi

        fi
    else
        output_error_message "Username or password is incorrect"        
    fi

    else
        output_error_message "Username or password is incorrect"        
fi

#============ end script body ============1
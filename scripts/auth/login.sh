#! /usr/bin/bash


#============ start initial information ============

echo
echo "========================== Login ========================="
echo

#============ end initial information ============

#============ start helper functions ============

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

set_ps_id() {
    local username="$1"
    usersContent=$(get_users)
    cat $passwd_path >> $passwd_temp_path
    
    > $passwd_path

    IFS=$'\n' 
    read -d '' -r -a all_users_data_arr < <(printf %s "$usersContent")
    for user_row in "${all_users_data_arr[@]}"; do
        ps_id=$(echo "$$")
        if [[ "$user_row" =~ ^$username:.*$ ]] ; then 
            split_string_to_array "$user_row" ":" user_data_array
            user_data_array[5]="$ps_id"
            user_row=$(IFS=":"; echo "${user_data_array[*]}") 
        elif [[ "${user_data_array[5]}" == "$ps_id" ]] ; then
            user_data_array[5]="null"
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
        user_ps_id=$(echo "$login_user_info" | cut -d ':' -f6)
        user_status=$(is_user_online "$user_ps_id")
        if [[ $user_status == "online" ]]; then
        output_error_message "User is already logged-in in another terminal"
        return
        fi  

        set_ps_id "$username"

        if ! user_dir_exists "$username" ; then
            mkdir "$engine_dir/.db-engine-users/$username"
            echo
            output_success_message "User directory created successfully"   
        fi
        echo
        echo

        if is_admin_user "$username" ;then 
            admin_info="$username"
            output_success_message "Login successful"
            source $script_dir/scripts/admin/main.sh

        else 

            lock_state=$(echo "$login_user_info" | cut -d ':' -f 4)
            if [[ $lock_state == "1" ]]; then
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
#! /usr/bin/bash
#! /usr/bin/bash

#============ start initial information ============

get_users

echo
echo "========================== Change user password ========================="
echo

#============ end initial information ============

#============ start constants ============

passwd_path="$engine_dir/.db-engine-users/.passwd"
passwd_temp_path="$engine_dir/.db-engine-users/.passwd.temp"

#============ end constants ============


#============ start helper functions ============

change_user_password() {
    local username="$1"
    local password="$2"
    touch $passwd_temp_path
    cat $passwd_path >> $passwd_temp_path
    > $passwd_path
    IFS=$'\n' 
    read -d '' -r -a all_users_data_arr < <(printf %s "$usersContent")
    for user_row in "${all_users_data_arr[@]}"; do
        if [[ "$user_row" =~ ^$username:.*$ ]] ; then 
            split_string_to_array "$user_row" ":" user_data_array
            user_data_array[1]="$password"
            user_row=$(IFS=":"; echo "${user_data_array[*]}")  
        fi
        echo "$user_row" >> $passwd_path
    done
    rm $passwd_temp_path
}

#============ end helper functions ============

#============ start script body ============

while true; do
    read -p "Enter username: " username
    if ! user_exists $username; then
        output_error_message "User does not exist. Please enter a valid username."
        continue
    fi
    break
done

read -s -p "Enter password: " u_password
echo

while true;do
    read -s -p "re-enter password: " u_password2
    echo
    if [[ $u_password != $u_password2 ]]; then
    output_error_message "passwords do not match"
    continue
    fi
    break
done

hashed_password=$(hash_password $u_password)

change_user_password $username $hashed_password

output_success_message "Password changed successfully for $username"


#============ end script body ============

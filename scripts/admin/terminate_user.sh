#! /usr/bin/bash
#! /usr/bin/bash

#============ start initial information ============

get_users

echo
echo "========================== Terminate user ========================="
echo

#============ end initial information ============

#============ start constants ============

passwd_path="$engine_dir/.db-engine-users/.passwd"
passwd_temp_path="$engine_dir/.db-engine-users/.passwd.temp"

#============ end constants ============


#============ start helper functions ============

get_user_info() {
    local username="$1"
    local result=$(grep "^$username:" "$engine_dir/.db-engine-users/.passwd")
    echo $result
}

is_user_online() {
    local user_ps=$1
    local all_pr=$(ps aux | grep .*db-engine.sh$ | sed -e 's/\s\+/ /g' | cut -d " " -f 2)
    IFS=$'\n'
    read -d '' -r -a all_ps_array < <(printf %s "$all_pr")
    for ps_value in "${all_ps_array[@]}";do
    if [[ "$ps_value" == "$user_ps" ]];then
        return 0
    fi
    done 
        return 1
}

#============ end helper functions ============

#============ start script body ============

while true; do
    read -p "Enter username: " username
    if [[ "$username" == "exit" ]]; then
        break
    fi
    if ! user_exists $username; then
        output_error_message "User does not exist. Please enter a valid username."
        continue
    fi
    user_data=$(get_user_info $username)
    user_ps=$(echo "$user_data" | cut -d: -f6)
    if is_user_online $user_ps; then
    kill -9 $user_ps
    output_success_message "User has been terminated."
    break
    else
    output_error_message "User is offline."
    fi
done

#============ end script body ============

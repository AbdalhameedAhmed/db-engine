#! /usr/bin/bash
#! /usr/bin/bash

#============ start initial information ============

echo
echo "========================== Terminate user ========================="
echo

#============ end initial information ============

#============ start helper functions ============

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
    output_success_message "User $username has been terminated."
    break
    else
    output_error_message "User $username is offline."
    fi
done

#============ end script body ============

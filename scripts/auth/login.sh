#! /usr/bin/bash


#============ start initial information ============

echo
echo "========================== Login ========================="
echo

#============ end initial information ============

#============ start helper functions ============

hash_password() {
    local password="$1"
    echo -n "$password" | sha256sum | cut -d' ' -f1
}

get_user_info() {
    local username="$1"
    local result=$(grep "^$username:" "$script_dir/scripts/auth/passwd")
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
        output_success_message "Login successful"
        echo
        loggedInUser="$username"
        PS3=$username"/dbManager: "
        source $script_dir/scripts/dbManager/main.sh
    else
        output_error_message "Username or password is incorrect"        
    fi

    else
        output_error_message "Username or password is incorrect"        
fi

#============ end script body ============
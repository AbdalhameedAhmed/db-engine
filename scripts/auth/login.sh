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

        if is_admin_user "$username" ;then 
        admin_info="$username"
        source $script_dir/scripts/admin/main.sh

        else 
        loggedInUser="$username"
        PS3=$username"/dbManaging: "
        source $script_dir/scripts/dbManager/main.sh

        fi
    else
        output_error_message "Username or password is incorrect"        
    fi

    else
        output_error_message "Username or password is incorrect"        
fi

#============ end script body ============
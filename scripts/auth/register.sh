#! /usr/bin/bash

#============ start initial information ============

echo
echo "========================== Register ========================="
echo

#============ end initial information ============

#============ start helper functions ============

# add new user to passwd file
add_new_user() {
    local username="$1"
    local password=$(hash_password "$2")
    if [[ "$register_mode" == "admin" ]]; then
        local userData="$username:$password:1:1:null:null"
        echo "$userData" >> "$engine_dir/.db-engine-users/.passwd"
    else
        local userData="$username:$password:0:1:null:null"
        echo "$userData" >> "$engine_dir/.db-engine-users/.passwd"
    fi
    echo
    output_success_message "$username registered successfully"
    echo
}

# validate username
validate_username() {
    local username="$1"
    if [[ $username =~ ^[a-zA-Z][a-zA-Z0-9]*$ ]]; then
        return 1
    else
        return 0
    fi
}

create_user_dir() {
    local username="$1"
    mkdir "$engine_dir/.db-engine-users/$username"
}

#============ end helper functions ============

#============ start script body ============

while true; do
    read -p "Enter username: " username
    if user_exists $username; then
        output_error_message "Username already exists. Please choose a different username."
        continue
    fi
    if validate_username "$username"; then
        output_error_message "Invalid username. Username must start with a letter and contain only alphanumeric characters."
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

add_new_user $username $u_password 
create_user_dir $username

#============ end script body ============

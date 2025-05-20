#! /usr/bin/bash

#============ start global variables ============

scriptPath=$(realpath "$0")
script_dir=$(dirname "$scriptPath")
engine_dir=$(dirname "$script_dir")
admin_info=""
loggedInUser=""
usersContent=""
auth_options=("Login" "Create new user" "Create new admin" "Exit")
allowed_auth_options=()
PS3='Login/Register:'

#============ end global variables ============

#============ start helper functions ============

source $script_dir/scripts/helpers/helperFunctions.sh
source $script_dir/scripts/helpers/draw_data.sh

add_users_dir(){
    if [[ ! -d "$engine_dir/.db-engine-users" ]] ; then
        mkdir "$engine_dir/.db-engine-users"
    fi
}

add_passwd_file() {
    if [[ ! -f "$engine_dir/.db-engine-users/.passwd" ]] ; then
        touch "$engine_dir/.db-engine-users/.passwd"
    fi
}

get_users() {
    usersContent=$(cat "$engine_dir/.db-engine-users/.passwd")
}

set_allowed_auth_options() {
    # update users content
    get_users

    # reset allowed auth options
    allowed_auth_options=()

    for option in "${auth_options[@]}"; do
        case "$option" in
            "Login")
                if [[ -n "$usersContent" ]]; then
                    allowed_auth_options+=("$option")
                fi
                ;;
            "Create new user")
                if [[ -n "$usersContent" ]]; then
                    allowed_auth_options+=("$option")
                fi
                ;;

            "Create new admin")
                if [[ -z "$usersContent" ]]; then
                    allowed_auth_options+=("$option")
                fi
                ;;
            *)
                allowed_auth_options+=("$option")
                ;;
            esac


    done
}

#============ end helper functions ============

#============ start script body ============

# ensure that the users directory exists
add_users_dir

# ensure that the passwd file exists
add_passwd_file

while true; do

set_allowed_auth_options

    select mode in "${allowed_auth_options[@]}" ; do
        case $mode in
            "Login")
                # login scenario
                source $script_dir/scripts/auth/login.sh
                break
                ;;
            "Create new user")
                # register scenario
                register_mode="normal"
                source $script_dir/scripts/auth/register.sh
                break
                ;;
            "Create new admin")
                # register admin scenario
                register_mode="admin"
                source $script_dir/scripts/auth/register.sh
                break
                ;;
            "Exit")
                exit
                ;;
            *) 
            echo
            output_error_message "invalid option $REPLY"
            echo
            break
            ;;
        esac

    done

done

#============ end script body ============

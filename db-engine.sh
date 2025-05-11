#! /usr/bin/bash

#============ start global variables ============

scriptPath=$(realpath "$0")
script_dir=$(dirname "$scriptPath")
engine_dir=$(dirname "$script_dir")
loggedInUser=""
usersContent=""
auth_options=("Login" "Create new user" "Exit")
allowed_auth_options=()
PS3='Login/Register:'

#============ end global variables ============

#============ start helper functions ============

add_passwd_file() {
    if [[ ! -f "$script_dir/scripts/auth/passwd" ]] ; then
        touch "$script_dir/scripts/auth/passwd"
    fi
}

add_users_dir(){
    if [[ ! -d "$engine_dir/.db-engine-users" ]] ; then
        mkdir "$engine_dir/.db-engine-users"
    fi
}

get_users() {
    usersContent=$(cat "$script_dir/scripts/auth/passwd")
}

set_allowed_auth_options() {
    # update users content
    get_users

    # reset allowed auth options
    allowed_auth_options=()

    for option in "${auth_options[@]}"; do
        if [[ "$option" == "Login" ]] ; then
            if [[ -n "$usersContent" ]]; then
            allowed_auth_options+=("Login")
            fi
        else
            allowed_auth_options+=("$option")
        fi

    done
}

output_success_message() {
    local green='\033[0;32m'
    local normal='\033[0m'
    echo -e "${green}$1${normal}"
}

output_error_message() {
    local red='\033[0;31m'
    local normal='\033[0m'
    echo -e "${red}$1${normal}"
}
#============ end helper functions ============

#============ start script body ============

# ensure that the passwd file exists
add_passwd_file

# ensure that the users directory exists
add_users_dir

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

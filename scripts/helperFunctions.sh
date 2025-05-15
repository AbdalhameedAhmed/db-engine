#! /usr/bin/bash


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

if_table_exist() {
    local table_name=$1
    if [[ -f  $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name ]]; then 
    return 0
    else
    return 1
    fi
}
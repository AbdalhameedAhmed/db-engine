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

remove_extra_spaces() {
    local text="$1"
    text=$(echo "$text" | sed -e 's/\s\+/ /g')
    echo "$text"
}

split_string_to_array() {
  local text="$1"
  local delimiter="$2"
  local array_name="$3"
  IFS="$delimiter" read -ra "$array_name" < <(printf %s "$text")
}
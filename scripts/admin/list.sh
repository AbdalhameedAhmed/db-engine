#! /usr/bin/bash

#============ start global variables ============

all_users=$(cat $engine_dir/".db-engine-users"/.passwd )
green=$'\033[0;32m'  # Use ANSI-C quoting to interpret escape sequences
normal=$'\033[0m' # Use ANSI-C quoting to interpret escape sequences

declare -a headers=("No." "User Name" "Status")
declare -a records=()

#============ end global variables ============

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

      echo "online"
    fi
    done 
    echo "offline"
}

#============ end helper functions ============

#============ start script body ============

if [ -n "$all_users" ]; then 
  counter=0
  while IFS= read -r user_list_name; do
    if [ -n "$user_list_name" ] && ! [[ "$user_list_name" =~ ^$admin_info:.*$ ]]; then 
      counter=$((counter + 1))
      user_name=$(echo "$user_list_name" | cut -d ":" -f 1)
      p_id=$(echo "$user_list_name" | cut -d ":" -f 6)
      user_status=$(is_user_online "$p_id")
      records+=("$counter:$user_name:$user_status") 
    fi
  done <<< "$all_users"
fi
echo
print_dynamic_table "User Listed" headers records

#============ end script body ============
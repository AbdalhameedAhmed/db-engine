#! /usr/bin/bash

all_users_raw=$(ls -F "/home/turbo/.db-engine-users" | grep '/$' | sed 's/\/$//' 2>/dev/null)

declare -a headers=("No." "User Name")
declare -a records=()

if [ -n "$all_users_raw" ]; then 
  counter=0
  while IFS= read -r user_list_name; do
    if [ -n "$user_list_name" ] && [[ "$user_list_name" != "$admin_info" ]]; then 
      counter=$((counter + 1))
      records+=("${counter}:${user_list_name}") 
    fi
  done <<< "$all_users_raw"
fi
echo
print_dynamic_table "User Listed" headers records
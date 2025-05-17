#! /usr/bin/bash

allDbs_raw=$(ls -F "/home/turbo/.db-engine-users/$loggedInUser" | grep '/$' | sed 's/\/$//' 2>/dev/null)

declare -a headers=("No." "Database Name")
declare -a records=()

if [ -n "$allDbs_raw" ]; then 
  counter=0
  while IFS= read -r db_name; do
    if [ -n "$db_name" ]; then 
      counter=$((counter + 1))
      records+=("${counter}:${db_name}") 
    fi
  done <<< "$allDbs_raw"
fi

print_dynamic_table "Databases Listed" headers records
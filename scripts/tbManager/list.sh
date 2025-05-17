#!/usr/bin/bash

#============ start global variables ============
ls_regex="^\s*ls\s*$"
#============ end global variables ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")

if [[ "$sql_code" =~ $ls_regex ]]; then


    all_tables=$(ls -F "$engine_dir/.db-engine-users/$loggedInUser/$connected_db" | grep -v '/$' 2>/dev/null)

    declare -a headers=("No." "Table Name")
    declare -a records=()

    if [ -n "$all_tables" ]; then 
    counter=0
    while IFS= read -r table_name; do
        if [ -n "$table_name" ]; then 
        counter=$((counter + 1))
        records+=("${counter}:${table_name}") 
        fi
    done <<< "$all_tables"
    fi

    print_dynamic_table "Table Listed" headers records

else

    output_error_message "syntax Error! Try to enter a valid query"

fi

shopt -u nocasematch

#============ end script body ============

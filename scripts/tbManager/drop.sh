#! /usr/bin/bash

#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
drop_regex="\s*drop\s+table\s+(${check_name_validity})\s*"

#============ end global variables ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")

if [[ "$sql_code" =~ $drop_regex ]]; then

    table_name="${BASH_REMATCH[1]}"
    echo "$table_name"

    # check if the table exists
    if ! if_table_exist "$table_name" ;then
        output_error_message "Table $table_name does not exist"
        return 
    fi

    rm $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name
    output_success_message "Table $table_name dropped successfully"

else
   output_error_message "syntax Error! Try to enter a valid query" 
fi

shopt -u nocasematch

#============ end script body ============

#! /usr/bin/bash

#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
drop_regex="\s*drop\s+table\s+(${check_name_validity})\s*"

#============ end global variables ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")

if [[ "$sql_code" =~ $drop_regex ]]; then

    syntax_table_name="${BASH_REMATCH[1]}"

    # check if the table exists
    if ! if_table_exist "$syntax_table_name" ;then
        output_error_message "Table $syntax_table_name does not exist"
        return 
    fi

    table_child=$(get_table_child "$syntax_table_name")
    if [[ -n "$table_child" ]]; then
    output_error_message "Cannot drop table $syntax_table_name because it is referenced by a foreign key in table $table_child"
    return
    fi
    echo "$table_child"
    rm $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$syntax_table_name
    output_success_message "Table $syntax_table_name dropped successfully"

else
   output_error_message "syntax Error! Try to enter a valid query" 
fi

shopt -u nocasematch

#============ end script body ============

#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
group_of_cols_regex="\(\s*(${check_name_validity}\s*(,\s*${check_name_validity})*)\s*\)"
group_of_values_regex="\(\s*(([1-9][0-9]*|'[^']*'|null)(\s*,\s*([1-9][0-9]*|'[^']*'|null))*)\s*\)"
sql_insert_regex="\s*insert\s+into\s*([a-zA-Z][a-zA-Z_]*)\s*${group_of_cols_regex}\s*values\s*${group_of_values_regex}"

#============ end global variables ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")
if [[ "$sql_code" =~ $sql_insert_regex ]]; then

    table_name="${BASH_REMATCH[1]}"
    columns="${BASH_REMATCH[2]}"
    values="${BASH_REMATCH[4]}"
    columns=$(echo "$columns" | sed -e 's/\s*,\s*/,/g')
    values=$(echo "$values" | sed -e 's/\s*,\s*/,/g')
    declare -a columns_array=()
    declare -a values_array=()
    split_string_to_array "$columns" "," columns_array
    split_string_to_array "$values" "," values_array
    # check if table exists
    if ! if_table_exist "$table_name" ;then
        output_error_message "Table $table_name does not exist"
        return 
    fi        

    # check if number of columns and values are equal
    if [[ "${#columns_array[@]}" -ne "${#values_array[@]}" ]]; then
        output_error_message "Number of columns does not match number of values"
        return
    fi

    table_cols=$(sed -n '1p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    table_data_types=$(sed -n '2p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    table_constraints=$(sed -n '3p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    split_string_to_array "$table_cols" ":" table_cols_array
    split_string_to_array "$table_data_types" ":" table_data_types_array
    split_string_to_array "$table_constraints" ":" table_constraints_array


    # check if all columns exist in table
    if ! check_all_columns_exist columns_array table_cols_array ;then
        output_error_message "Some columns does not exist in table $table_name"
        return
    fi

    # check if repeated column names
    if check_repeated_column_names columns_array ;then
        output_error_message "Repeated Column Names! Try to enter a valid query"
        return
    fi

    new_insert_data=""
    has_error="false"
    table_column_counter=0
    for table_col in "${table_cols_array[@]}" ; do
        catched_value="null"
        fount_value="false"
        col_counter=0
        for column in "${columns_array[@]}" ; do
            if [[ "$table_col" == "$column" ]]; then

                column_data_type="${table_data_types_array[${table_column_counter}]}"

                # check if data type is valid
                valid_data_type "$column" "${values_array[${col_counter}]}" "$column_data_type"
                validation_error_code=$?
                if [[ "$validation_error_code" -ne 0 ]] ;then
                    print_data_type_errors "$validation_error_code" "$table_name" "$column" "${values_array[${col_counter}]}" "$column_data_type"
                    has_error="true"
                    echo "hello data type $column"
                    break
                fi

                # check on constraints 
                valid_constraints "$column" "${values_array[${col_counter}]}" "${table_constraints_array[${table_column_counter}]}" table_cols_array 
                constraint_error_code=$?
                if [[ "$constraint_error_code" -ne 0 ]] ;then

                    print_constraints_errors $constraint_error_code "$column" "${values_array[${col_counter}]}"
                    has_error="true"
                    break

                fi

                catched_value="${values_array[${col_counter}]}"
                fount_value="true"
                break 
            fi
            ((col_counter++))

        done;

        if [[ "$fount_value" == "false" && "$has_error" == "false" ]]; then
            if ! valid_constraints "$table_col" "$catched_value" "${table_constraints_array[${col_counter}]}" table_cols_array; then
              has_error="true"  
            fi
        fi

        if [[ "$has_error" == "true" ]]; then
            break
        fi


        if [[ "$table_column_counter" == "0" ]] ; then
            new_insert_data="$catched_value"
        else
            new_insert_data="$new_insert_data:$catched_value"                
        fi 
        ((table_column_counter++))
    done;

    # add new values to table
    if [[ "$has_error" == "false" ]]; then
        echo "$new_insert_data" >> $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name
        output_success_message "Data inserted successfully into table '$table_name'."        
    fi

else 

    output_error_message "syntax Error! Try to enter a valid query"

fi
shopt -u nocasematch

#============ end script body ============

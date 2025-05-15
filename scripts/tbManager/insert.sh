#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
group_of_cols_regex="\(\s*(${check_name_validity}\s*(,\s*${check_name_validity})*)\s*\)"
group_of_values_regex="\(\s*(([1-9][0-9]*|'[^']*')(\s*,\s*([1-9][0-9]*|'[^']*'))*)\s*\)"
sql_insert_regex="\s*insert\s+into\s*([a-zA-Z][a-zA-Z_]*)\s*${group_of_cols_regex}\s*values\s*${group_of_values_regex}"

# insert into tableName (first_name,last_name) values ('qwe','qweq')
#============ end global variables ============

#============ start helper functions ============
# extract_column_names() {
#     local syntax="$1"
#     local columnNames=$(echo "$syntax" | grep -oP "$group_of_cols_regex"| sed -e "s/^(//" -e "s/)$//" -e "s/\s*,\s*/,/g")
#     IFS=','
#     read -d '' -r -a syntax_cols_array < <(printf %s "$columnNames")  
# }
check_all_columns_exist() {
    local table_name="$1"
    local -n local_columns_array="$2"
    local -n local_table_cols_array="$3"
    local exists_cols_array=()
    local counter=0

    for column in "${local_columns_array[@]}"; do
        counter=$((counter+1))
        for table_col in "${local_table_cols_array[@]}"; do
            if [[ "$column" == "$table_col" ]]; then
                exists_cols_array+=("$column")
            fi
        done 
        if [[ "${#exists_cols_array[@]}" -ne "$counter" ]]; then
            return 1
        fi        
    done
    return 0
}

check_repeated_column_names() {
    local -n local_cols_array="$1"
    local -a seen=()   
    for col in "${local_cols_array[@]}"; do
        if [[ " ${seen[*]} " =~ " ${col} " ]]; then
            return 0
        else
            seen+=("$col")
        fi
    done
    return 1
}

valid_data_type(){
    local column_value="$1"
    local data_type="$2"
    local column_name="$3"

    if [[ "$data_type" == "int" ]]; then
            if [[ "$column_value" =~ ^[0-9]+$ ]] ; then
                return 0
            else
                output_error_message "Data type mismatch for column '$column_name'. Value '${column_value}' is not a valid integer."

                return 1
            fi

    elif [[ "$data_type" =~ varchar\(([1-9][0-9]*)\) ]]; then

        local varchar_size="${BASH_REMATCH[1]}"
        local number_of_chars="${#column_value}"
        if [[ "$number_of_chars" -ge "$varchar_size" ]]; then
            output_error_message "Value for column '$column_name' ('${column_value}') exceeds maximum size of $varchar_size for type '$data_type'."
        return 1

        fi
        if [[ "$column_value" =~ \'[^\']*\' ]];  then
        return 0
        else 
            output_error_message "Value for column '$column_name' ('${column_value}') must be a string enclosed in single quotes for type '$data_type'."
        return 1
        fi

    fi
}
#============ end helper functions ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")
if [[ "$sql_code" =~ $sql_insert_regex ]]; then

    table_name="${BASH_REMATCH[1]}"
    columns="${BASH_REMATCH[2]}"
    values="${BASH_REMATCH[4]}"
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
    split_string_to_array "$table_cols" ":" table_cols_array
    split_string_to_array "$table_data_types" ":" table_data_types_array


    # check if all columns exist in table
    if ! check_all_columns_exist "$table_name" columns_array table_cols_array ;then
        output_error_message "Some columns does not exist in table $table_name"
    fi

    # check if repeated column names
    if check_repeated_column_names columns_array ;then
        output_error_message "Repeated Column Names! Try to enter a valid query"
    fi

    echo "${table_cols_array[0]}"
    new_insert_data=""
    has_error="false"
    for table_col in "${table_cols_array[@]}" ; do
        found_value="false"
        col_counter=0
        for column in "${columns_array[@]}" ; do
            if [[ "$table_col" == "$column" ]]; then
                found_value="true"
                column_data_type="${table_data_types_array[${col_counter}]}"

                # check if data type is valid

                if ! valid_data_type "${values_array[${col_counter}]}" "$column_data_type" "$column";then
                    has_error="true"
                    break
                fi

                if [[ -z "$new_insert_data" ]] ; then
                    new_insert_data="${values_array[${col_counter}]}"
                else
                    new_insert_data="$new_insert_data:${values_array[${col_counter}]}"                
                fi 
            fi
            ((col_counter++))

        done;
        if [[ "$has_error" == "true" ]]; then
            break
        fi
        if [[ "$found_value" == "false" ]]; then
            new_insert_data="$new_insert_data:null"
        fi



    done;
    if [[ "$has_error" == "false" ]]; then
        echo "$new_insert_data" >> $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name
        output_success_message "Data inserted successfully into table '$table_name'."        
    fi

else 

    output_error_message "syntax Error! Try to enter a valid query"

fi
shopt -u nocasematch

#============ end script body ============

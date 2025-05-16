#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
group_of_cols_regex="\(\s*(${check_name_validity}\s*(,\s*${check_name_validity})*)\s*\)"
group_of_values_regex="\(\s*(([1-9][0-9]*|'[^']*'|null)(\s*,\s*([1-9][0-9]*|'[^']*'|null))*)\s*\)"
sql_insert_regex="\s*insert\s+into\s*([a-zA-Z][a-zA-Z_]*)\s*${group_of_cols_regex}\s*values\s*${group_of_values_regex}"

# insert into tableName (first_name,last_name) values ('qwe','qweq')
#============ end global variables ============

#============ start helper functions ============

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
    local column_name="$1"
    local column_value="$2"
    local data_type="$3"

    if [[ "$data_type" == "int" ]]; then
            if [[ "$column_value" == "null" ]];then
                return 0
            elif [[ "$column_value" =~ ^[0-9]+$ ]] ; then
                return 0
            else

                return 1
            fi

    elif [[ "$data_type" =~ varchar\(([1-9][0-9]*)\) ]]; then

        local varchar_size="${BASH_REMATCH[1]}"
        local number_of_chars="${#column_value}"
        if [[ "$column_value" == "null" ]];then
            return 0
        fi
        if [[ "$number_of_chars" -ge "$varchar_size" ]]; then
        return 2
        fi
        if [[ "$column_value" =~ \'[^\']*\' ]];  then
        return 0
        else 
        return 3
        fi

    fi
}

print_data_type_errors() {
    local error_code="$1"
    local table_name="$2"
    local column_name="$3"
    local column_value="$4"
    local data_type="$5"
    case $error_code in
    "1")
        output_error_message "Data type mismatch for column '$column_name'. Value '${column_value}' is not a valid integer."
    ;;
    "2")
    if [[ "$data_type" =~ varchar\(([1-9][0-9]*)\) ]]; then
    local varchar_size="${BASH_REMATCH[1]}"
        output_error_message "Value for column '$column_name' ('${column_value}') exceeds maximum size of $varchar_size for type '$data_type'."
    fi
    ;;
    "3")
        output_error_message "Value for column '$column_name' (${column_value}) must be a string enclosed in single quotes for type '$data_type'."
    ;;
    esac
}

get_column_order() {
    local column_name="$1"
    local -n column_names_array_order="$2"
    local counter=1
    for column in "${column_names_array_order[@]}"; do
        if [[ "$column_name" == "$column" ]]; then
            echo "$counter"
            return
        fi
        ((counter++))
    done
}

check_is_pk() {
    local column_name="$1"
    local column_value="$2"
    local -n pk_column_names_array="$3"
    local column_order=$(get_column_order "$column_name" pk_column_names_array)
    local table_data=$(tail -n +4 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name | cut -d : -f $column_order)
    local -a lines
    IFS=$'\n'
    read -d '' -r -a lines <<< "$table_data"
    for line in "${lines[@]}"; do
        if [[ "$line" == "$column_value" ]]; then
            return 1
        fi
    done
    return 0 
}

check_is_nn() {
    local column_value="$1"
    if [[ "$column_value" == "null" ]];then
        return 1
    else
        return 0
    fi
}

valid_constraints(){
    local column_name="$1"
    local column_value="$2"
    local constraints="$3"
    local -n local_column_names_array="$4"

    if [[ "$constraints" == "pk" ]]; then 
        if [[ "$column_value" == "null" ]];then
            return 1
        elif ! check_is_pk "$column_name" "$column_value" local_column_names_array;then
            return 2
        else
            return 0
        fi
    elif [[ "$constraints" =~ fk.+ ]];then
        return 0
    else
        split_string_to_array "$constraints" "," constraints_array
        for constraint in "${constraints_array[@]}"; do
        echo "check on constraint $constraint  ${constraints_array[@]}"
            case "$constraint" in
                "nn")
                if check_is_nn "$column_value"; then
                    continue 
                else
                    return 3
                fi
                ;;
                "unique")
                if ! check_is_nn "$column_value" ;then
                    return 4

                elif ! check_is_pk "$column_name" "$column_value" local_column_names_array ;then
                    return 5
                else
                    continue
                fi
                ;;
            esac
        done
        return 0
    fi

}

print_constraints_errors() {
    local error_code="$1"
    local column_name="$2"
    local column_value="$3"

    case $error_code in
    "1")
        output_error_message "Primary key column '$column_name' cannot be null."
    ;;
    "2")
        output_error_message "Primary key '$column_value' already exists."
    ;;
    "3")
        output_error_message "Not null constraint violated for column '$column_name'."
    ;;
    "4")
        output_error_message "Unique constraint violated for column '$column_name'. Value '$column_value' cannot be null."
    ;;
    "5")
        output_error_message "Unique constraint violated for column '$column_name'. Value '$column_value' already exists."
    ;;
    esac
    
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
    table_constraints=$(sed -n '3p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    split_string_to_array "$table_cols" ":" table_cols_array
    split_string_to_array "$table_data_types" ":" table_data_types_array
    split_string_to_array "$table_constraints" ":" table_constraints_array


    # check if all columns exist in table
    if ! check_all_columns_exist "$table_name" columns_array table_cols_array ;then
        output_error_message "Some columns does not exist in table $table_name"
    fi

    # check if repeated column names
    if check_repeated_column_names columns_array ;then
        output_error_message "Repeated Column Names! Try to enter a valid query"
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

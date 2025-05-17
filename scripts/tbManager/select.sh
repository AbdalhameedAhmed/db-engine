#! /usr/bin/bash

#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
check_value_validity="([1-9][0-9]*|'[^']*'|null)"
select_regex="\s*select\s+(\*|${check_name_validity}(\s*,\s*${check_name_validity})*)\s+from\s+(${check_name_validity})\s*(\s+where\s+(${check_name_validity}\s*(=|>|<|!=)\s*${check_value_validity})\s*)?$"

#============ start global variables ============

#============ start helper functions ============

#============ end helper functions ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")

if [[ "$sql_code" =~ $select_regex ]]; then

    table_name="${BASH_REMATCH[3]}"
    columns="${BASH_REMATCH[1]}"
    if [[ "$columns" != "*" ]]; then
        columns=$(echo "$columns" | sed 's/\s*,\s*/,/g')
        declare -a columns_array=()
        split_string_to_array "$columns" "," columns_array
    fi
    where_condition="${BASH_REMATCH[5]}"
    condition_operator="${BASH_REMATCH[6]}"
    
    # check if the table exists
    if ! if_table_exist "$table_name" ;then
        output_error_message "Table $table_name does not exist"
        return 
    fi

    table_cols=$(sed -n '1p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    table_data_types=$(sed -n '2p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    table_constraints=$(sed -n '3p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    declare -a table_cols_array=()
    declare -a table_data_types_array=()
    declare -a table_constraints_array=()
    split_string_to_array "$table_cols" ":" table_cols_array
    split_string_to_array "$table_data_types" ":" table_data_types_array
    split_string_to_array "$table_constraints" ":" table_constraints_array

    # check on repeated column names
    if [[ "$columns" != "*" ]] && check_repeated_column_names columns_array ;then
        output_error_message "Repeated Column Names! Try to enter a valid query"
        return
    fi

    # check if all columns exist in table
    if [[ "$columns" != "*" ]] && ! check_all_columns_exist columns_array table_cols_array ;then
        output_error_message "Some columns does not exist in table $table_name, Try to enter a valid query"
        return
    fi

    # condition part
    if [[ -n "$where_condition" ]];then

        where_condition=$(echo "$where_condition" | sed 's/\s*'"$condition_operator"'\s*/'"$condition_operator"'/')
        where_left_value=$(echo "$where_condition" | cut -d$condition_operator -f1)
        where_right_value=$(echo "$where_condition" | cut -d$condition_operator -f2)
        declare -a condition_column_array=()
        condition_column_array+=("$where_left_value")

        if ! check_all_columns_exist condition_column_array table_cols_array ;then
            output_error_message "Column '$where_left_value' in the where condition does not exist in table $table_name, Try to enter a valid query"
            return
        fi 

        # check the validity of data type in the where condition
        where_column_order=$(get_column_order "$where_left_value" table_cols_array)
        ((where_column_order--))
        where_column_data_type="${table_data_types_array[${where_column_order}]}"
        valid_data_type "$where_left_value" "$where_right_value" "$where_column_data_type"
        validation_error_code=$?
        if [[ "$validation_error_code" -ne 0 ]]; then 
            print_condition_data_type_errors "$validation_error_code" "$table_name" "$where_left_value" "$where_right_value" "$where_column_data_type" 
            return
        fi

        # check the validity of the comparison operator
        if [[ "$where_column_data_type" != "int" ]] && [[ "$condition_operator" != "=" && "$condition_operator" != "!=" ]] ;then
            output_error_message "Invalid condition operator '$condition_operator' for non-integer data type '$where_column_data_type'. Only '=' or '!=' are allowed."
            return
        fi

    fi

    table_content=$(tail -n +4 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    declare -a table_content_arr=()
    declare -a table_columns_for_print_arr=()
    table_columns_for_print_arr["0"]="No."
    counter=1

    if [[ "$columns" == "*" ]]; then
        for col_name in "${table_cols_array[@]}"; do
            table_columns_for_print_arr[${counter}]="$col_name"
            ((counter++))
        done
        
    else
        for col_name in "${columns_array[@]}"; do
            table_columns_for_print_arr[${counter}]="$col_name"
            ((counter++))
        done
    fi

    echo "${table_columns_for_print_arr[@]}"
    declare -a table_content_for_print_arr=()
    IFS=$'\n' 
    read -d '' -r -a table_content_arr < <(printf %s "$table_content")

    where_column_order_num=$((where_column_order+1))
    number_of_selected_rows=0  
    counter=1  
    for table_content_line in "${table_content_arr[@]}";do
    table_line_condition_value=$(echo "$table_content_line" | cut -d : -f $where_column_order_num)
    split_string_to_array "$table_content_line" ":" line_arr
    if [[ -z "$where_condition" ]] || 
        [[ "$condition_operator" == "=" && "$table_line_condition_value" == "$where_right_value" ]] ||
        [[ "$condition_operator" == "!=" && "$table_line_condition_value" != "$where_right_value" ]] ||
        [[ "$condition_operator" == ">" && "$table_line_condition_value" -gt "$where_right_value" ]] ||
        [[ "$condition_operator" == "<" && "$table_line_condition_value" -lt "$where_right_value" ]]; then

        set_value_counter=0
        for selected_col in "${table_columns_for_print_arr[@]}"; do
        if [[ "$set_value_counter" == "0" ]];then
            table_content_line="$counter"
            ((set_value_counter++))
            else 
            column_order=$(get_column_order "$selected_col" table_cols_array)
            ((column_order--))
            table_content_line+=":${line_arr[$column_order]}"
        fi
        done
        table_content_for_print_arr[${number_of_selected_rows}]="$table_content_line"
    ((counter++))
    ((number_of_selected_rows++))
    fi
    done
    # start select data from the table    
    print_dynamic_table "$table_name (${number_of_selected_rows} rows)" table_columns_for_print_arr table_content_for_print_arr



else 

    output_error_message "syntax Error! Try to enter a valid query"

fi

shopt -u nocasematch

#============ end script body ============


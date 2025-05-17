#! /usr/bin/bash

#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
check_value_validity="([1-9][0-9]*|'[^']*'|null)"
delete_regex="\s*delete\s+from\s+(${check_name_validity})\s*(\s+where\s+(${check_name_validity}\s*(=|>|<|!=)\s*${check_value_validity})\s*)?$"

#============ end global variables ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")

if [[ "$sql_code" =~ $delete_regex ]]; then

    table_name="${BASH_REMATCH[1]}"
    where_condition="${BASH_REMATCH[3]}"
    condition_operator="${BASH_REMATCH[4]}"
    
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


    if [[ -n "$where_condition" ]];then

        where_condition=$(echo "$where_condition" | sed 's/\s*'"$condition_operator"'\s*/'"$condition_operator"'/')
        where_left_value=$(echo "$where_condition" | cut -d$condition_operator -f1)
        where_right_value=$(echo "$where_condition" | cut -d$condition_operator -f2)
        declare -a condition_column_array=()
        condition_column_array+=("$where_left_value")

        # check if the column in the condition is exist in the table
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

    temp_file_path=$engine_dir/".db-engine-users"/$loggedInUser/$connected_db/.${table_name}.temp
    table_file_path=$engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name

    cat $table_file_path >> $temp_file_path   

    table_meta_data=$(head -n 3 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    table_content=$(tail -n +4 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    > $table_file_path

    echo "$table_meta_data" >> $table_file_path   
    
    IFS=$'\n' 
    read -d '' -r -a table_content_arr < <(printf %s "$table_content")

    where_column_order_num=$((where_column_order+1))
    number_of_deleted_rows=0

    for table_content_line in "${table_content_arr[@]}"; do

        table_line_condition_value=$(echo "$table_content_line" | cut -d : -f $where_column_order_num)

        if [[ -z "$where_condition" ]] || 
        [[ "$condition_operator" == "=" && "$table_line_condition_value" == "$where_right_value" ]] ||
        [[ "$condition_operator" == "!=" && "$table_line_condition_value" != "$where_right_value" ]] ||
        [[ "$condition_operator" == ">" && "$table_line_condition_value" -gt "$where_right_value" ]] ||
        [[ "$condition_operator" == "<" && "$table_line_condition_value" -lt "$where_right_value" ]]; then
            ((number_of_deleted_rows++))
        else
        echo "$table_content_line" >> $table_file_path  
        fi

    done
    
    output_success_message "Data deleted successfully in $number_of_deleted_rows rows in table '$table_name'."
    rm $temp_file_path

else 
    output_error_message "syntax Error! Try to enter a valid query"
fi

shopt -u nocasematch

#============ end script body ============


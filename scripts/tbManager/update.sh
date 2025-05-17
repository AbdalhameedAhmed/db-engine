#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
check_value_validity="([1-9][0-9]*|'[^']*'|null)"
update_regex="^\s*update\s+(${check_name_validity})\s+set\s+(${check_name_validity}\s*=\s*${check_value_validity}*\s*(\s*,\s*${check_name_validity}\s*=\s*${check_value_validity})*)\s*(\s+where\s+(${check_name_validity}\s*(=|>|<|!=)\s*${check_value_validity})\s*)?$"

#============ end global variables ============

#============ start helper functions ============

extract_col_data() {

text="$1"
local -n f_arr="$2"
local -n l_arr="$3"
text=$(echo "$text" | grep -oP "[a-zA-Z][a-zA-Z_]*\s*=\s*([1-9][0-9]*|'[^']*'|null)")
IFS=$'\n'
read -d '' -r -a text_arr <<< "$text" 
counter=0
for line in "${text_arr[@]}"; do
    line=$(echo "$line" | sed 's/\s*=\s*/=/1')
    col_name=$(echo "$line" | cut -d '=' -f 1)
    col_val=$(echo "$line" | cut -d '=' -f 2)
    f_arr[$counter]="$col_name"
    l_arr[$counter]="$col_val"    
    ((counter++))
done
}

#============ end helper functions ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(remove_extra_spaces "$sql_code")
if [[ "$sql_code" =~ $update_regex ]]; then
    table_name="${BASH_REMATCH[1]}"
    values_to_update="${BASH_REMATCH[2]}"
    where_condition="${BASH_REMATCH[7]}"
    condition_operator="${BASH_REMATCH[8]}"
    
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
    declare -a syntax_col_names_arr=()
    declare -a syntax_values_arr=()
    
    extract_col_data "$values_to_update" syntax_col_names_arr syntax_values_arr
    if check_repeated_column_names syntax_col_names_arr ;then
        output_error_message "Repeated Column Names! Try to enter a valid query"
        return
    fi
    
    # check if all columns exist in table
    if ! check_all_columns_exist syntax_col_names_arr table_cols_array ;then
        output_error_message "Some columns does not exist in table $table_name, Try to enter a valid query"
        return
    fi

    counter=0
    for syntax_col_name in "${syntax_col_names_arr[@]}"; do
        column_order=$(get_column_order "$syntax_col_name" table_cols_array)
        ((column_order--))
        column_data_type="${table_data_types_array[${column_order}]}"

        # check on the validty of data types
        valid_data_type "$syntax_col_name" "${syntax_values_arr[${counter}]}" "$column_data_type"
        validation_error_code=$?
        if [[  "$validation_error_code" -ne 0 ]];then 
        print_data_type_errors "$validation_error_code" "$table_name" "$syntax_col_name" "${syntax_values_arr[${counter}]}" "$column_data_type"
        return
        fi

        # check on constraints
        valid_constraints "$syntax_col_name" "${syntax_values_arr[${counter}]}" "${table_constraints_array[${column_order}]}" table_cols_array
        constraint_error_code=$?
        if [[  "$constraint_error_code" -ne 0 ]];then 
        print_constraints_errors "$constraint_error_code" "$syntax_col_name" "${syntax_values_arr[${counter}]}"
        print_constraints_errors "Error while check on constarint"
        return
        fi

        ((counter++))

    done

    # condition part
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

    # start update data in the table    
    temp_file_path=$engine_dir/".db-engine-users"/$loggedInUser/$connected_db/${table_name}.temp
    table_file_path=$engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name

    cat $table_file_path >> $temp_file_path   

    table_meta_data=$(head -n 3 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    table_content=$(tail -n +4 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    > $table_file_path

    echo "$table_meta_data" >> $table_file_path   
    
    IFS=$'\n' 
    read -d '' -r -a table_content_arr < <(printf %s "$table_content")

    where_column_order_num=$((where_column_order+1))
    number_of_updated_rows=0
    for table_content_line in "${table_content_arr[@]}"; do
        table_line_condition_value=$(echo "$table_content_line" | cut -d : -f $where_column_order_num)
        split_string_to_array "$table_content_line" ":" line_arr
        if [[ -z "$where_condition" ]] || 
        [[ "$condition_operator" == "=" && "$table_line_condition_value" == "$where_right_value" ]] ||
        [[ "$condition_operator" == "!=" && "$table_line_condition_value" != "$where_right_value" ]] ||
        [[ "$condition_operator" == ">" && "$table_line_condition_value" -gt "$where_right_value" ]] ||
        [[ "$condition_operator" == "<" && "$table_line_condition_value" -lt "$where_right_value" ]]; then
            number_of_updated_rows=$((number_of_updated_rows+1)) 
            counter=0
            for syntax_col_name in "${syntax_col_names_arr[@]}"; do
                syntax_col_name_order=$(get_column_order "$syntax_col_name" table_cols_array)
                ((syntax_col_name_order--))
                new_value="${syntax_values_arr[${counter}]}"
                line_arr[$syntax_col_name_order]="$new_value"
                ((counter++))
            done
        fi


        counter=0
        if [[ "$number_of_updated_rows" == "2" ]]; then 

        for line_here in "${line_arr[@]}"; do
            valid_constraints "${table_cols_array[${counter}]}" "$line_here" "${table_constraints_array[${counter}]}" table_cols_array
            constraint_error_code=$?
            if [[  "$constraint_error_code" -ne 0 ]];then
            output_error_message "Error while updating data"
            print_constraints_errors "$constraint_error_code" "${table_cols_array[${counter}]}" "$line_here"
            > $table_file_path
            cat $temp_file_path >> $table_file_path
            rm $temp_file_path
            return
            fi
            ((counter++))
        done
        fi
        table_content_line=$(IFS=":"; echo "${line_arr[*]}")  
        echo "$table_content_line" >> $table_file_path  
    done
    output_success_message "Data updated successfully in $number_of_updated_rows rows in table '$table_name'."
    rm $temp_file_path
else
    output_error_message "syntax Error! Try to enter a valid query"
fi

shopt -u nocasematch

#============ end script body ============

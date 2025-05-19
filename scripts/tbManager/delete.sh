#! /usr/bin/bash

#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
check_value_validity="([1-9][0-9]*|'[^']*'|null)"
delete_regex="\s*delete\s+from\s+(${check_name_validity})\s*(\s+where\s+(${check_name_validity}\s*(=|>|<|!=)\s*${check_value_validity})\s*)?$"

#============ end global variables ============

#============ start helper functions ============

get_pk_order(){
    local -n const_arr="$1"
    for const_val in "${const_arr[@]}"; do
        if [[ "$const_val" == "pk" ]]; then
            local pk_order=$(get_column_order "$const_val" const_arr)
            echo "$pk_order"
            return
        fi
    done
    echo ""
    return
}


if_pk_value_used_as_foreign_key() {
    local fk_reference_table=$1
    local pk_value=$2
    local foreign_key_regex="\s*fk\s*,\s*([a-zA-Z][a-zA-Z_]*)\s*,\s*([a-zA-Z][a-zA-Z_]*)"
    all_tables=$(ls -F "$engine_dir/.db-engine-users/$loggedInUser/$connected_db" | grep -v '/$' 2>/dev/null)
    while IFS= read -r table_name; do
        if [ -n "$table_name" ] && [[ "$table_name" != "$fk_reference_table" ]]; then 
            local table_constraints=$(sed -n '3p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
            declare -a constraints_array
            split_string_to_array "$table_constraints" ":" constraints_array
            counter=1
            for constraint in "${constraints_array[@]}"; do
                if [[ "$constraint" =~ $foreign_key_regex ]]; then
                    local fk_table_name="${BASH_REMATCH[1]}"
                    if [[ "$fk_table_name" == "$fk_reference_table" ]]; then

                        table_content=$(tail -n +4 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name | cut -d : -f $counter)
                        while IFS= read -r table_fk_value; do
                            if [[ "$table_fk_value" == "$pk_value" ]]; then
                                return 0
                            fi
                        done <<< "$table_content"
                    fi
                fi
                ((counter++))
            done
        fi
    done <<< "$all_tables"
    return 1
}

#============ end helper functions ============

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

    # start delete data from the table    

    # check if table is referenced by a foreign key
    table_child=$(get_table_child "$table_name")
    
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

            if [[ -n "$table_child" ]];then 
                pk_order=$(get_pk_order table_constraints_array)
                pk_value=$(echo "$table_content_line" | cut -d : -f $pk_order)

                if if_pk_value_used_as_foreign_key "$table_name" "$pk_value" ; then

                    output_error_message "Cannot delete row because its primary key value is referenced as a foreign key in table $table_child"
                    > $table_file_path
                    cat $temp_file_path >> $table_file_path
                    rm $temp_file_path
                    return
                fi
            else
                ((number_of_deleted_rows++))
            fi

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


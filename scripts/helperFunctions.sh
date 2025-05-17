#! /usr/bin/bash


output_success_message() {
    local green='\033[0;32m'
    local normal='\033[0m'
    echo -e "${green}$1${normal}"
}

output_error_message() {
    local red='\033[0;31m'
    local normal='\033[0m'
    echo -e "${red}$1${normal}"
}

if_table_exist() {
    local table_name=$1
    if [[ -f  $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name ]]; then 
    return 0
    else
    return 1
    fi
}

remove_extra_spaces() {
    local text="$1"
    text=$(echo "$text" | sed -e 's/\s\+/ /g')
    echo "$text"
}

split_string_to_array() {
  local text="$1"
  local delimiter="$2"
  local array_name="$3"
  IFS="$delimiter" read -ra "$array_name" < <(printf %s "$text")
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

check_all_columns_exist() {
    local -n local_columns_array="$1"
    local -n local_table_cols_array="$2"
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
        output_error_message "Unique constraint violated for column $column_name. Value '$column_value' cannot be null."
    ;;
    "5")
        output_error_message "Unique constraint violated for column $column_name. Value '$column_value' already exists."
    ;;
    esac
    
}
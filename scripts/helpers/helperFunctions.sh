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

output_important_message() {
    local blue='\033[0;34m'
    local normal='\033[0m'
    echo -e "${blue}$1${normal}"
}

output_warning_message() {
    local yellow='\033[0;33m'
    local normal='\033[0m'
    echo -e "${yellow}$1${normal}"
}

# get all users from passwd file
get_users() {
    usersContent=$(cat "$passwd_path")
    echo "$usersContent"
}

# check if user exists
user_exists() {
    local username="$1"
    local result=$(grep "^$username:" "$passwd_path")
    if [[ -n $result ]]; then
        return 0
    else
        return 1
    fi
}

# get user info from .passwd file
get_user_info() {
    local username="$1"
    local user_info=$(grep "^$username:" $passwd_path)
    echo $user_info
}

# for hashing password
hash_password() {
    local password="$1"
    echo -n "$password" | sha256sum | cut -d' ' -f1
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
        ((number_of_chars-=2)) # remove the two single quotes
        if [[ "$column_value" == "null" ]];then
            return 0
        fi
        if [[ "$number_of_chars" -gt "$varchar_size" ]]; then
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

check_is_valid_fk_value() {
    local fk_reference_table=$1
    local fk_reference_column=$2
    local fk_value=$3
    local reference_table_columns=$(sed -n '1p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$fk_reference_table)
    split_string_to_array "$table_cols" ":" fk_table_cols_array
    local pk_column_order=$(get_column_order "$fk_reference_column" fk_table_cols_array)
    local table_data=$(tail -n +4 $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$fk_reference_table | cut -d : -f $pk_column_order)
    local -a record_arr=()
    IFS=$'\n'
    read -d '' -r -a record_arr <<< "$table_data"
    for line in "${record_arr[@]}"; do
        if [[ "$line" == "$fk_value" ]]; then
            return 0
        fi
    done
    return 1
}

valid_constraints(){
    local column_name=$1
    local column_value=$2
    local constraints=$3
    local -n local_column_names_array="$4"
    local foreign_key_regex="\s*fk\s*,\s*([a-zA-Z][a-zA-Z_]*)\s*,\s*([a-zA-Z][a-zA-Z_]*)"
    if [[ "$constraints" == "pk" ]]; then 
        if [[ "$column_value" == "null" ]];then
            return 1
        elif ! check_is_pk "$column_name" "$column_value" local_column_names_array;then
            return 2
        else
            return 0
        fi
    elif [[ "$constraints" =~ $foreign_key_regex ]];then
        local fk_table_name="${BASH_REMATCH[1]}"
        local fk_column_name="${BASH_REMATCH[2]}"
        if ! check_is_valid_fk_value "$fk_table_name" "$fk_column_name" "$column_value" ; then 
        return 6
        else
        return 0
        fi
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
    "6")
        output_error_message "Foreign key constraint violated for column '$column_name'. Value '$column_value' does not exist in the referenced table as a primary key."
    ;;
    esac
    
}


print_condition_data_type_errors() {

    local error_code="$1"
    local table_name="$2"
    local column_name="$3"
    local column_value="$4"
    local data_type="$5"
    case $error_code in
    "1")
        output_error_message "Data type mismatch in the where condition for column '$column_name'. Value ${column_value} is not a valid integer."
    ;;
    "3")
        output_error_message "Value for column '$column_name' (${column_value}) must be a string enclosed in single quotes for type '$data_type'."
    ;;
    esac
}


get_table_child() {
    local fk_reference_table=$1
    local foreign_key_regex="\s*fk\s*,\s*([a-zA-Z][a-zA-Z_]*)\s*,\s*([a-zA-Z][a-zA-Z_]*)"
    all_tables=$(ls -F "$engine_dir/.db-engine-users/$loggedInUser/$connected_db" | grep -v '/$' 2>/dev/null)
    while IFS= read -r table_name; do
        if [ -n "$table_name" ] && [[ "$table_name" != "$fk_reference_table" ]]; then 
            local table_constraints=$(sed -n '3p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
            declare -a constraints_array
            split_string_to_array "$table_constraints" ":" constraints_array
            for constraint in "${constraints_array[@]}"; do
                if [[ "$constraint" =~ $foreign_key_regex ]]; then
                    local fk_table_name="${BASH_REMATCH[1]}"
                    if [[ "$fk_table_name" == "$fk_reference_table" ]]; then
                        echo "$table_name"
                        return
                    fi
                fi
            done
        fi
    done <<< "$all_tables"
    echo ""
    return
}

is_user_online() {

    local user_ps="$1"
    if [[ "$user_ps" -eq "null" ]]; then
        echo "offline"
        return
    fi

    local all_pr=$(ps aux | grep .*db-engine.sh$ | sed -e 's/\s\+/ /g' | cut -d " " -f 2)
    IFS=$'\n'
    read -d '' -r -a all_ps_array < <(printf %s "$all_pr")
    
    for ps_value in "${all_ps_array[@]}";do
    if [[ "$ps_value" == "$user_ps" ]];then
      echo "online"
      return
    fi
    done 
    echo "offline"
}
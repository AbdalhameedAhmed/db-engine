#! /usr/bin/bash

#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
check_column_type='(int|varchar\([1-9][0-9]*\))'
check_constraint="(\s+primary key|\s+(references\s+[a-zA-Z][a-zA-Z_]*\s+\([a-zA-Z][a-zA-Z_]*\))|(\s+unique|\s+not null)*)"
sql_create_regex="^\s*create\s+table\s+${check_name_validity}\s+\(\s*${check_name_validity}\s+${check_column_type}\s*${check_constraint}?\s*(,\s*${check_name_validity}\s+${check_column_type}\s*${check_constraint}?\s*)*\)$"

#============ end global variables ============

#============ start helper functions ============

get_table_name() {
    local sql_code=$1
    local table_name=""
    table_name=$(echo $sql_code | cut -d" " -f3)
    echo "$table_name"
}

extract_column_data() {
    local sql_code=$1
    local column_data=""
    local column_data_without_parenthesis=""
    column_data=$(echo "$sql_code" | grep -o "(.*)" | sed -e "s/^(//" -e "s/)$//" -e "s/,/\n/g")
    column_data=$(echo "$column_data" | sed -e "s/^\s*//")
    echo "$column_data"
}

extract_column_names(){
    local column_data=$1
    local column_names=""
    column_names=$(awk 'begin {allData = "";FS=" ";}{if (allData == "") {allData=$1}else {allData=allData":"$1}}END {print allData}' <<<$column_data)
    echo "$column_names"
}

extract_column_types() {
    local column_data=$1
    local column_types=""
    column_types=$(awk 'begin {allData = "";FS=" ";}{if (allData == "") {allData=$2}else {allData=allData":"$2}}END {print allData}' <<<$column_data)
    echo "$column_types"
}

check_repeated_column_names() {
 local column_data=$1
    local column_names=""
    column_names=$(awk '{print $1}' <<< "$column_data")

    local -a lines       # Declare 'lines' as a local array
    local old_ifs="$IFS" # Save the current Internal Field Separator
    IFS=$'\n'            # Set IFS to newline for the 'read' command
    read -d '' -r -a lines <<< "$column_names" # Populate the 'lines' array
    IFS="$old_ifs"       # Restore the original IFS

    local -a seen=()     # Declare 'seen' as a local array, good practice
    local line           # Declare 'line' as a local variable for the loop
    for line in "${lines[@]}"; do
        if [[ " ${seen[*]} " =~ " ${line} " ]]; then
            return 0
        else
            seen+=("$line")
        fi
    done
    return 1
}

check_repeated_constraints() {
  local fullText="$1"
  local primary_count=0 
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local -a words
    local word
    local IFS=' '

    local not_count=0
    local null_count=0
    local unique_count=0

    words=($line) # Split the line into an array of words

    for word in "${words[@]}"; do
      case "$word" in
        "primary")
          ((primary_count++))
          if [[ "$primary_count" -gt 1 ]]; then
            return 0 
          fi
          ;;
        "not")
          ((not_count++))
          if [[ "$not_count" -gt 1 ]]; then
            return 0 
          fi
          ;;
        "null")
          ((null_count++))
          if [[ "$null_count" -gt 1 ]]; then
            return 0
          fi
          ;;
        "unique")
          ((unique_count++))
          if [[ "$unique_count" -gt 1 ]]; then
            return 0 
          fi
          ;;
      esac
    done
  done <<< "$fullText" # Corrected: use here-string to pass variable content

  return 1 # Return 0 (success/no repetition)
}

extract_column_Constraints() {
    local column_data=$1
    local column_constraints=""
    column_constraints=$(awk '
BEGIN {
    all_date=""
    constraints[1]="primary key"
    constraints[2]="unique"
    constraints[3]="not null"
    constraints[4]="references"
    IGNORECASE = 1
}
{
    column_constraints=""
    for (idx in constraints) {
        current_constraint_pattern = constraints[idx]
        # Check if the current line ($0) contains the constraint pattern
        if ($0 ~ current_constraint_pattern) {
            if (current_constraint_pattern == "primary key"){
                column_constraints = column_constraints"pk"
            }else if (current_constraint_pattern == "not null"){
                if (column_constraints == ""){
                    column_constraints = column_constraints"nn"
                }else {
                    column_constraints = column_constraints",""nn"
                }
            }else if (current_constraint_pattern == "references") {
            split($0, arr, " ");
            table_name = arr[4]
            col_name = arr[5]
            sub(/\(/, "",col_name)
            sub(/\)/, "",col_name)
                if (column_constraints == ""){
                    column_constraints = column_constraints"fk"
                }else {
                    column_constraints = column_constraints":fk"
                }
            column_constraints = column_constraints","table_name","col_name
            }
            else {
            if (column_constraints == ""){
            column_constraints = column_constraints""current_constraint_pattern
            }else {
            column_constraints = column_constraints","current_constraint_pattern 
            }
            }
        }
        # check if it the first row of the text file add column_constraints to all_date else add ":" and column_constraints    
    }
    if (NR == 1) {
        all_date = column_constraints
    } else {
        all_date = all_date ":" column_constraints
    }
}
END {
    print all_date    
    }
' <<< $column_data)
    echo "$column_constraints"
}

is_valid_fk_column() {
    local table_name="$1"
    local column_name="$2"
    local table_cols=$(sed -n '1p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    local table_constraints=$(sed -n '3p' $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name)
    declare -a table_cols_array=()
    declare -a table_constraints_array=()
    split_string_to_array "$table_cols" ":" table_cols_array
    split_string_to_array "$table_constraints" ":" table_constraints_array

    # check if the column exists in the table
    declare -a syntax_col_names_arr=("$column_name")

    if ! check_all_columns_exist syntax_col_names_arr table_cols_array ;then
        output_error_message "Invalid Foreign Key! Column $column_name does not exist in table $table_name"
        return 1
    fi

    local column_order=$(get_column_order "$column_name" table_cols_array)
    ((column_order--))
    # check if the column is a primary key
    if [[ "${table_constraints_array[${column_order}]}" == "pk" ]] ;then 
    return 0
    else 
    output_error_message "Invalid Foreign Key! Column $column_name is not a primary key"
    return 1
    fi
}

is_valid_fk() {
    local column_constraints="$1"
    local foreign_key_regex="\s*fk\s*,\s*([a-zA-Z][a-zA-Z_]*)\s*,\s*([a-zA-Z][a-zA-Z_]*)"
    IFS=':'
    read -r -a constraints_array <<< "$column_constraints"
    for constraint_line in "${constraints_array[@]}"; do
        if [[ "$constraint_line" =~ $foreign_key_regex ]]; then
        local table_name="${BASH_REMATCH[1]}"
        local column_name="${BASH_REMATCH[2]}"
            if ! if_table_exist "$table_name" ; then 
            output_error_message "Invalid Foreign Key! Table $table_name does not exist"
            return 1
            elif ! is_valid_fk_column "$table_name" "$column_name";then
            return 1
            fi      
        fi
    done
    return 0
}

#============ end helper functions ============

#============ start script body ============

shopt -s nocasematch

 
if [[ "$sql_code" =~ $sql_create_regex ]]; then

    table_name=$(get_table_name "$sql_code")

    if if_table_exist "$table_name";then
        output_error_message "Table $table_name already exists"
    else 
        column_data=$(extract_column_data "$sql_code")
        if check_repeated_column_names "$column_data";then
        output_error_message "Repeated Column Names! Try to enter a valid query"
        return
        elif check_repeated_constraints "$column_data";then
        output_error_message "Repeated Constraints! Try to enter a valid query"
        return
        else
            table_column_names=$(extract_column_names "$column_data")
            table_column_types=$(extract_column_types "$column_data")
            table_column_constraints=$(extract_column_Constraints "$column_data")
            if ! is_valid_fk "$table_column_constraints" ; then 
            return 
            fi
            touch $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name
            echo "$table_column_names" >> $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name  
            echo "$table_column_types"  >> $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name
            echo "$table_column_constraints" >> $engine_dir/".db-engine-users"/$loggedInUser/$connected_db/$table_name
            output_success_message "Table $table_name created successfully"
        fi
        
    fi

else
    output_error_message "syntax Error! Try to enter a valid query"
fi

shopt -u nocasematch

#============ end script body ============

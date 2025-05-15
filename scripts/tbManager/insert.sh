#============ start global variables ============

check_name_validity='[a-zA-Z][a-zA-Z_]*'
group_of_cols_regex="\(\s*(${check_name_validity}\s*(,\s*${check_name_validity})*)\s*\)"
group_of_values_regex="\(\s*(([1-9][0-9]*|'[^']*')(\s*,\s*([1-9][0-9]*|'[^']*'))*)\s*\)"
sql_insert_regex="\s*insert\s+into\s*([a-zA-Z][a-zA-Z_]*)\s*${group_of_cols_regex}\s*values\s*${group_of_values_regex}"

#============ end global variables ============

#============ start helper functions ============
# extract_column_names() {
#     local syntax="$1"
#     local columnNames=$(echo "$syntax" | grep -oP "$group_of_cols_regex"| sed -e "s/^(//" -e "s/)$//" -e "s/\s*,\s*/,/g")
#     IFS=','
#     read -d '' -r -a syntax_cols_array < <(printf %s "$columnNames")

    
# }
#============ end helper functions ============

#============ start script body ============

shopt -s nocasematch

sql_code=$(echo "$sql_code" | sed -e 's/\s\+/ /g')
if [[ "$sql_code" =~ $sql_insert_regex ]]; then

    table_name="${BASH_REMATCH[1]}"
    columns="${BASH_REMATCH[2]}"
    values="${BASH_REMATCH[4]}"
    echo "$table_name"
    echo "$columns"
    echo "$values"
    echo "$sql_code"


if if_table_exist "$table_name" ;then
    # extract_column_names "$sql_code"
    echo ${syntax_cols_array[@]}
    echo $table_name
    else
    output_error_message "Table $table_name does not exist"
fi        

else 

    output_error_message "syntax Error! Try to enter a valid query"

fi
shopt -u nocasematch

#============ end script body ============

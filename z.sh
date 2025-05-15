syntax="insert into      table  ( first_name  ,   last_name ) values ('val1',12)"
check_name_validity='[a-zA-Z][a-zA-Z_]*'
group_of_cols_regex="\(\s*(${check_name_validity}\s*(,\s*${check_name_validity})*)\s*\)"
# remove extra spaces from syntax line
syntax=$(echo "$syntax" | sed -e 's/\s\+/ /g')
sql_insert_regex="\s*insert\s+into\s*([a-zA-Z][a-zA-Z_]*)\s*${group_of_cols_regex}\s*values\s*\(([^)]*)\)"
if [[ "$syntax" =~ $sql_insert_regex ]]; then
    table_name="${BASH_REMATCH[1]}"
    columns="${BASH_REMATCH[2]}"
    values="${BASH_REMATCH[4]}"
fi
echo "$table_name"
echo "$columns"
echo "$values"
echo "$syntax"
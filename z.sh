extract_col_data() {

text="$1"
local -n f_arr="$2"
local -n l_arr="$3"
text=$(echo "$text" | grep -oP "[a-zA-Z][a-zA-Z_]*\s*=\s*([1-9][0-9]*|'[^']*'|null)")
IFS=$'\n'
read -d '' -r -a text_arr <<< "$text" 
for line in "${text_arr[@]}"; do
    line=$(echo "$line" | sed 's/\s*=\s*/=/1')
    col_name=$(echo "$line" | cut -d '=' -f 1)
    col_val=$(echo "$line" | cut -d '=' -f 2)
    f_arr+="$col_name"
    l_arr+="$col_val"    
done


}
values_to_update="emp_id = 23"
extract_col_data "$values_to_update" syntax_col_names_arr syntax_values_arr

echo "${syntax_col_names_arr[@]}"
echo "${syntax_values_arr[@]}"
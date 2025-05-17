#! /usr/bin/bash

# Function to print a dynamic table
# Arguments:
#   1. Table Title (string)
#   2. Array of Column Headers (passed by name reference)
#   3. Array of Records (passed by name reference, each record is a colon-separated string)

print_dynamic_table() {
    local table_title="$1"
    local -n header_arr_ref="$2"
    local -n records_arr_ref="$3"

    local num_cols="${#header_arr_ref[@]}"
    if (( num_cols == 0 )); then
        echo "Error: No column headers provided to print_dynamic_table."
        return 1
    fi

    declare -a max_content_widths_arr=()

    # Initialize widths with header lengths
    for (( i=0; i<num_cols; i++ )); do
        max_content_widths_arr[$i]=${#header_arr_ref[$i]}
    done

    # Update widths based on data lengths from records
    for record_line in "${records_arr_ref[@]}"; do
        IFS=':' read -r -a cells <<< "$record_line"
        for (( i=0; i<num_cols; i++ )); do
            local cell_value=""
            if [[ $i -lt ${#cells[@]} ]]; then # Check if cell exists for this column
                cell_value="${cells[$i]}"
            fi
            local cell_len=${#cell_value}
            if (( cell_len > max_content_widths_arr[$i] )); then
                max_content_widths_arr[$i]=$cell_len
            fi
        done
    done

    # Construct separator line and printf format string for data rows
    local separator_line="+"
    local data_row_format_string="|"

    for (( i=0; i<num_cols; i++ )); do
        local content_width="${max_content_widths_arr[$i]}"
        local dashes_count=$((content_width + 2)) # +2 for spaces around content
        local dashes=$(printf '%*s' "$dashes_count" "" | tr ' ' '-')
        
        separator_line+="${dashes}+"
        data_row_format_string+=" %-${content_width}s |"
    done
    # data_row_format_string is now like "| %-W1s | %-W2s | ... |"
    # Add newline for the complete format string
    data_row_format_string+="\n"

    # Calculate total table width for the title
    local table_total_width=${#separator_line}
    local title_inner_width=$((table_total_width - 2)) # Width for text inside the title's |...|

    # Create the top border for the title section
    local title_outer_border_dashes=$(printf '%*s' "$title_inner_width" "" | tr ' ' '-')
    local title_outer_border_line="+${title_outer_border_dashes}+"

    # Center the title text
    local formatted_title_content
    local title_text_len=${#table_title}
    if [ "$title_text_len" -gt "$title_inner_width" ]; then
        # Truncate title_text if it's too long
        formatted_title_content=$(printf "%.*s" "$title_inner_width" "$table_title")
    else
        local padding_total=$((title_inner_width - title_text_len))
        local pad_left=$((padding_total / 2))
        local pad_right=$((padding_total - pad_left))
        formatted_title_content=$(printf "%*s%s%*s" "$pad_left" "" "$table_title" "$pad_right" "")
    fi
    local formatted_title_line="|${formatted_title_content}|"

    # Print the table
    echo "$title_outer_border_line"
    echo "$formatted_title_line"
    echo "$separator_line"
    # shellcheck disable=SC2059 # We are intentionally building the format string
    printf "$data_row_format_string" "${header_arr_ref[@]}"
    echo "$separator_line"

    if [[ ${#records_arr_ref[@]} -eq 0 ]]; then
        local no_records_message="No records to display."
        local msg_len=${#no_records_message}
        local empty_row_content
        # Center the "No records" message within the available inner width
        if [ "$msg_len" -gt "$title_inner_width" ]; then
            empty_row_content=$(printf "%.*s" "$title_inner_width" "$no_records_message")
        else
            local padding_total_empty=$((title_inner_width - msg_len))
            local pad_left_empty=$((padding_total_empty / 2))
            local pad_right_empty=$((padding_total_empty - pad_left_empty))
            empty_row_content=$(printf "%*s%s%*s" "$pad_left_empty" "" "$no_records_message" "$pad_right_empty" "")
        fi
        printf "|%s|\n" "$empty_row_content" # Print centered message spanning the table width
    else
        for record_line in "${records_arr_ref[@]}"; do
            IFS=':' read -r -a cells <<< "$record_line"
            # Ensure cells array has num_cols elements for printf, padding with empty strings if necessary
            local printf_cells_args=()
            for (( k=0; k<num_cols; k++ )); do
                printf_cells_args+=("${cells[$k]:-}") # Default to empty string if cell missing or null
            done
            # shellcheck disable=SC2059
            printf "$data_row_format_string" "${printf_cells_args[@]}"
        done
    fi

    echo "$separator_line"
}

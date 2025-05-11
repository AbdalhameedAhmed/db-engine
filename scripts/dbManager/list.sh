#! /usr/bin/bash

# list databases in formated order table
allDbs=$(ls -F "$engine_dir/.db-engine-users/$loggedInUser" | grep '/$' | sed 's/\/$//')
if [ -z "$allDbs" ]; then
  echo "No databases found"
else
   # Define column widths for the table
  num_w=3    # Width for the "No." column (e.g., "1", "10", "100")
  name_w=20  # Width for the "Name" column (database names will be truncated if longer)

  # Calculate lengths for separator parts.
  # Each column in the table looks like: | content |
  # The dashes in the separator line should span the content area + the two spaces around it.
  dashes_num_col=$(printf '%*s' "$((num_w + 2))" "" | tr ' ' '-')   # e.g., ----- for num_w=3
  dashes_name_col=$(printf '%*s' "$((name_w + 2))" "" | tr ' ' '-') # e.g., ---------------------- for name_w=20
  separator_line="+${dashes_num_col}+${dashes_name_col}+"

  # Calculate overall table width for the title section
  table_width=${#separator_line}
  title_inner_width=$((table_width - 2)) # Width for text inside the title's |...|

  title_text="Databases Listed"
  title_text_len=${#title_text}

  # Create the top border for the title section (e.g., +------------------------+)
  title_outer_border_dashes=$(printf '%*s' "$title_inner_width" "" | tr ' ' '-')
  title_outer_border_line="+${title_outer_border_dashes}+"

  # Center the title text within its line
  if [ "$title_text_len" -gt "$title_inner_width" ]; then
    # Truncate title_text if it's too long
    formatted_title_content=$(printf "%.*s" "$title_inner_width" "$title_text")
  else
    padding_total=$((title_inner_width - title_text_len))
    pad_left=$((padding_total / 2))
    pad_right=$((padding_total - pad_left))
    formatted_title_content=$(printf "%*s%s%*s" "$pad_left" "" "$title_text" "$pad_right" "")
  fi
  formatted_title_line=$(printf "|%s|" "$formatted_title_content") # e.g., |   Databases Listed   |

  # Print the table header section
  echo "$title_outer_border_line"
  echo "$formatted_title_line"
  echo "$separator_line"
  printf "| %-${num_w}s | %-${name_w}s |\n" "No." "Name" # Column titles
  echo "$separator_line"

  counter=0
  while IFS= read -r db_name; do
    if [ -n "$db_name" ]; then # Process only non-empty lines from allDbs
      counter=$((counter + 1))
      # Print data row, truncating db_name if it's longer than name_w
      printf "| %-${num_w}d | %-${name_w}.${name_w}s |\n" "$counter" "$db_name"
    fi
  done <<< "$allDbs" # Feed the content of allDbs to the loop

  if [ "$counter" -eq 0 ]; then
    # If allDbs was not empty but no actual database names were processed (e.g., it only contained empty lines)
    printf "| %-${table_width_minus_4}s |\n" "No databases to list." # Simple message if no items
  fi

  # Print bottom border of the table
  echo "$separator_line"
fi
echo


xd=$(awk '
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
            }else {
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
' <<< "id int primary key
first_name varchar(50)
employee_id int  references employee (xx) unique not null")
echo "$xd" # It's good practice to quote variables in echo

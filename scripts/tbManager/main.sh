#! /usr/bin/bash

#============ start script body ============

while true ; do
    read -e -p "$loggedInUser>>$connected_db> " sql_code
    if [[ "$sql_code" == "exit" ]]; then
        break
    fi
    command=$(echo "$sql_code" | cut -d' ' -f1)

    case $command in
        "create")
            source $script_dir/scripts/tbManager/create.sh
            ;;
        "insert")
            source $script_dir/scripts/tbManager/insert.sh
            ;;
        "update")
            source $script_dir/scripts/tbManager/update.sh
            ;;

        "select")
            source $script_dir/scripts/tbManager/select.sh
            ;;

        "delete")
            source $script_dir/scripts/tbManager/delete.sh
            ;;

        "drop")
            source $script_dir/scripts/tbManager/drop.sh
            ;;

        "ls")
            source $script_dir/scripts/tbManager/list.sh
            ;;
        
    esac

done

#============ end script body ============

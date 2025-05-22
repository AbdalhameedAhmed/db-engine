#============ start local variables ============

admin_logout=""

#============ end local variables ============

#============ start helper functions ============

print_admin_page_header() {
echo
output_important_message "========================== Admin Panel ========================="
echo
}

#============ end helper functions ============

# "terminate user" 

#============ start script body ============
while [[ -z "$admin_logout" ]] ; do 
    print_admin_page_header
    PS3=$admin_info"/admin: "
    select option in "Admin database" "Connect to user" "List users" "lock/unlock user" "change user password" "Logout"; do
        case $option in 

            "Admin database")
                PS3=$username"/dbManaging: "
                loggedInUser="$username"
                source $script_dir/scripts/dbManager/main.sh
                print_admin_page_header
                break
            ;;

            "Connect to user")
    
                source $script_dir/scripts/admin/connect_to_user.sh
                break
            ;;

            "List users")
                source $script_dir/scripts/admin/list.sh
                break
            ;;

            "lock/unlock user")
                source $script_dir/scripts/admin/lock_unlock.sh
                break
            ;;
            # "terminate user")
            #     source $script_dir/scripts/dbManager/drop.sh
            #     break
            # ;;
            "change user password")
                source $script_dir/scripts/admin/change_password.sh
                break
            ;;
            "Logout")
            admin_logout="true"
            admin_info=""
            loggedInUser=""
            PS3='Login/Register:'
            echo
            output_success_message "Logged out successfully"
            echo
            sleep 1
            break
            ;;
            "*")
                echo
                output_error_message "invalid option $REPLY"
                echo
                break
                ;;
        esac
    done
done

#============ end script body ============


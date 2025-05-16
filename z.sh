# print_array(){
#     local -n my_array2="$1"

#     for anyString in "${my_array2[@]}"; do
#         echo "$anyString"
#     done
# }

# my_data="apple:banana:cherry:date"
# IFS=":" 
# read -r -a my_array <<< "$my_data"
# print_array my_array
num="1"
xd=$(cat /home/turbo/.db-engine-users/ahmed/t/iti | cut -d : -f $num)
echo "${xd}"
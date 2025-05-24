#! /usr/bin/bash

# all_pr=$(ps aux | grep .*db-engine.sh$ | sed -e 's/\s\+/ /g' | cut -d " " -f 5)
# echo "$all_pr"

declare -a xx=("a" "b" "c")

echo ${xx[0]}
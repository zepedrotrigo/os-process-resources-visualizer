for group in "${subgroups[@]}"; do
    declare -n lst="$group"
    echo "group name: ${group} with group members: ${lst[@]}"
    for element in "${lst[@]}"; do
        echo -en "\tworking on $element of the $group group\n"
    done
done

for pid in arr:
    arr = {pid : [comm,user,vmrss,rate,ratew], pid : [comm,user,vmrss,rater,ratew]}

for key in "${!MYARRAY[@]}"; do
  printf '%s:%s\n' "$key" "${MYARRAY[$key]}"
done | sort -t : -k 2n
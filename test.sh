#!/bin/bash
declare -A associative_array_of_processes
pid=1
comm="slack"
user="fortnyce"
VmSize_value="42"
VmRSS_value="88"
rchar_value="53"
wchar_value="37"
process_date="2 setembro"

associative_array_of_processes[$pid,"comm"]=$comm
associative_array_of_processes[$pid,"user"]=$user
associative_array_of_processes[$pid,"VmSize"]=$VmSize_value
associative_array_of_processes[$pid,"VmRSS"]=$VmRSS_value
associative_array_of_processes[$pid,"rchar"]=$rchar_value
associative_array_of_processes[$pid,"wchar"]=$wchar_value
associative_array_of_processes[$pid,"date"]=$process_date

pid=2
comm="discord"
user="sop101"
VmSize_value="423"
VmRSS_value="838"
rchar_value="533"
wchar_value="337"
process_date="32 setembro"

associative_array_of_processes[$pid,"comm"]=$comm
associative_array_of_processes[$pid,"user"]=$user
associative_array_of_processes[$pid,"VmSize"]=$VmSize_value
associative_array_of_processes[$pid,"VmRSS"]=$VmRSS_value
associative_array_of_processes[$pid,"rchar"]=$rchar_value
associative_array_of_processes[$pid,"wchar"]=$wchar_value
associative_array_of_processes[$pid,"date"]=$process_date

for key in "${!associative_array_of_processes[@]}"; do

    echo "$key ${associative_array_of_processes[$key]}"
    unset $key
    sleep 1
    echo ${associative_array_of_processes[1]}
    sleep 1
done

#declare -A array
#array[x1,y1]=100
#array[x1,y2]=200
#array[x2,y1]=300
#array[x2,y2]=400

#keys=(x1 x2)
#for key in "${keys[@]}"; do
#
#    #the loop contents are the same
#    echo "$key : y1 = ${array[$key,y1]}"
#    echo "$key : y2 = ${array[$key,y2]}"
#done
echo ${#pid_list[@]} - ${#pid_list2[@]} - ${#pid_list3[@]} - ${#pid_list4[@]}
#!/bin/bash
declare -A matrix
num_rows=4
num_columns=5

for ((i=1;i<=num_rows;i++)) do
    for ((j=1;j<=num_columns;j++)) do
        matrix[$i,$j]=$RANDOM
    done
done

#for key in "${keys[@]}"; do
#
#    #the loop contents are the same
#    echo "$key : y1 = ${array[$key,y1]}"
#    echo "$key : y2 = ${array[$key,y2]}"
#done
#!/bin/bash

c=32
timePattern="^[A-Z][a-z][a-z] ([1-9]{1,2}) [0-2][0-3]:[0-5][0-9]$"
            # ^[A-Z][a-z][a-z] ([1-9]{1,2}) [0-2][0-3]:[0-5][0-9]$
user_start_time=$1

#[[ "$user_start_time" =~ $timePattern ]] && echo "in if" || echo "in else"
if [[ "$user_start_time" =~ $timePattern ]]; then
#or if [ "$user_start_time" =~ "$timePattern" ]then
         echo "ok"
else
         echo "not ok"
fi
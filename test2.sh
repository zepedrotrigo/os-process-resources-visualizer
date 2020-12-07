for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    ...
    # Lista com PIDs que não contêm a FLAG -c
    if [[ $flag_c != "" ]]; then
        comm=$(cat $entry/comm)
        if ! [[ $comm =~ $flag_c ]]; then
            pid_list2+=($entry_basename)
        fi
    fi

    # Lista com PIDs que não contêm a flag -u
    if [[ $flag_u != "" ]]; then
        uid="$( stat -c "%u" /proc/${entry_basename} )"
        user="$( id -nu ${uid} )"
        if ! [[ $user =~ $flag_u ]]; then
            pid_list3+=($entry_basename)
        fi
    fi

    # Lista com PIDs que estão no intervalo de tempo definido pelas flags -s e -e
    if [[ $flag_s != "" || $flag_e != "" ]]; then
        pid_date=$(ls -ld /proc/$entry_basename)
        pid_date=$(echo $pid_date | awk '{ print $6" "$7" "$8}')
        pid_date=$(date -d "${pid_date}" +"%s")

        if [[ $flag_s != "" ]]; then
            if [ $pid_date -lt $min_date ]; then
                pid_list4+=($entry_basename)
            fi
        fi
        if [[ $flag_e != "" ]]; then
            if [ $pid_date -gt $max_date ]; then
                pid_list4+=($entry_basename)
            fi
        fi
    fi
    ...
done
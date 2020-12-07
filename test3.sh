for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    ...
    # Lista com PIDs que não contêm a FLAG -c
    if [[ $flag_c != "" ]]; then
        comm=$(cat $entry/comm)
        if ! [[ $comm =~ $flag_c ]]; then
            pid_list2+=($entry_basename)
        fi
    fi
    ...
done
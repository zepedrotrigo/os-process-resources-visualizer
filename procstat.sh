#!/bin/bash
# awk, bc, cat, cut, date, getopts, grep, head, ls, printf, sleep, sort

cd /proc # Mudar a diretoria para /proc
printf '%-20s\t\t %-10s\t\t %10s\t %10s\t %10s\t %10s\t %9s\t %3s\t %6s\t %5s\n' "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE" # Cabeçalho da tabela

for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) (o PID)
    if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos
        comm=$(cat $entry_basename/comm)
        user="$( ps -o uname= -p "${entry_basename}" )"

        VmSize=$(grep 'VmSize' $entry_basename/status) # Obter todas as linhas com VmSize
        VmSize_value=$(echo $VmSize | grep -o -E '[0-9]+') # Obter apenas o valor numérico
        VmRSS=$(grep 'VmRSS' $entry_basename/status)
        VmRSS_value=$(echo $VmRSS | grep -o -E '[0-9]+')
        rchar=$(grep 'rchar' $entry_basename/io)
        rchar_value=$(echo $rchar | grep -o -E '[0-9]+')
        wchar=$(grep 'wchar' $entry_basename/io)
        wchar_value=$(echo $wchar | grep -o -E '[0-9]+')

        if [[ $VmSize_value == "" ]]; then
            VmSize_value="N/A"
        fi

        if [[ $VmRSS_value == "" ]]; then
            VmRSS_value="N/A"
        fi 

        #if [[ ${#user} -gt 15 ]]; then
        #    user = "xxxx"
        #fi
        #https://qastack.com.br/unix/396223/bash-shell-script-output-alignment

        printf '%-30s\t %-20s\t %10s\t %10s\t %10s\t %10s\t %9s\t %5s\t %6s\t %5s\n' "$comm" "$user" "$entry_basename" "$VmSize_value" "$VmRSS_value" "$rchar_value" "$wchar_value" "****" "****" "****"
    fi
done


# rchar vai ser o readb, wchar -> writeb, e o rater e ratew são a taxa de leitura/escrita em bytes por segundo dos processos
#!/bin/bash
# awk, bc, cat, cut, date, getopts, grep, head, ls, printf, sleep, sort
#TODO mismatch entre os valores do read_io e do print abaixo. Podem estar desalinhados
# deve ter a ver com a variavel counter
#TODO VALIDAR TODOS OS VALORES IMPRESSOS
#-----------------------------------------Declaração de Funções-------------------------------------

read_io () {

    cd /proc/ # Mudar para a diretoria /proc/
    rchar_array=() # Inicializar arrays
    wchar_array=()

    for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
        entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) (o PID)
        if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos
            if [[ -r "$entry/io" ]] ; then
                # Leitura dos valores rchar e wchar
                rchar=$(grep 'rchar' $entry_basename/io) # Obter todas as linhas com rchar
                rchar_value=$(echo $rchar | grep -o -E '[0-9]+') # Obter apenas o valor numérico
                wchar=$(grep 'wchar' $entry_basename/io)
                wchar_value=$(echo $wchar | grep -o -E '[0-9]+')

                rchar_array+=($rchar_value) #Guardar o valor num array
                wchar_array+=($wchar_value)
            fi
        fi
    done
}

display_process () {

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
    process_date=$(ls -ld /proc/$entry_basename)
    process_date=$(echo $process_date | awk '{ print $6" "$7" "$8}')

    if [[ $VmSize_value == "" ]]; then # Se o valor for "" alterar para "N/A"
        VmSize_value="N/A"
    fi

    if [[ $VmRSS_value == "" ]]; then # Se o valor for "" alterar para "N/A"
        VmRSS_value="N/A"
    fi 

    printf '%-30s\t %-20s\t %10s\t %10s\t %10s\t %10s\t %9s\t %10s\t %10s\t %5s\n' "$comm" "$user" "$entry_basename" "$VmSize_value" "$VmRSS_value" "$rchar_value" "$wchar_value" "${read_rate_array[counter]}" "${write_rate_array[counter]}" "$process_date"
    (( counter++ ))
    #TODO ver se estamos a imprimir o ultimo elemento do array
}

#------------------------------------------Main program---------------------------------------------
#------------------------------------------Argumentos de entrada------------------------------------

if [[ $# -lt 100 ]]; then #TODO 
    cd /proc # Mudar a diretoria para /proc
    while getopts "c:s:e:u:p:mtdwr"  OPTION; do #TODO time é o argument -1. Podemos ir busca-lo assim
        if [[ ${OPTARG} == -* ]]; then
            echo "Missing argument for -${OPTION}"
            exit 1
        fi
        case $OPTION in
        c)
            flag_c=${OPTARG}
            ;;
        s)
            flag_s=${OPTARG}
            ;;
        e)
            flag_e=${OPTARG}
            ;;
        u)
            flag_u=${OPTARG}
            ;;
        p)
            flag_p=${OPTARG}
            ;;
        m)
            flag_m=1
            ;;    
        t)
            flag_t=1
            ;;  
        d)
            flag_d=1
            ;; 
        w)
            flag_w=1
            ;;   
        r)
            flag_r=1
            ;;
        *)
            echo "Invalid options provided"
            exit 1
            ;;
        esac
    done

    shift $((OPTIND-1))

# ----------------------------------- Ler taxa de IO no intervalo de s segundos ----------------------------
    
    read_rate_array=() #Inicializar arrays
    write_rate_array=()

    read_io # ler rchar e wchar pela 1ª vez
    first_rchar_array=("${rchar_array[@]}") # Copiar array da 1ª leitura uma vez que
    first_wchar_array=("${wchar_array[@]}") # vai ser overwritten
    sleep $1 # Esperar s segundos #TODO can't divide by zero, robust programi
    read_io # ler rchar e wchar pela 2ª vez

    for i in ${!rchar_array[@]}; do # Calcular read rate e write rate em Bytes/s
        op1=${rchar_array[i]}
        op2=${first_rchar_array[i]}
        read_rate=$(echo "scale=1; ($op1 - $op2)/$1" | bc)
        op1=${wchar_array[i]}
        op2=${first_wchar_array[i]}
        write_rate=$(echo "scale=1; ($op1 - $op2)/$1" | bc)

        read_rate_array+=($read_rate)
        write_rate_array+=($write_rate)
    done

    #--------------------------- Imprimir cabeçalho da tabela------------------------------------------
    
    printf '%-20s\t\t %10s\t\t %10s\t %10s\t %10s\t %10s\t %9s\t %10s\t %10s\t %12s\n' "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE" # Cabeçalho da tabela

    counter=0
    for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
        entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) (o PID)
        if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos
            if [[ -r "$entry/io" && -r "$entry/comm" && -r "$entry/status" ]] ; then
                #if flag exists and condiçao; if flag2 exist and condicao
                if [[ $flag_c =~ "" ]]; then
                    comm=$(cat $entry_basename/comm)
                    if [[ $comm =~ $flag_c ]]; then
                        display_process $entry_basename
                    else
                        :
                    fi
                fi
            fi
        fi
    done

else
    echo "Invalid options provided"
fi
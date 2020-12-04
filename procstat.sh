#!/bin/bash
# awk, bc, cat, cut, date, getopts, grep, head, ls, printf, sleep, sort
#TODO os rater e ratew nao batem certo se usarmos sorts. Compor
#TODO VALIDAR TODOS OS VALORES IMPRESSOS
#TODO no such file or directory
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

process_list () {
    for pid in ${pid_list[@]}; do 
        comm=$(cat $pid/comm)
        user="$( ps -o uname= -p "${pid}" )"
        VmSize=$(grep 'VmSize' $pid/status) # Obter todas as linhas com VmSize
        VmSize_value=$(echo $VmSize | grep -o -E '[0-9]+') # Obter apenas o valor numérico
        VmRSS=$(grep 'VmRSS' $pid/status)
        VmRSS_value=$(echo $VmRSS | grep -o -E '[0-9]+')
        rchar=$(grep 'rchar' $pid/io)
        rchar_value=$(echo $rchar | grep -o -E '[0-9]+')
        wchar=$(grep 'wchar' $pid/io)
        wchar_value=$(echo $wchar | grep -o -E '[0-9]+')
        process_date=$(ls -ld /proc/$pid)
        process_date=$(echo $process_date | awk '{ print $6" "$7" "$8}')

        if [[ $VmSize_value == "" ]]; then # Se o valor for "" alterar para "N/A"
            VmSize_value="N/A"
        fi

        if [[ $VmRSS_value == "" ]]; then # Se o valor for "" alterar para "N/A"
            VmRSS_value="N/A"
        fi

        associative_array_of_processes[$pid,"comm"]=$comm
        associative_array_of_processes[$pid,"user"]=$user
        associative_array_of_processes[$pid,"VmSize"]=$VmSize_value
        associative_array_of_processes[$pid,"VmRSS"]=$VmRSS_value
        associative_array_of_processes[$pid,"rchar"]=$rchar_value
        associative_array_of_processes[$pid,"wchar"]=$wchar_value
        associative_array_of_processes[$pid,"date"]=$process_date
        #TODO falta o RATER e o RATEW

    done 
}

#------------------------------------------Main program---------------------------------------------
#------------------------------------------Argumentos de entrada------------------------------------

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
pid_list=()

for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) (o PID)
    if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos
        if [[ -r "$entry/io" && -r "$entry/comm" && -r "$entry/status" ]] ; then # Obter apenas folders com permissões de leitura
            pid_list+=($entry_basename) #Guardar esses folders num array que vai ser utilizada na função process_list
        fi
    fi
done

declare -A associative_array_of_processes
process_list # function

for pid in ${pid_list[@]}; do
    printf '%-30s\t %-20s\t %10s\t %10s\t %10s\t %10s\t %9s\t %10s\t %10s\t %5s\n' "${associative_array_of_processes[$pid,"comm"]}" "${associative_array_of_processes[$pid,"user"]}" "$pid" "${associative_array_of_processes[$pid,"VmSize"]}" "${associative_array_of_processes[$pid,"VmRSS"]}" "${associative_array_of_processes[$pid,"rchar"]}" "${associative_array_of_processes[$pid,"wchar"]}" "FAZER" "FAZER" "${associative_array_of_processes[$pid,"date"]}"
done

#if flag exists and condiçao; if flag2 exist and condicao
#if [[ $flag_c =~ "" ]]; then
#    comm=$(cat $entry_basename/comm)
#    if [[ $comm =~ $flag_c ]]; then
#        display_process $entry_basename
#    else
#        :

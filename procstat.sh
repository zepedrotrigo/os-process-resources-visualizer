#!/bin/bash
#TODO a flag das datas nao esta a funcionar bem
#TODO validar args datas (ver se o user insere uma data com o formato valido)
#TODO ULTIMO o sudo estraga a subtraçao de arrays. (experimentar fazer permutaçoes de ifs)
#TODO ALINHAR CABEÇALHO
cd /proc
sort_parameter=1
sort_reverse=""
flag_p=2147483647
flag_s=""
flag_e=""
#-----------------------------------------Declaração de Funções-------------------------------------
read_io () {
    rchar_array=() # Inicializar arrays
    wchar_array=()
    for pid in ${pid_list[@]}; do
        if [ -e /proc/$pid ]; then # verificar se a diretoria ainda existe
            # Leitura dos valores rchar e wchar
            rchar=$(grep 'rchar' $pid/io) # Obter todas as linhas com rchar
            rchar_value=$(echo $rchar | grep -o -E '[0-9]+') # Obter apenas o valor numérico
            wchar=$(grep 'wchar' $pid/io)
            wchar_value=$(echo $wchar | grep -o -E '[0-9]+')
            #Guardar valores de rchar e wchar em arrays
            rchar_array+=($rchar_value)
            wchar_array+=($wchar_value)
        else
            rchar_array+=(0) # Se o processo entretanto terminar, preencher o array com 0 à mesma
            wchar_array+=(0) # para não haver incompatibilidade de indexes na função process_list
#                              que utiliza os valores destes arrays
        fi
    done
}

process_list () {
    counter=0
    for pid in ${pid_list[@]}; do
        if [ -e /proc/$pid ]; then # verificar se a diretoria ainda existe
            comm=$(cat $pid/comm | tr " " "_")
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
            rater=${read_rate_array[counter]}
            ratew=${write_rate_array[counter]}

            if [[ $VmSize_value == "" ]]; then # Se o valor for "" alterar para "N/A"
                VmSize_value="N/A"
            fi
            if [[ $VmRSS_value == "" ]]; then # Se o valor for "" alterar para "N/A"
                VmRSS_value="N/A"
            fi

            if [ $counter -ge $flag_p ]; then
                break
            fi
            printf '%-30s\t %-20s\t %10s\t %10s\t %10s\t %10s\t %9s\t %10s\t %10s\t %5s\n' "$comm" "$user" "$pid" "$VmSize_value" "$VmRSS_value" "$rchar_value" "$wchar_value" "$rater" "$ratew" "$process_date"
            (( counter++ ))
        fi
    done  | sort -n -k $sort_parameter $sort_reverse
}
#------------------------------------------Argumentos de entrada------------------------------------
while getopts "c:s:e:u:p:mtdwr"  OPTION; do
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
        sort_parameter=4
        ;;    
    t)
        if [ $sort_parameter -ne 1 ]; then
            echo "Invalid argument: multiple sort parameters detected"
            exit 1
        fi
        sort_parameter=5
        ;;  
    d)
        if [ $sort_parameter -ne 1 ]; then
            echo "Invalid argument: multiple sort parameters detected"
            exit 1
        fi
        sort_parameter=8
        ;; 
    w)
        if [ $sort_parameter -ne 1 ]; then
            echo "Invalid argument: multiple sort parameters detected"
            exit 1
        fi
        sort_parameter=9
        ;;   
    r)
        sort_reverse="-r"
        ;;
    *)
        echo "Invalid options provided"
        exit 1
        ;;
    esac
done

shift $((OPTIND-1))
#------------------------------------------Validação de argumentos------------------------------------------------------
if [ "$#" -ne 1 ] || ! [[ $1 =~ ^[0-9]+$ ]] || [ $1 -gt 2147483647 ] || [ $1 -lt 1 ]; then # If $1 (sleep) não for int ou for menor que 1 ou for maior que 2^31-1 ou o n de argumentos for diferente de 1
    echo "Invalid argument sleep time"
    exit 1
fi
#------------------------------------------Obter listas de PIDs-------------------------------------------------------
pid_list=()
pid_list2=()
pid_list3=()
pid_list4=()
min_date=$(date -d "${flag_s}" +"%s")
max_date=$(date -d "${flag_e}" +"%s")
for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) (o PID)
    if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos
        if [ -r "$entry/io" ] && [ -r "$entry/comm" ] && [ -r "$entry/status" ] && [ -r "/proc/$entry_basename" ] ; then # Obter apenas folders com permissões de leitura
            
            # Lista com os PIDs todos (que permitem leitura)
            pid_list+=($entry_basename) #Guardar esses folders num array que vai ser utilizada na função process_list
            
            # Lista com PIDs que não contêm a FLAG -c
            if [[ $flag_c != "" ]]; then
                comm=$(cat $entry_basename/comm)
                if ! [[ $comm =~ $flag_c ]]; then
                    pid_list2+=($entry_basename)
                fi
            fi
            # Lista com PIDs que não contêm a flag -u
            if [[ $flag_u != "" ]]; then
                user="$( ps -o uname= -p "${entry_basename}" )"
                if ! [[ $user =~ $flag_u ]]; then
                pid_list3+=($entry_basename)
                fi
            fi
            # Lista com PIDs que estão no intervalo de tempo definido pelas flags -s e -e
            if [[ $flag_s != "" && $flag_e != "" ]]; then
                pid_date=$(ls -ld /proc/$entry_basename)
                pid_date=$(echo $pid_date | awk '{ print $6" "$7" "$8}')
                pid_date=$(date -d "${pid_date}" +"%s")
                if [ $pid_date -lt $min_date ] || [ $pid_date -gt $max_date ]; then
                    pid_list4+=($entry_basename)
                fi
            fi
        fi
    fi
done

# Subtrair arrays com PIDS que não contêm as flags ao array com os PIDs todos
echo ${#pid_list[@]} - ${#pid_list2[@]} - ${#pid_list3[@]} - ${#pid_list4[@]}
for i in "${pid_list2[@]}"; do
    pid_list=(${pid_list[@]//*$i*})
done
for i in "${pid_list3[@]}"; do
    pid_list=(${pid_list[@]//*$i*})
done
for i in "${pid_list4[@]}"; do
    pid_list=(${pid_list[@]//*$i*})
done
echo ${#pid_list[@]}
# ----------------------------------- Ler taxa de IO no intervalo de s segundos ----------------------------
read_rate_array=() #Inicializar arrays
write_rate_array=()
read_io # ler rchar e wchar pela 1ª vez
first_rchar_array=("${rchar_array[@]}") # Copiar array da 1ª leitura uma vez que
first_wchar_array=("${wchar_array[@]}") # vai ser overwritten
sleep $1 # Esperar s segundos
read_io # ler rchar e wchar pela 2ª vez

for i in ${!rchar_array[@]}; do # Calcular read rate e write rate em Bytes/s
    op1=${rchar_array[i]}
    op2=${first_rchar_array[i]}
    read_rate=$(echo "scale=2; ($op1 - $op2)/$1" | bc)
    op1=${wchar_array[i]}
    op2=${first_wchar_array[i]}
    write_rate=$(echo "scale=2; ($op1 - $op2)/$1" | bc)

    read_rate_array+=($read_rate)
    write_rate_array+=($write_rate)
done
#-------------------------------------- Imprimir tabela ----------------------------------------------------------------
printf '%-20s\t\t %10s\t\t %10s\t %10s\t %10s\t %10s\t %9s\t %10s\t %10s\t %12s\n' "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE" # Cabeçalho da tabela
process_list # devolve um array de processos
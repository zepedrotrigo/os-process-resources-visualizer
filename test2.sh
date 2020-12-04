#!/bin/bash
cd /proc

pid_list1=()
pid_list2=()

for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) (o PID)
    if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos
        if [[ -r "$entry/io" && -r "$entry/comm" && -r "$entry/status" ]] ; then # Obter apenas folders com permissões de leitura
            pid_list1+=($entry_basename) #Guardar esses folders num array que vai ser utilizada na função process_list
        fi
    fi
done

for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) (o PID)
    if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos
        if [[ -r "$entry/io" && -r "$entry/comm" && -r "$entry/status" ]] ; then # Obter apenas folders com permissões de leitura
            
            #Aplicar argumentos das flags
            # FLAG -C
            comm=$(cat $entry/comm)
            abc="d.*"
            if ! [[ $comm =~ $abc ]]; then
                pid_list2+=($entry_basename) #Guardar esses folders num array que vai ser utilizada na função process_list
            fi
            # FLAG -U

        fi
    fi
done

echo "pid_list1"
echo ${pid_list1[@]}
sleep 2
echo "pid_list2"
echo ${pid_list2[@]}

# EU QUERO OBTER OS INDICES A REMOVER E FICAR APENAS COM INDICES POSIVEIS
echo "output"
for i in "${pid_list2[@]}"; do
         pid_list1=(${pid_list1[@]//*$i*})
done
echo ${pid_list1[@]}
sleep 2
for pid in ${pid_list1[@]}; do 
    comm=$(cat $pid/comm)
    user="$( ps -o uname= -p "${pid}" )"
    echo $comm $pid $user
done
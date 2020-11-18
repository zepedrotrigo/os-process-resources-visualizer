#!/bin/bash
# apresenta estatísticas sobre a memória usada por processos e sobre a quantidade de I/O 
# que uma selecção de processos estão a efetuar

# visualizar a quantidade de memória total de um processo, a quantidade de memória física 
# ocupada por um processo, o número total e bytes de I/O que umprocesso leu/escreveu 
# e também a taxa de leitura/escrita correspondente aos últimos s segundos para de um processo 
# (o valor de s é passado como parametro).

# permite a visualização da quantidade de memória total e da memória
# residente em memória física (linhas VmSize e VmRSS de /proc/[pid]/status), do número de
# total de bytes de I/O (linhas rchar e wchar de /proc/[pid]/io) e da taxa de leitura/escrita
# (em bytes por segundo) dos processos seleccionados nos últimos s segundos (calculadas a partir de 2
# leituras de /proc/[pid]/io com intervalo de s segundos).
# parâmetro obrigatório que é o número de segundos que serão usados para calcular as taxas de I/O

# awk, bc, cat, cut, date, getopts, grep, head, ls, printf, sleep, sort

cd /proc # Mudar a diretoria para /proc

for entry in /proc/*; do # ciclo for para cada ficheiro ou diretoria contido em /proc/
    entry_basename="$(basename $entry)" # obter apenas o basename (caminho relativo da pasta) 
    if [[ $entry_basename =~ ^[0-9]+$ ]]; then # Obter apenas folders ou files com nomes apenas númericos

        VmSize=$(grep 'VmSize' $entry_basename/status)
        Vmsize_final=$(cut -d " " $VmSize) # Ficamos aqui, precisamos de obter apenas o numero.
        echo $Vmsize_final
        VmRSS=$(grep 'VmRSS' $entry_basename/status)
        rchar=$(grep 'rchar' $entry_basename/io)
        wchar=$(grep 'wchar' $entry_basename/io)
        #printf '%s %s \n' "${VmSize[@]}" "${VmRSS[@]}"
        #printf '%s\n' "${VmSize[@]}"
    fi
done

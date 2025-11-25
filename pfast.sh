#!/usr/bin/env bash


# AUTHOR: julio.pereira@gmail.com
# example: bash pfast.sh <arg1> <arg2> <arg3>
# arg1= ip(destination)
# arg2= Repeat icmp echo request
# arg3= file name

#!/usr/bin/env bash

# AUTOR: julio.pereira@gmail.com
# VERSÃO: Paralela (Background) com disparos espaçados em 200ms.

export LC_NUMERIC=C

# - VARIÁVEIS E INICIALIZAÇÃO -
a1=$1
a2=$2
a3=$3
mg="tente:\n\t$(basename $0) arg1(IP) arg2(Repeat) arg3(FileName)"

vm="\033[31;1m"  # Vermelho (DOWN)
vd="\033[32;1m"  # Verde (UP)
cl="\033[m"      # Limpa

when=$(date +%Y%m%d)
mon="mon"
pid=$$

# Nome do arquivo de estado (onde o status DW/UP é armazenado)
STATE_FILE="/tmp/${a3}_${a1}_${pid}_state"
LOG_FILE="$mon/${when}_${a3}_${a1}_${pid}"

# - CHECAGEM DE ARGUMENTOS e DIRETÓRIOS -
if [ -z "$a1" ] || [ -z "$a2" ] || [ -z "$a3" ]; then
    echo -e "Argumentos faltando!\n"
    echo -e $mg
    exit 1
fi
if [[ $a2 = 0 ]]; then  
    a2=$(echo "9^8" | bc)
fi
[ ! -d $mon ] && mkdir $mon

# Inicializa o arquivo de estado: UP (0) e timestamp inicial (0)
echo "0:0" > $STATE_FILE

# Limpa o arquivo de estado e mata processos filhos ao sair
# Isso garante que todos os pings em background sejam interrompidos.
trap "rm -f $STATE_FILE; kill 0" EXIT

# - FUNÇÃO DE PING E ANÁLISE (EXECUTADA EM BACKGROUND) -

run_test() {
    # Teste de 1.0s: 6 pacotes, 0.2s de intervalo.
    local report=$(ping $a1 -c 6 -i 0.2 -W 1.5)
    local loss=$(echo "$report" | grep -oP '\d+(?=% packet loss)')

    # Lê o estado atual (dw:timestamp). Usa um loop para garantir a leitura correta.
    local state=$(cat $STATE_FILE)
    local dw=$(echo $state | cut -d':' -f1)
    local date_dw=$(echo $state | cut -d':' -f2)

    # 1. Se a perda é total (100%)
    if [ "$loss" -eq 100 ];then

        # Se estava UP (dw=0), registra a queda e atualiza o estado
        if [[ $dw -eq 0 ]];then
            local new_date_dw=$(date +%s%3N)
            # Registra no LOG:
            echo -e "$vm PING $a1 at $(date +%Y-%m-%d_%H:%M:%S.%3N) DW $cl" >> $LOG_FILE
            # Atualiza o estado: DOWN (1) com o novo timestamp
            echo "1:$new_date_dw" > $STATE_FILE
        fi

    # 2. Se estava DOWN (dw=1) e o ping retornou alguma resposta
    elif [ $dw -eq 1 ]; then

        local date_up=$(date +%s%3N)
        local diff=$(($date_up - $date_dw))
        local diff_seg=$(LC_NUMERIC=C awk "BEGIN { printf \"%.3f\", $diff/1000 }")
        
        # Limiar de 0.05s: Registra apenas interrupções acima de 50ms
        local comp=$(echo "$diff_seg >= 0.05" | bc) 

        if [[ $comp = 1 ]];then
            # Registra no LOG:
            echo -e "$vd PING $a1 at $(date +%Y-%m-%d_%H:%M:%S.%3N) UP [$diff_seg seg] $cl" >> $LOG_FILE
        else
            # Ruído muito rápido, desfaz o registro de DOWN 
            sed -i '$d' $LOG_FILE
        fi

        # Atualiza o estado: UP (0)
        echo "0:0" > $STATE_FILE

    fi
}

# - LOOP DE DISPARO (Garante 200ms de intervalo entre os INÍCIOS) -

for ((i=1;i<$a2;i++));do
    run_test &    # Roda a função de 1.0s de teste em segundo plano
    sleep 0.2   # Pausa de 200ms para espaçar o início do próximo teste
done

# Aguarda todos os processos em segundo plano terminarem (se o loop não for infinito)
wait

exit 0
done

exit 0 

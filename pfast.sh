#!/usr/bin/env bash


# AUTHOR: julio.pereira@ciriontechnologies.com
# exemplo: bash pfast.sh <arg1> <arg2> <arg3>
# arg1= ip(destination)
# arg2= Repeat icmp echo request
# arg3= file name

# - VARIABLES DECLARATION -
a1=$1
a2=$2
a3=$3
mg="$(basename $0) arg1(IP) arg2(Repeat) arg3(FileName)"
dw=0
lp=0

vm="\033[31;1m"  
vd="\033[32;1m"
cl="\033[m"


when=$(date +%Y%m%d)
mon="mon"

# - CHECK ARGUMENTS - 

if [ -z "$a1" ]; then
    echo "Argumentos 1, 2, 3 vazios"
    echo $mg
    exit 1
elif [ -z "$a2" ]; then
    echo "Argumentos 2, 3 vazios"
    echo $mg
    exit 1
elif [ -z "$a3" ]; then
    echo "Argumento 3 vazio"
    echo $mg
    exit 1
fi

if [[ $a2 = 0 ]]; then 
    a2=$(echo "9^8" | bc)
fi

# - CREATE DIRECTORY AND FILES -

[ ! -d $mon ] && mkdir $mon

if [ ! -f $a3 ];then

    touch $mon/${when}_${a3}_${a1}

fi

# -  RUN LOOP -

for ((i=1;i<$a2;i++));do

    report=$(ping $a1 -c 3 -i 0.2 -W 1)
    loss=$(echo "$report" | grep -oP '\d+(?=% packet loss)')

    if [ "$loss" -eq 100  ];then

        if [[ $dw -eq 0 && $lp -gt 0 ]];then

            date_dw=$(date +%s%3N)
            echo -e "$vm NO-PING $a1 at $(date +%Y-%m-%d-%H:%M:%S.%3N) DW $cl" >> $mon/${when}_${a3}_${a1}
            dw=1
            lp=0

        else

            lp=$((lp  + 1))

        fi

    elif [ $dw -eq 1 ]; then

        date_up=$(date +%s%3N)
        diff=$(($date_up - $date_dw))
        diff_seg=$(LC_NUMERIC=C awk "BEGIN { printf \"%.3f\", $diff/1000 }")
        comp=$(echo "$diff_seg >= 0.3" | bc)

        if [[ $comp = 1 ]];then

                echo -e "$vd PING-OK $a1 at $(date +%Y-%m-%d-%H:%M:%S.%3N) [$diff_seg seg] UP $cl" >> $mon/${when}_${a3}_${a1}

        fi

        dw=0

    else

        lp=0

    fi

done

exit 0 
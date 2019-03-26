#!/bin/bash

which phytool > /dev/null
if [ $? -ne 0 ]; then
   exit
fi


for page in {0..31}
do
echo "Page $page"
phytool write eth0/0/22 $page
    for i in {0..31}
    do
        val="$(phytool read eth0/0/$i)"
        if [ "$val" == "0000" ]; then
            val="0x0000"
        fi
        val="$(echo $val | gawk -Fx '{print $2}')"
        echo -n $val" "
        if [ $i -eq 15 ]; then 
            echo ""
        fi
    done
    phytool write eth0/0/22 0
    echo ""
done
phytool write eth0/0/22 0



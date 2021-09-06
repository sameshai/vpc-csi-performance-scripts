#!/bin/sh
SECONDS=0
while true
do

        kubectl get pods $1 -o wide | grep 'Running'; rc=$?
        if [[ $rc -eq 0 ]]; then
                duration=$SECONDS
                echo "Pod $1 is in running state. $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed" >> $2.log
                break
        fi
done
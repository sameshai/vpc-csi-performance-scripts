#!/bin/sh
NO_OF_VOLUMES=$NO_OF_VOLUMES
SECONDS=0
while true
do
  
        kubectl get nodes $1 -o yaml | grep devicePath | wc -l | grep $NO_OF_VOLUMES; rc=$?
        if [[ $rc -eq 0 ]]; then
                duration=$SECONDS
    		echo "All 11 volumes Attached to Node $1. $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed" >> $2.log
                break
        fi
done

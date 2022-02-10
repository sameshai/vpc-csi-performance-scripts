#!/bin/sh
SCALE_DOWN_PODS=$SCALE_DOWN_PODS
ITERATIONS=$ITERATIONS
APP_NAME=$APP_NAME
POD_NAME=$POD_NAME
SCALE_UP_PODS=$SCALE_UP_PODS

scale_down()
{
    j=0
    volume_attached=0

    # declare -a pvc_array
    # declare -a pv_array

    # pvc_array=( $(kubectl get po -l app=$APP_NAME -o json | jq -j '.items[] | "\(.metadata.namespace), \(.metadata.name), \(.spec.volumes[].persistentVolumeClaim.claimName)\n"' | grep -v null | awk '{print $3}') )

    # for i in "${pvc_array[@]}"
    # do
    #     pv_array[j]=$(kubectl get pvc $i | awk '{if (NR!=1) {print $3} }')
    #     j=$(( $j + 1 ))
    # done

    kubectl scale --replicas=$SCALE_DOWN_PODS statefulset $POD_NAME
    sleep 70
    # SECONDS=0
    # while true
    # do
    #         j=0
    #         for i in "${pv_array[@]}"
    #         do
    #                 kubectl get volumeattachments | grep true | grep $i > /dev/null; rc=$?
    #                 if [[ $rc -eq 0 ]]; then
    #                         volume_attached=1
    #                         break
    #                 else
    #                         unset 'pv_array[$j]'
    #                 fi

    #                 j=$(( $j + 1 ))
    #         done

    #         #If all volumes are detached exit
    #         if [[ $volume_attached -eq 0 ]]; then
    #                         duration=$SECONDS
    #                         echo "All volumes detached for statefulset-$POD_NAME , app-$APP_NAME. $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed" >> detach.log
    #                         break
    #         fi

    #         volume_attached=0       
    # done
}

scale_up()
{
    SECONDS=0
    kubectl scale --replicas=$SCALE_UP_PODS statefulset $POD_NAME
    sleep 5s
    collect_status
}

collect_status()
{
    for i in `kubectl get pods -l app=$APP_NAME -o wide | awk '{if (NR!=1) {print $1} }'`;
    do
            logFile=$i-$(date +"%Y_%m_%d_%I_%M_%p")
        echo "Checking pod status for " "'$i'" " POD" > $logFile.log
        ./PodStatus.sh $i $logFile &
        ./NodeStatus.sh $(kubectl get pods $i -o wide | awk '{if (NR!=1) {print $7} }') $logFile &
    done
    echo "Done!"
}

x=1
echo "Starting performance state for scale-up and scale-down"
while [ $x -le $ITERATIONS ]
do
    echo "Iteration $x starts............."
    echo "Scaling down.."
    scale_down
    echo "Scaling down complete.."
    echo "Scaling up started.."
    scale_up
    SECONDS=0
    while true
    do
        echo "Waiting for Pods to be in running state.."
        duration=$SECONDS
        #Timeout after 30mins we don't want to hang here
        if [ $duration -ge 1800 ]; then
            echo "Timeout Pods not going in running state"
            exit 1
        fi

        kubectl get pods -l app=$APP_NAME | grep 'Running' | wc -l | grep $SCALE_UP_PODS; rc=$?

        if [[ $rc -eq 0 ]]; then
            echo "All Pods for iteration $x are in running state in $duration time" >> Iteration.log
            echo "Scaling up completed.."
            break
        fi
    done
    echo "Iteration $x ends............."
    x=$(( $x + 1 ))
    sleep 5
done

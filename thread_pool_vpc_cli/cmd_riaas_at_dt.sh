#!/bin/bash
##########################################
# Developed By: Arashad Ahamad           #
# Email ID:     arahamad@in.ibm.com      #
##########################################

#INSTANCE_ID=${INSTANCE_ID:-"0727_c72d0981-e2a1-40ea-ad04-5a717ab4e2cb"}
IN=$4

WAIT_TIME=5
ATTEMPT=200

#REDIRECT="2>&1"
BACKGROUND="&"

attach_volume_cmd()
{	
	local startTime=`date +%s`
	local aWTime=0
	local aAttempt=0
	local aAccepted=false
	local aAtWait=0  # How much Time attach_volume_cmd method wait for attachment accept
	local vAcceptStartTime=0  # start time once RIaaS accepted volume attachment

	while [ $aAttempt -lt $ATTEMPT ]
	do
		echo "Attachment attempt for $i volume: " $aAttempt "at " "`date`" >> attach_$1 $REDIRECT
		ibmcloud is in-vola attname$1 $IN $1 >> attach_$1 $REDIRECT
		if [ $? == 0 ]; then
			aAccepted=true
			vAcceptStartTime=`date +%s`
			break
		fi
		echo "Current status for instance" >> attach_$1 $REDIRECT
		ibmcloud is in-vols $IN --json >> attach_$1 $REDIRECT

		sleep $WAIT_TIME
		aAtWait=$(($aAtWait + $WAIT_TIME))
		aAttempt=$(($aAttempt + 1))
	done

	echo "Total wait for attachment acceptance: " $aAtWait >> attach_$1 $REDIRECT
	echo "Check Attachment accepted or not just after" >> attach_$1 $REDIRECT
	ibmcloud is in-vols $IN --json | grep attname$1 >> attach_$1 $REDIRECT
	if [ $? == 0 ]; then
		echo "Atatchment found" >> attach_$1 $REDIRECT
	else
		echo "Attachment not found" >> attach_$1 $REDIRECT
	fi


	echo "Lets wait for attachment success" >> attach_$1 $REDIRECT
        local wAttempt=0
	local isSuccess=false
	while [ $wAttempt -lt $ATTEMPT ] && [ "$aAccepted" == "true" ]
	do
		echo "Wait attempt for $i volume attachment success: " $wAttempt "at " `date` >> attach_$1 $REDIRECT
		ibmcloud is in-vols $IN --json | grep attname$1 -A 1 -B 1 | grep "attached" >> attach_$1 $REDIRECT
		if [ $? == 0 ]; then
			echo "SUCCESSFULY attached volume" >> attach_$1 $REDIRECT
			isSuccess=true
                        break
                fi

		echo "\n\n Instance status for attachment " "at " `date` "\n\n" >> attach_$1 $REDIRECT
                ibmcloud is in-vols $IN --json >> attach_$1 $REDIRECT

		sleep $WAIT_TIME
		aWTime=$(($aWTime + $WAIT_TIME))
		wAttempt=$(($wAttempt + 1))
	done
	echo "Volume attachment accepted at " $vAcceptStartTime >> attach_$1 $REDIRECT
	echo "WAIT TIME for $1 volume atatchment(Include accept and wait attached): " $(($aWTime + $aAtWait)) " seconds" >> attach_$1 $REDIRECT
	local endTime=`date +%s`
	echo "Volume attachment end Time: " $endTime >> attach_$1 $REDIRECT
	if [ "$isSuccess" == "true" ]; then
		echo "ACTUAL ATTACHING TIME TAKEN BY CLIENT for volume $1: " $(($endTime - $startTime)) " seconds" >> attach_$1 $REDIRECT
		echo "ACTUAL ATTACHING TIME TAKEN BY RIaaS(including network performance & cmd execution) by volume $1 : " $(($endTime - $vAcceptStartTime)) " seconds" >> attach_$1 $REDIRECT
	else
		echo "FAILED ATTACHMNET for volume " $1 >> attach_$1 $REDIRECT
	fi
}

detach_attachment_cmd()
{
	local startTime=`date +%s`
	local dWTime=0
	local dAttempt=0
	local dSAttempt=false
	local dWaitTime=0
	local vdAcceptStartTime=0 # start time once RIaaS accepted volume detachment
	while [ $dAttempt -lt $ATTEMPT ]
        do
		echo "Detaching attempt no. " $dAttempt "at " `date` >> detach_$1 $REDIRECT
                ibmcloud is in-vold $IN $1 -f >> detach_$1 $REDIRECT
                if [ $? == 0 ]; then
			dSAttempt=true
			vdAcceptStartTime=`date +%s`
                        break
                fi
                sleep $WAIT_TIME
		dWaitTime=$(($dWaitTime + $WAIT_TIME))
		dAttempt=$(($dAttempt + 1))
        done

	echo "Total wait for detach acceptance:" $dWaitTime >> detach_$1 $REDIRECT
	echo "Wait for attachment deletion" >> detach_$1 $REDIRECT
	local dwAttempt=0
	local isDSuccess=false
        while [ $dwAttempt -lt $ATTEMPT ] && [ "$dSAttempt" == "true" ]
        do
		echo "Detach wait attempt no. " $dwAttempt "at " `date` >> detach_$1 $REDIRECT
                ibmcloud is in-vols $IN --json | grep $1 >> detach_$1 $REDIRECT
                if [ $? == 0 ]; then
                        echo "Attachment still not detached" >> detach_$1 $REDIRECT
		else
			isDSuccess=true
			echo "SUCCESSFULY deleted attachment" >> detach_$1 $REDIRECT
			break
                fi
		echo "\n\n Instance status for attachment " "at " `date` "\n\n" >> detach_$1 $REDIRECT
		ibmcloud is in-vols $IN --json >> detach_$1 $REDIRECT

                sleep $WAIT_TIME
		dWTime=$(($dWTime + $WAIT_TIME))
		dwAttempt=$(($dwAttempt + 1))
        done
	echo "WAIT TIME for attachment deletion(Include accept and detach ): " $(($dWTime + $dWaitTime)) " seconds" >> detach_$1 $REDIRECT
	echo "Detachment accepted at " $vdAcceptStartTime >> detach_$1 $REDIRECT
	local endTime=`date +%s`
	echo "Detach end time: " $endTime >> detach_$1 $REDIRECT
	if [ "$isDSuccess" == "true" ]; then
		echo "ACTUAL DETACHING TIME TAKE BY CLIENT for $1 attachment: " $(($endTime - $startTime)) " seconds" >> detach_$1 $REDIRECT
		echo "ACTUAL DETACHING TIME TAKE BY RIaaS(including network performance & execution) by $1 attachment: " $(($endTime - $vdAcceptStartTime)) " seconds" >> detach_$1 $REDIRECT
	else
		echo "FAILED DETACHMENT for attachment ID " $1 >> detach_$1 $REDIRECT
	fi
}

attach()
{
	echo "In Atatch" >> attach.log $REDIRECT
	for i in $1
	do
		echo "Calling attach for " $i "volume" >> attach.log $REDIRECT
		if [ "$2" == "PR" ]; then
			attach_volume_cmd $i &
		else
			attach_volume_cmd $i
		fi
	done
}

detach()
{
	echo "In Detach" >> detach.log $REDIRECT
	for i in $1
        do
                echo "Calling detach for " $i "attachment id" >> detach.log $REDIRECT
		if [ "$2" == "PR" ]; then
                	detach_attachment_cmd $i &
		else
			detach_attachment_cmd $i
		fi
        done
}

migrate()
{
	echo "Migrating volume $1 from $IN to $2 instance"
	echo "First attaching to existing instance"
	attach "$1"	

	echo "Detaching volume  from existing instance"
	detach "$1"

	echo "Attaching to new instance $2"
	IN=$2
	attach "$1"
}

echo "Selected action is:" $1 >> main_execution.log $REDIRECT
echo "Volume/attachment details:" $2 >> main_execution.log $REDIRECT

if [ "$1" == "AT" ]; then
	echo "Calling Attach" >> main_execution.log $REDIRECT
	if [ "$3" == "PR" ]; then
		attach "$2" "PR"
	elif [ "$3" == "SE" ]; then
		attach "$2" "SE"
	else
		echo "Wrong option, please provide 3rd parameter as PR or SE"
	fi
elif [ "$1" == "DT" ]; then
	echo "Calling Detach" >> main_execution.log $REDIRECT
	if [ "$3" == "PR" ]; then
		detach "$2" "PR"
	elif [ "$3" == "SE" ]; then
		detach "$2" "SE"
	else
		echo "Wrong option, please provide 3rd parameter as PR or SE"
	fi
elif [ "$1" == "MG" ]; then
	echo "Calling migration" >> main_execution.log $REDIRECT
	migrate "$2" "$3"
else
	echo "Wrong option" >> main_execution.log $REDIRECT
fi 

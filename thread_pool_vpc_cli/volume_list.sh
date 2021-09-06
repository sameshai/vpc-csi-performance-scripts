#!/bin/bash
##########################################
# Developed By: Sameer Shaikh          #
# Email ID:     sameer.shaikh@in.ibm.com      #
##########################################

VOL_FILTER=${VOL_FILTER:-"vsi-vol"}
VOL_NUMBER=${VOL_NUMBER:-11}

run_attach()
{
	:> volume_list.log
	k=0
	node_array=(0727_c72d0981-e2a1-40ea-ad04-5a717ab4e2cb 0727_91070f58-c2e8-4e52-a9a9-1aa5f937359a 0727_2a28ff3b-1d76-47d3-83f2-4725e5f680d6 0727_bf9176cc-a12f-4eeb-bd7b-2933fcdcdd22 0727_f4526808-0e8b-4909-86d9-93cae7e363ca 0727_8340bc4f-d1c9-4878-9d76-7453bf6bb61c)

	for j in "${node_array[@]}"
    do
		VOL_FILTER="vsi-vol"
		
		if [ $k -ne 0 ]; then
			VOL_FILTER=$VOL_FILTER$(( $k + 1 ))
		fi

		echo $VOL_FILTER
        local vIDs=""
		for i in `ibmcloud is vols | grep $VOL_FILTER | grep 5iops-tier | awk '{print $1 " " $7}' | awk '{print $1}' | head -$VOL_NUMBER`
		do
			vIDs="$vIDs $i"
		done
		echo "$j$vIDs" >> volume_list.log
        k=$(( $k + 1 ))
    done
	
}

run_attach

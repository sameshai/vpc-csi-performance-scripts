#!/bin/bash
##########################################
# Developed By: Sameer Shaikh          #
# Email ID:     sameer.shaikh@in.ibm.com      #
##########################################
run_detach()
{
	#attachment ID size is bigger in NG
	local detachIDSize=41
	:> attachment_list.log
	node_array=(0727_c72d0981-e2a1-40ea-ad04-5a717ab4e2cb 0727_91070f58-c2e8-4e52-a9a9-1aa5f937359a 0727_2a28ff3b-1d76-47d3-83f2-4725e5f680d6 0727_bf9176cc-a12f-4eeb-bd7b-2933fcdcdd22 0727_f4526808-0e8b-4909-86d9-93cae7e363ca 0727_8340bc4f-d1c9-4878-9d76-7453bf6bb61c )

	for j in "${node_array[@]}"
    do

		local atIDs=""
		for i in `ibmcloud is in-vols $j --json | grep -B 3 '"type": "data"' | grep "id" | awk '{print $2}'`
			do
			atID=${i:1:$detachIDSize}
			atIDs="$atIDs $atID"
			done
		echo "$j$atIDs" >> attachment_list.log
	done
}

run_detach



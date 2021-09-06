

# thread_pool_vpc_cli

1.) Make sure you do ibmcloud login in respective region 
2.) Modify and run volume_list.sh as per your volume filters this will generate log file that go program will require in my case it is (vsi-vol, vsi-vol2, vsi-vol3, vsi-vol4, vsi-vol5, vsi-vol6) 11 volumes for each filter (66 volumes)
3.) Run —> time go run worker-pool.go


# measure_pod_up_time

1.) Export below values
export SCALE_DOWN_PODS=0
export ITERATIONS=10
export APP_NAME=nginx
export POD_NAME=web
export SCALE_UP_PODS=6
export NO_OF_VOLUMES=11
2.) Run ./performTest.sh


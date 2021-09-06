package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"
)

func RemoveIndex(s []string, index int) []string {
	return append(s[:index], s[index+1:]...)
}

func worker(id int, jobs <-chan job, results chan<- int) {
	for j := range jobs {
		start := time.Now()
		fmt.Println("worker", id, "started  job", j)
		var md *exec.Cmd

		if j.oper == "AT" {
			md = exec.Command("./cmd_riaas_at_dt.sh", j.oper, j.volID, "SE", j.instanceID)
		} else {
			md = exec.Command("./cmd_riaas_at_dt.sh", j.oper, j.attID, "SE", j.instanceID)
		}

		if err := md.Start(); err != nil {
			fmt.Printf("Failed to start cmd: %v", err)
			return
		}

		// And when you need to wait for the command to finish:
		if err := md.Wait(); err != nil {
			log.Printf("Cmd returned error: %v", err)
		}
		fmt.Println("worker", id, "finished job", j, " in ", time.Since(start))
		results <- j.jobID * 2
	}
}

type job struct {
	jobID      int
	volID      string
	instanceID string
	oper       string
	attID      string
}

func detach() []job {

	fmt.Println("Preparing Detaching List...........")

	//Execute the attach_list script which will prepare the list of attachment for respective instance id.
	//Format of file is <instance-id> followed by 11 <attachment-ids>. New line for each instance-id
	md := exec.Command("./attach_list.sh")

	if err := md.Start(); err != nil {
		fmt.Printf("Failed to start cmd: %v", err)
		return nil
	}

	// And when you need to wait for the command to finish:
	if err := md.Wait(); err != nil {
		log.Printf("Cmd returned error: %v", err)
	}

	// os.Open() opens specific file in
	// read-only mode and this return
	// a pointer of type os.
	file, err := os.Open("attachment_list.log")

	if err != nil {
		log.Fatalf("failed to open")

	}

	// The bufio.NewScanner() function is called in which the
	// object os.File passed as its parameter and this returns a
	// object bufio.Scanner which is further used on the
	// bufio.Scanner.Split() method.
	scanner := bufio.NewScanner(file)

	// The bufio.ScanLines is used as an
	// input to the method bufio.Scanner.Split()
	// and then the scanning forwards to each
	// new line using the bufio.Scanner.Scan()
	// method.
	scanner.Split(bufio.ScanLines)
	var read_lines []string

	for scanner.Scan() {
		read_lines = append(read_lines, scanner.Text())
	}

	// The method os.File.Close() is called
	// on the os.File object to close the file
	file.Close()

	type vsiSet map[string][]string

	// and then a loop iterates through
	// and prints each of the slice values.
	vsiList := make(vsiSet)
	for _, vsi := range read_lines {
		s := strings.Split(vsi, " ")
		temp := s[0]
		s = RemoveIndex(s, 0)
		vsiList[temp] = s
	}

	//fmt.Println(vsiList)
	var detachJobList = make([]job, 132)

	j := 0
	for instance_id, node := range vsiList {
		//fmt.Println("Node --", node)

		for _, attach := range node {
			//fmt.Println("Attach --", attach)

			temp_job := job{
				jobID:      j + 1,
				instanceID: instance_id,
				oper:       "DT",
				attID:      attach,
			}
			detachJobList[j] = temp_job
			j = j + 1
		}

	}

	//fmt.Println(detachJobList)
	return detachJobList

}

func attach(job_arr []job) []job {

	fmt.Println("Preparing Attaching List...........")

	// os.Open() opens specific file in
	// read-only mode and this return
	// a pointer of type os.
	//Format of file is <instance-id> followed by 11 <volume-ids>. New line for each instance-id
	file, err := os.Open("volume_list.log")

	if err != nil {
		log.Fatalf("failed to open")

	}

	// The bufio.NewScanner() function is called in which the
	// object os.File passed as its parameter and this returns a
	// object bufio.Scanner which is further used on the
	// bufio.Scanner.Split() method.
	scanner := bufio.NewScanner(file)

	// The bufio.ScanLines is used as an
	// input to the method bufio.Scanner.Split()
	// and then the scanning forwards to each
	// new line using the bufio.Scanner.Scan()
	// method.
	scanner.Split(bufio.ScanLines)
	var read_lines []string

	for scanner.Scan() {
		read_lines = append(read_lines, scanner.Text())
	}

	// The method os.File.Close() is called
	// on the os.File object to close the file
	file.Close()

	type vsiVolSet map[string][]string

	// and then a loop iterates through
	// and prints each of the slice values.
	vsiVolList := make(vsiVolSet)
	for _, vsi := range read_lines {
		s := strings.Split(vsi, " ")
		temp := s[0]
		s = RemoveIndex(s, 0)
		vsiVolList[temp] = s
	}

	//fmt.Println(vsiVolList)

	j := 66
	for instance_id, node := range vsiVolList {
		//fmt.Println("Node --", node)

		for _, volume := range node {
			//fmt.Println("Volume --", volume)

			temp_job := job{
				jobID:      j + 1,
				instanceID: instance_id,
				oper:       "AT",
				volID:      volume,
			}
			job_arr[j] = temp_job
			j = j + 1
		}

	}

	//fmt.Println(job_arr)
	return job_arr
}

func main() {

	start := time.Now()
	job_arr := detach()
	job_arr = attach(job_arr)

	//fmt.Println(job_arr)

	const numJobs = 132
	jobs := make(chan job, numJobs)
	results := make(chan int, numJobs)

	for w := 1; w <= 10; w++ {
		go worker(w, jobs, results)
	}

	for j := 0; j < numJobs; j++ {

		jobs <- job_arr[j]
	}

	close(jobs)

	for a := 1; a <= numJobs; a++ {
		<-results
	}

	fmt.Println("Total Time taken", time.Since(start))
}

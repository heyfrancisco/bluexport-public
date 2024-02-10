#!/bin/bash
#
# Usage:    ./bluexport.sh [ -a | -x volumes_name_to_exclude ] [VSI_Name_to_Capture] [Capture_Image_Name] [both|image-catalog|cloud-storage] [daily | monthly | single]
#
# Example:  ./bluexport.sh -a namdr namdr_img image-catalog daily ---- Excludes Volumes with ASP2_ in the name and exports to image catalog
# Example:  ./bluexport.sh -x ASP2_ namdr namdr_img both monthly    ---- Includes all Volumes and exports to COS and image catalog
#
# Capture IBM Cloud POWERVS VSI and Export to COS or/and Image Catalog
#
# Ricardo Martins - Blue Chip Portugal © 2024
#######################################################################################

       #####  START:CODE  #####

####  START: Constants Definition  #####
Version=1.6.4
bluexscrt="$HOME/bluexscrt"
log_file="$HOME/bluexport.log"
capture_time=`date +%Y-%m-%d_%H%M`
flagj=0
job_log="$HOME/bluex_job.log"
job_test_log="$HOME/bluex_job_test.log"
job_id="$HOME/bluex_job_id.log"
job_log_short="$HOME/bluex_job"
job_monitor="$HOME/bluex_job_monitor.tmp"
vsi_list_id_tmp="$HOME/bluex_vsi_list_id.tmp"
vsi_list_tmp="$HOME/bluex_vsi_list.tmp"
volumes_file="$HOME/bluex_volumes_file.tmp"
end_log_file='==== END ========= $timestamp ========='
single=0
####  END: Constants Definition  #####

####  START: Check if Config File exists  ####
if [ ! -f $bluexscrt ]
then
	echo "" >> $log_file
	timestamp=$(date +%F" "%T" "%Z)
	echo "==== START ======= $timestamp =========" >> $log_file
	echo "`date +%Y-%m-%d_%H:%M:%S` - Config file $bluexscrt Missing!! Aborting!..." >> $log_file
	echo "==== END ========= $timestamp =========" >> $log_file
	echo "" >> $log_file
	exit 0
fi
####  END: Check if Config File exists  ####

####  START: Get Cloud Config Data  #####
accesskey=$(cat $bluexscrt | grep "ACCESSKEY" | awk {'print $2'})
secretkey=$(cat $bluexscrt | grep "SECRETKEY" | awk {'print $2'})
bucket=$(cat $bluexscrt | grep "BUCKETNAME" | awk {'print $2'})
apikey=$(cat $bluexscrt | grep "APYKEY" | awk {'print $2'})
powervsdcdr=$(cat $bluexscrt | grep "POWERVSDR" | awk {'print $2'})
powervsdcprd=$(cat $bluexscrt | grep "POWERVSPRD" | awk {'print $2'})
region=$(cat $bluexscrt | grep "REGION" | awk {'print $2'})
####  END: Get Cloud Config Data  #####

       #####  START: FUNCTIONS  #####

#### START:FUNCTION - Finish log file when aborting  ####
abort() {
	echo $1 >> $log_file
	timestamp=$(date +%F" "%T" "%Z)
	eval echo $end_log_file >> $log_file
	exit 0
}
#### END:FUNCTION - Finish log file when aborting  ####

#### START:FUNCTION - Check if image-catalog as images from last saturday and deleted it ####
delete_previous_img() {
	img_id_old=$(/usr/local/bin/ibmcloud pi imgs --long | grep $vsi | grep $old_img | awk {'print $1'})
	img_name_old=$(/usr/local/bin/ibmcloud pi imgs --long | grep $vsi | grep $old_img | awk {'print $2'})
	if [ ! $img_id_old ]
	then
		echo "There is no Image from $old_img - Nothing to delete." >> $log_file
	else
		echo "== Deleting image name $img_name_old - image ID $img_id_old - from day $old_img... ==" >> $log_file
		sh -c '/usr/local/bin/ibmcloud pi imgd '$img_id_old 2>> $log_file
	fi
}
#### END:FUNCTION - Check if image-catalog as images from last saturday and deleted it ####

####  START:FUNCTION - Target DC and List all VSI in the POWERVS DC and Get VSI Name and ID  ####
dc_vsi_list() {
	sh -c '/usr/local/bin/ibmcloud pi st '$1 2>> $log_file
    # List all VSI in this POWERVS DC and Get VSI Name and ID #
	sh -c '/usr/local/bin/ibmcloud pi ins | awk {'\''print $1" "$2'\''} | tail -n +2' > $vsi_list_id_tmp 2>> $log_file
	vsi_id=$(cat $vsi_list_id_tmp | grep $vsi | awk {'print $1'})
	cat $vsi_list_id_tmp | awk {'print $2'} > $vsi_list_tmp
}
####  END:FUNCTION - Target DC and List all VSI in the POWERVS DC and Get VSI Name and ID  ####

####  START:FUNCTION - Monitor Capture and Export Job  ####
job_monitor() {
    # Get Capture & Export Job ID #
	echo "`date +%Y-%m-%d_%H:%M:%S` - Job log in file $job_log" >> $log_file
	if [ $flagj -eq 1 ]
	then
		job=$(sh -c '/usr/local/bin/ibmcloud pi jobs | grep -B7 '$capture_name' | grep "Job ID" | awk {'\''print $3'\''}' 2>> $log_file)
	else
		job=$(cat $job_id | grep "Job ID " | awk {'print $3'})
	fi
    # Check Capture & Export Job Status #
	echo "Job Monitoring of VM Capture "$capture_name" - Job ID:" $job >> $job_log
	while true
	do
		sh -c '/usr/local/bin/ibmcloud pi job '$job 1> $job_monitor 2>>$job_log
		job_status=$(cat $job_monitor | grep "State " | awk {'print $2'})
		message=$(cat $job_monitor |grep "Message" | cut -f 2- -d ' ')
		operation=$(cat $job_monitor |grep "Message" | cut -f 2- -d ' '| sed 's/::/ /g' | awk {'print $3'})
		if [[ $job_status == "completed" ]]
		then
			if [[ $destination == "cloud-storage" ]]
			then
				echo "`date +%Y-%m-%d_%H:%M:%S` - Image Capture and Export of $vsi to Bucket $bucket Completed !!" >> $log_file
			elif [[ $destination == "both" ]]
			then
				echo "`date +%Y-%m-%d_%H:%M:%S` - Image Capture and Export of $vsi to Image Catalog Completed !!" >> $log_file
				echo "`date +%Y-%m-%d_%H:%M:%S` - Image Capture and Export of $vsi to Bucket $bucket Completed !!" >> $log_file
			else
				echo "`date +%Y-%m-%d_%H:%M:%S` - Image Capture and Export of $vsi to Image Catalog Completed !!" >> $log_file
			fi
			if [ $single -eq  0 ]
			then
				delete_previous_img
			fi
			echo "`date +%Y-%m-%d_%H:%M:%S` - Finished Successfully!!" >> $job_log
			job_log_perm=$job_log_short"_"$capture_name".log"
			cp $job_log $job_log_perm
			abort "`date +%Y-%m-%d_%H:%M:%S` - Finished Successfully!!"
		elif [[ $job_status == "" ]]
		then
			echo "`date +%Y-%m-%d_%H:%M:%S` - FAILED Getting Job ID or no Job Running!" >> $log_file
			abort "`date +%Y-%m-%d_%H:%M:%S` - Check file $job_monitor for more details."
		elif [[ $job_status == "failed" ]]
		then
			echo "`date +%Y-%m-%d_%H:%M:%S` - Job ID "$job" Status:" ${job_status^^} >> $log_file
			echo "`date +%Y-%m-%d_%H:%M:%S` - Message:" $message >> $log_file
			abort "`date +%Y-%m-%d_%H:%M:%S` - Job Failed, check message!!"
		else
			if [[ $operation != $operation_before ]]
			then
				echo "`date +%Y-%m-%d_%H:%M:%S` - Job ID "$job" Status:" ${job_status^^} >> $log_file
				echo "`date +%Y-%m-%d_%H:%M:%S` - Message:" $message >> $log_file
				echo "`date +%Y-%m-%d_%H:%M:%S` - Waiting for Operation Change... Operation Running Now:" ${operation^^} >> $log_file
				echo "`date +%Y-%m-%d_%H:%M:%S` - Running "${operation^^}"... Sleeping 60 seconds..." >> $job_log
				sleep 60
				operation_before=$operation
			else
				echo "`date +%Y-%m-%d_%H:%M:%S` - Still Running "${operation^^}"... Sleeping 60 seconds..." >> $job_log
				sleep 60
			fi
		fi
	done
}
####  END:FUNCTION - Monitor Capture and Export Job  ####

####  START:FUNCTION - Login in IBM Cloud  ####
cloud_login() {
	/usr/local/bin/ibmcloud login --apikey $apikey -r $region 2>&1 > /dev/null
}
####  END:FUNCTION - Login in IBM Cloud  ####

####  START:FUNCTION - Get IASP name  ####
get_IASP_name() {
	echo "`date +%Y-%m-%d_%H:%M:%S` - Getting $vsi IASP Name..." >> $log_file
	vsi_ip=$(cat $bluexscrt | grep $vsi | awk {'print $2'})
	if ping -c1 -w3 $vsi_ip &> /dev/null
	then
		echo "`date +%Y-%m-%d_%H:%M:%S` - Ping VSI $vsi OK." >> $log_file
	else
		abort "`date +%Y-%m-%d_%H:%M:%S` - Cannot ping VSI $vsi ! Aborting..."
	fi
	ssh -q qsecofr@$vsi_ip exit
	if [ $? -eq 255 ]
	then
		abort "`date +%Y-%m-%d_%H:%M:%S` - Unable to SSH to $vsi and not able to get IASP status! Try STRTCPSVR *SSHD on the $vsi VSI. Aborting..."
	else
		iasp_name=$(ssh qsecofr@$vsi_ip 'ls -l / | grep " IASP"' | awk {'print $9'})
		if [[ $iasp_name == "" ]]
		then
			echo "`date +%Y-%m-%d_%H:%M:%S` - VSI $vsi doesn't have IASP or it is Varied OFF" >> $log_file
		else
			echo "`date +%Y-%m-%d_%H:%M:%S` - VSI $vsi IASP Name: $iasp_name" >> $log_file
		fi
	fi
}
####  END:FUNCTION - Get IASP name  ####

####  START:FUNCTION - Check if VSI exists and Get VSI IP and IASP NAME if exists  ####
check_VSI_exists() {
	echo "" > $job_log
   ## Target PRD DC ##
	echo "`date +%Y-%m-%d_%H:%M:%S` - Searching for VSI in PRD DC..." >> $log_file
	dc_vsi_list $powervsdcprd
	if_ctl=0
	if grep -qe ^$vsi$ $vsi_list_tmp
	then
		echo "`date +%Y-%m-%d_%H:%M:%S` - VSI to Capture: $vsi" >> $log_file
		if [ $flagj -eq 0 ]
		then
		get_IASP_name
		fi
		if_ctl=1
	elif [ $if_ctl -eq  0 ]
	then
		echo "`date +%Y-%m-%d_%H:%M:%S` - VSI $vsi doesn't exist in PRD DC!" >> $log_file
		echo "`date +%Y-%m-%d_%H:%M:%S` - Searching for VSI in DR DC..." >> $log_file
   ## Target DR DC ##
		dc_vsi_list $powervsdcdr
		if grep -qe ^$vsi$ $vsi_list_tmp
		then
		echo "`date +%Y-%m-%d_%H:%M:%S` - VSI to Capture: $vsi" >> $log_file
			if [ $flagj -eq 0 ]
			then
				get_IASP_name
			fi
		if_ctl=1
		fi
	fi
	if [ "$if_ctl" -eq  0 ]
	then
        	abort "`date +%Y-%m-%d_%H:%M:%S` - VSI $vsi doesn't exist!"
	fi
}
####  END:FUNCTION - Check if VSI exists and Get VSI IP and IASP NAME if exists  ####

       ####  END - FUNCTIONS  ####

####  START: Iniciate Log and Validate Arguments  ####
timestamp=$(date +%F" "%T" "%Z)
echo "==== START ======= $timestamp =========" >> $log_file

if [ $# -eq 0 ]
then
	abort "`date +%Y-%m-%d_%H:%M:%S` - No arguments supplied!!"
fi

case $1 in

   -j)
	if [ $# -lt 3 ]
	then
		echo "Flag -j selected, but Arguments Missing!! Syntax: bluexport -j VSI_NAME IMAGE_NAME"
		abort "`date +%Y-%m-%d_%H:%M:%S` - Flag -j selected, but Arguments Missing!! Syntax: bluexport -j VSI_NAME IMAGE_NAME"
	fi
	vsi=${2^^}
	capture_name=${3^^}
	echo "`date +%Y-%m-%d_%H:%M:%S` - Flag -j selected, watching only the Job Status for Capture Image $capture_name! Logging at $HOME/bluexport_j_"$capture_name".log" >> $log_file
	timestamp=$(date +%F" "%T" "%Z)
	echo "==== END ========= $timestamp =========" >> $log_file
	flagj=1
	log_file="$HOME/bluexport_j_"$capture_name".log"
	echo "" > $log_file
	timestamp=$(date +%F" "%T" "%Z)
	echo "==== START ======= $timestamp =========" >> $log_file
	cloud_login
	check_VSI_exists
	job_monitor
    ;;

   -a | -ta)
	if [ $# -lt 5 ]
	then
		abort "`date +%Y-%m-%d_%H:%M:%S` - Arguments Missing!! Syntax: bluexport $1 VSI_NAME IMAGE_NAME EXPORT_LOCATION [daily|monthly]"
	fi
	if [[ $5 == "daily" ]]
	then
		old_img=$(date --date '1 day ago' "+%Y-%m-%d")
	elif [[ $5 == "monthly" ]]
	then
		old_img=$(date --date '1 month ago' "+%Y-%m-%d")
	elif [[ $5 == "single" ]]
	then
		single=1
	else
		abort "`date +%Y-%m-%d_%H:%M:%S` - Reocurrence must be daily or monthly!"
	fi
	if [[ $1 == "-ta" ]]
	then
		test=1
		echo "`date +%Y-%m-%d_%H:%M:%S` - Flag -t selected. Logging at "$job_test_log >> $log_file
		echo "`date +%Y-%m-%d_%H:%M:%S` - Testing only!! No Capture will be done!" >> $log_file
		timestamp=$(date +%F" "%T" "%Z)
		echo "==== END ========= $timestamp =========" >> $log_file
		log_file=$job_test_log
		timestamp=$(date +%F" "%T" "%Z)
		echo "==== START ======= $timestamp =========" >> $log_file
	else
		test=0
	fi
	vsi=${2^^}
	echo "`date +%Y-%m-%d_%H:%M:%S` - Starting Capture&Export for VSI Name: $vsi ..." >> $log_file
	capture_img_name=${3^^}
	capture_name=$capture_img_name"_"$capture_time
	echo "`date +%Y-%m-%d_%H:%M:%S` - Capture Name: $capture_name" >> $log_file
	destination=$4
	echo "`date +%Y-%m-%d_%H:%M:%S` - Export Destination: $destination" >> $log_file
	if [[ $destination == "both" ]] || [[ $destination == "image-catalog" ]] || [[ $destination == "cloud-storage" ]]
	then
		echo "`date +%Y-%m-%d_%H:%M:%S` - Export Destination $destination is valid!" >> $log_file
	else
		abort "`date +%Y-%m-%d_%H:%M:%S` - Export Destination $destination is NOT valid!"
	fi
	volumes_cmd="/usr/local/bin/ibmcloud pi inlv $vsi | tail -n +2"
    ;;

   -x | -tx)
	if [ $# -lt 6 ]
	then
		abort "`date +%Y-%m-%d_%H:%M:%S` - Arguments Missing!! Syntax: bluexport $1 EXCLUDE_NAME VSI_NAME IMAGE_NAME EXPORT_LOCATION"
	fi
	if [[ $6 == "daily" ]]
	then
		old_img=$(date --date '1 day ago' "+%Y-%m-%d")
	elif [[ $6 == "monthly" ]]
	then
		old_img=$(date --date '1 month ago' "+%Y-%m-%d")
	elif [[ $6 == "single" ]]
	then
		single=1
	else
		abort "`date +%Y-%m-%d_%H:%M:%S` - Reocurrence must be daily or monthly!"
	fi
	if [[ $1 == "-tx" ]]
	then
		test=1
		echo "`date +%Y-%m-%d_%H:%M:%S` - Flag -t selected. Logging at "$job_test_log >> $log_file
		echo "`date +%Y-%m-%d_%H:%M:%S` - Testing only!! No Capture will be done!" >> $log_file
		timestamp=$(date +%F" "%T" "%Z)
		echo "==== END ========= $timestamp =========" >> $log_file
		log_file=$job_test_log
		timestamp=$(date +%F" "%T" "%Z)
		echo "==== START ======= $timestamp =========" >> $log_file
	else
		test=0
	fi
	exclude_name=$2
	echo "`date +%Y-%m-%d_%H:%M:%S` - Volumes Name to exclude: $exclude_name" >> $log_file
	vsi=${3^^}
	echo "`date +%Y-%m-%d_%H:%M:%S` - Starting Capture&Export for VSI Name: $vsi ..." >> $log_file
	capture_img_name=${4^^}
	capture_name=$capture_img_name"_"$capture_time
	echo "`date +%Y-%m-%d_%H:%M:%S` - Capture Name: $capture_name" >> $log_file
	destination=$5
	echo "`date +%Y-%m-%d_%H:%M:%S` - Export Destination: $destination" >> $log_file
	if [[ $destination == "both" ]] || [[ $destination == "image-catalog" ]] || [[ $destination == "cloud-storage" ]]
	then
		echo "`date +%Y-%m-%d_%H:%M:%S` - Export Destination $destination is valid!" >> $log_file
	else
		abort "`date +%Y-%m-%d_%H:%M:%S` - Export Destination $destination is NOT valid!"
	fi
	volumes_cmd="/usr/local/bin/ibmcloud pi inlv $vsi | grep -v "$exclude_name" | tail -n +2"
    ;;

   -v | --version)
	echo "  ### bluexport by RQM - Blue Chip © 2023-2024"
	echo "  ### Version: $Version"
	exit 0
    ;;

    *)
	abort "`date +%Y-%m-%d_%H:%M:%S` - Flag -a or -x Missing or invalid Flag!"
    ;;
esac
####  END: Iniciate Log and Validate Arguments  ####

cloud_login
check_VSI_exists

####  START: Get Volumes to capture  ####
eval $volumes_cmd > $volumes_file
volumes=$(cat $volumes_file | awk {'print $1'} | tr '\n' ' ')
volumes_name=$(cat $volumes_file | awk {'print $2'} | tr '\n' ' ')
echo "`date +%Y-%m-%d_%H:%M:%S` - Volumes ID Captured: $volumes" >> $log_file
echo "`date +%Y-%m-%d_%H:%M:%S` - Volumes Name Captured: $volumes_name" >> $log_file
####  END: Get Volumes to capture  ####

####  START: Flush ASPs and IASP Memory to Disk  ####
if [ $test -eq 0 ]
then
	echo "`date +%Y-%m-%d_%H:%M:%S` - Flushing Memory to Disk for SYSBAS..." >> $log_file
	ssh -T qsecofr@$vsi_ip 'system "CHGASPACT ASPDEV(*SYSBAS) OPTION(*FRCWRT)"' >> $log_file
	if [[ $iasp_name != "" ]]
	then
		echo "`date +%Y-%m-%d_%H:%M:%S` - Flushing Memory to Disk for $iasp_name ..." >> $log_file
		ssh -T qsecofr@$vsi_ip 'system "CHGASPACT ASPDEV('$iasp_name') OPTION(*FRCWRT)"' >> $log_file
	fi
else
	echo "`date +%Y-%m-%d_%H:%M:%S` - Flushing Memory to Disk for SYSBAS..." >> $log_file
	if [[ $iasp_name != "" ]]
	then
		echo "`date +%Y-%m-%d_%H:%M:%S` - Flushing Memory to Disk for $iasp_name ..." >> $log_file
	fi
fi
####  END: Flush ASPs and IASP Memory to Disk  ####

####  START: Make the Capture and Export  ####
if [[ $destination == "image-catalog" ]]
then
	echo "`date +%Y-%m-%d_%H:%M:%S` - == Executing Capture and Export Cloud command... ==" >> $log_file
	if [ $test -eq 1 ]
	then
		echo "/usr/local/bin/ibmcloud pi incap $vsi_id --destination $destination --name $capture_name --volumes \"$volumes\" --job" >> $log_file
	else
		rm $job_id
		/usr/local/bin/ibmcloud pi incap $vsi_id --destination $destination --name $capture_name --volumes "$volumes" --job 2>> $log_file | tee -a $log_file $job_id
	fi
else
	echo "`date +%Y-%m-%d_%H:%M:%S` - == Executing Capture and Export Cloud command... ==" >> $log_file
	if [ $test -eq 1 ]
	then
		echo "/usr/local/bin/ibmcloud pi incap $vsi_id --destination $destination --name $capture_name --volumes \"$volumes\" --access-key $accesskey --secret-key $secretkey --region $region --image-path $bucket --job" >> $log_file
	else
		rm $job_id
		/usr/local/bin/ibmcloud pi incap $vsi_id --destination $destination --name $capture_name --volumes "$volumes" --access-key $accesskey --secret-key $secretkey --region $region --image-path $bucket --job 2>> $log_file | tee -a $log_file $job_id
	fi
fi
####  END: Make the Capture and Export  ####

####  START: Job Monitoring  ####
if [ $test -eq 0 ]
then
	echo "`date +%Y-%m-%d_%H:%M:%S` - => Iniciating Job Monitorization..." >> $log_file
else
	echo "`date +%Y-%m-%d_%H:%M:%S` - => Iniciating Job Monitorization..." >> $log_file
	abort "`date +%Y-%m-%d_%H:%M:%S` - Test Finished!"
fi

job_monitor
####  END: Job Monitoring  ####

       #####  END:CODE  #####

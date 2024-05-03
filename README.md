# bluexport
Capture IBM Cloud POWERVS VSI and Export to COS or/and Image Catalog.  

<h6>This script was made in GNU bash, version 5.1.16(1)-release.</h6>  

#
 Usage:    <h6>./bluexport.sh [ -a | -x volumes_name_to_exclude ] [VSI_Name_to_Capture] [Capture_Image_Name] [both|image-catalog|cloud-storage] [hourly | daily | weekly | monthly | single]</h6>

 Examples:  <h6>./bluexport.sh -a vsi_name capture_img_name image-catalog daily  ---- Includes all Volumes and exports to image catalog, and deletes yesterday image if exists.</h6>
   <h6>./bluexport.sh -x ASP2_ vsi_name capture_img_name both monthly  ---- Excludes Volumes with ASP2_ in the name and exports to image catalog and COS, and deletes last month images if exists.</h6>  

 <h5>Flag t before a or x makes it a test and do not makes the capture</h5>  
 <h5>Example:</h5>  <h6>./bluexport.sh -tx "ASP2_ IASP" vsi_name capture_img_name both monthly ---- Do not makes the export, and makes log in a different log file.</h6>  
 <h6>[hourly | daily | weekly | monthly | single] - This parameter allows the script to delete the image from the previous capture. i.e. If weekly is selected it will try to delete the image from the week before.</h6>
  
 <h6>Note: Reocurrence "hourly" only permits captures to image-catalog</h6>  
  
 *This file is to be run in crontab or in background, it will not have many or none output to screen, it will log in a file.*  
  
*Before running bluexport.sh, first you must configure the file <U>bluexscrt</U> with your IBM Cloud Data.*  
*Replace all <> with your data.*  

  
Content of file bluexscrt before edit:  

```
APYKEY <REPLACE-ALL-THIS-WITH-YOUR-API-KEY>  
WSFRADR <REPLACE-ALL-THIS-WITH-YOUR-POWER-VIRTUAL-SERVER-CRN-i.e.   crn:v1:bluemix:public:power-iaas:blablablablabla::>  
POWERVSPRD <REPLACE-ALL-THIS-WITH-YOUR-POWER-VIRTUAL-SERVER-CRN-i.e.  crn:v1:bluemix:public:power-iaas:blablablablabla::>  
WSFRAPRD <REPLACE-ALL-THIS-WITH-YOUR-POWER-VIRTUAL-SERVER-CRN-i.e.  crn:v1:bluemix:public:power-iaas:blablablablabla::>  
  
ACCESSKEY <REPLACE-ALL-THIS-WITH-YOUR-ACCES-KEY>  
SECRETKEY <REPLACE-ALL-THIS-WITH-YOUR-SECRET-KEY>  
BUCKETNAME <REPLACE-ALL-THIS-WITH-YOUR-BUCKET-NAME>  
REGION <REPLACE-ALL-THIS-WITH-YOUR-REGION>  
  
SERVER1 XXX.XXX.XXX.XXX <SERVER1_VSI_ID>
SERVER2 XXX.XXX.XXX.XXX <SERVER2_VSI_ID>
SERVER3 XXX.XXX.XXX.XXX <SERVER3_VSI_ID>
.  
.  
SERVERN XXX.XXX.XXX.XXX <SERVERN_VSI_ID>

ALLWS WSFRADR POWERVSPRD WSFRAPRD                                                                                                   - The shortnames in this line...
WSNAMES <Power VS Workspace Name of the WSFRADR:Power VS Workspace Name of the POWERVSPRD:Power VS Workspace Name of the WSFRAPRD>  - ...and the long names in this line must be in the same order

VSI_USER vsi_user

SSHKEYPATH /sshkeypath/.ssh/key

```

bluexscrt example:
```
APYKEY bla123BLA321bla345BLA  
WSMADDR crn:v1:bluemix:public:power-iaas:bla123bla321bla345bla123bla::  
WSMADPRD crn:v1:bluemix:public:power-iaas:bla123bla312bla345bla123bla::
WSFRADR crn:v1:bluemix:public:power-iaas:bla123bla312bla543bla123bla::
ACCESSKEY bla123BLAblaBLA  
SECRETKEY bla123BLAblaBLAbla  
BUCKETNAME mybucket  
REGION eu-de  
  
SERVER1 192.168.111.111 abcdefgh-1234-1a2b-1234-abc123def123
SERVER2 192.168.111.112 abcdefgh-1234-1a2b-1234-abc123def123

ALLWS WSMADDR WSMADPRD WSFRADR
WSNAMES Power VS Workspace Mad DR:Power VS Workspace Mad PRD:Power VS Workspace Fra DR

VSI_USER bluexport

SSHKEYPATH /home/<USER>/.ssh/bluexport_rsa

```

#
  <sub>Ricardo Martins - [Blue Chip Portugal](http://www.bluechip.pt) © 2024</sub>  

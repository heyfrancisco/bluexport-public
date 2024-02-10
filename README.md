# bluexport
Capture IBM Cloud POWERVS VSI and Export to COS or/and Image Catalog.
#
 Usage:    ./bluexport.sh [ -a | -x volumes_name_to_exclude ] [VSI_Name_to_Capture] [Capture_Image_Name] [both|image-catalog|cloud-storage] [daily | monthly | single]

 Example:  ./bluexport.sh -a namdr namdr_img image-catalog daily ---- Excludes Volumes with ASP2_ in the name and exports to image catalog.
 Example:  ./bluexport.sh -x ASP2_ namdr namdr_img both monthly    ---- Includes all Volumes and exports to COS and image catalog.
#

Before running bluexport.sh, first you must configure file bluexscrt with your IBM Cloud Data.
Replace all < TEXT > with your data.


bluexscrt example:
```
APYKEY blaBLAblaBLA  
POWERVSDR crn:v1:bluemix:public:power-iaas:blablablablabla::  
POWERVSPRD crn:v1:bluemix:public:power-iaas:blablablablabla::  
ACCESSKEY blaBLAblaBLA  
SECRETKEY blaBLAblaBLAbla  
BUCKETNAME mybucket  
REGION eu-de  
  
SERVER1 192.168.111.111  
SERVER2 192.168.111.112  
```
  
Content of file bluexscrt before edit:  

```
APYKEY <REPLACE-ALL-THIS-WITH-YOUR-API-KEY>  
POWERVSDR <REPLACE-ALL-THIS-WITH-YOUR-POWER-VIRTUAL-SERVER-CRN-i.e.   crn:v1:bluemix:public:power-iaas:blablablablabla::>  
POWERVSPRD <REPLACE-ALL-THIS-WITH-YOUR-POWER-VIRTUAL-SERVER-CRN-i.e.  crn:v1:bluemix:public:power-iaas:blablablablabla::>  
ACCESSKEY <REPLACE-ALL-THIS-WITH-YOUR-ACCES-KEY>  
SECRETKEY <REPLACE-ALL-THIS-WITH-YOUR-SECRET-KEY>  
BUCKETNAME <REPLACE-ALL-THIS-WITH-YOUR-BUCKET-NAME>  
REGION <REPLACE-ALL-THIS-WITH-YOUR-REGION>  
  
SERVER1 XXX.XXX.XXX.XXX  
SERVER2 XXX.XXX.XXX.XXX  
SERVER3 XXX.XXX.XXX.XXX  
.  
.  
SERVERN XXX.XXX.XXX.XXX  
```

#
  <sub>Ricardo Martins - [Blue Chip Portugal](http://www.bluechip.pt) © 2024</sub>  

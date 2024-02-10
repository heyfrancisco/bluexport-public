# bluexport
#
# Usage:    ./bluexport.sh [ -a | -x volumes_name_to_exclude ] [VSI_Name_to_Capture] [Capture_Image_Name] [both|image-catalog|cloud-storage] [daily | monthly | single]
#
# Example:  ./bluexport.sh -a namdr namdr_img image-catalog daily ---- Excludes Volumes with ASP2_ in the name and exports to image catalog
# Example:  ./bluexport.sh -x ASP2_ namdr namdr_img both monthly    ---- Includes all Volumes and exports to COS and image catalog
#
# Capture IBM Cloud POWERVS VSI and Export to COS or/and Image Catalog
# Ricardo Martins - Blue Chip Portugal © 2023
#####################################################################################

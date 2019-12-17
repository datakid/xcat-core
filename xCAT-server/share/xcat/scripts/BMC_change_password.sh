#!/bin/sh

##########################################################################
# This script does the following:
#    - use nmap for the range given (ex: 172.11.139.3-5) to generate list of IP address
#    - try to connect using REST api 
#                with root/0penBmc (Witherspoon) or 
#                     ADMIN/ADMIN (Boston) to check if this is OpenBMC system
#    - check the output of the REST login to see if password needs to be changed
#    - use REST call to change to user provided password
#    - report error is password does not meet PAM validation rules
#   
# Usage: $0 -r <ip_ranges> -n <new BMC Password>
##########################################################################


if [ $# -le 3 ];  then
    echo "Usage:"
    echo "      $0  -r <ip_ranges> -n <new BMC Password> "
    exit
fi

while getopts n:r:h:  option
do
 case "${option}"
 in
 r) RANGE=${OPTARG};;
 n) NEW=${OPTARG};;
 esac
done

if ! [ -x "$(command -v nmap)" ]; then
  echo 'Error: nmap is not installed.' >&2
  exit 1
fi

#Generate the list of IP addresses in the range that user provided
nmap -n -sn $RANGE -oG - | awk '/Up$/{print $2}' > /tmp/$$.ip.list

WITHERSPOON_DEFAULT_USER="root"
WITHERSPOON_DEFAULT_PW="0penBmc"

BOSTON_DEFAULT_USER="ADMIN"
BOSTON_DEFAULT_PW="ADMIN"

CHANGE_PW_REQUIRED="The password provided for this account must be changed before access is granted"
PW_PAM_VALIDATION="password value failed PAM validation checks"
UNAUTHORIZED="Unauthorized"

for name in `cat /tmp/$$.ip.list`
do

    ## Look for Witherspoon first
    SYSTEM_TYPE="Witherspoon"
    PasswordChangeNeeded=`curl -sD - --data '{"UserName":"'"$WITHERSPOON_DEFAULT_USER"'","Password":"'"$WITHERSPOON_DEFAULT_PW"'"}' -k -X POST https://$name/redfish/v1/SessionService/Sessions`

    if [[ "$PasswordChangeNeeded" =~ "$CHANGE_PW_REQUIRED" ]]; then
        echo "$name: Password change needed for $SYSTEM_TYPE system"
        PasswordChanged=`curl -u $WITHERSPOON_DEFAULT_USER:$WITHERSPOON_DEFAULT_PW --data '{"Password":"'"$NEW"'"}' -k -X PATCH https://$name/redfish/v1/AccountService/Accounts/$WITHERSPOON_DEFAULT_USER 2> /dev/null`
        if [[ "$PasswordChanged" =~ "$PW_PAM_VALIDATION" ]]; then
            echo "$name: Can not change password for $SYSTEM_TYPE system - $PW_PAM_VALIDATION"
        elif [[ -z "$PasswordChanged" ]]; then
            # If no output, password change was successful
            echo "$name: Password for $SYSTEM_TYPE system changed" 
        else
            # Some unexpected output changing the password - report error and show output
            echo "$name: Unable to change password for $SYSTEM_TYPE system - $PasswordChanged"
        fi

        continue
    fi

    ## Look for Boston next
    SYSTEM_TYPE="Boston"
    PasswordChangeNeeded=`curl -sD - --data '{"UserName":"'"$BOSTON_DEFAULT_USER"'","Password":"'"$BOSTON_DEFAULT_PW"'"}' -k -X POST https://$name/redfish/v1/SessionService/Sessions`
    if [[ "$PasswordChangeNeeded" =~ "$CHANGE_PW_REQUIRED" ]]; then
        echo "$name: Password change needed for $SYSTEM_TYPE system"
        PasswordChanged=`curl -u $BOSTON_DEFAULT_USER:$BOSTON_DEFAULT_PW --data '{"Password":"'"$NEW"'"}' -k -X PATCH https://$name/redfish/v1/AccountService/Accounts/2 2> /dev/null`
        if [[ "$PasswordChanged" =~ "$PW_PAM_VALIDATION" ]]; then
            echo "$name: Can not change password for $SYSTEM_TYPE system - $PW_PAM_VALIDATION"
        elif [[ -z "$PasswordChanged" ]]; then
            # If no output, password change was successful
            echo "$name: Password for $SYSTEM_TYPE system changed" 
        else
            # Some unexpected output changing the password - report error and show output
            echo "$name: Unable to change password for $SYSTEM_TYPE system - $PasswordChanged"
        fi

        continue
    fi

done

rm /tmp/$$.ip.list

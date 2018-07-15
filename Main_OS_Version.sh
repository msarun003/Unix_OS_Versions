#!/bin/sh
#This Script is for Fetching OS Version details of the server(RHEL / CentOS / OEL / Ubuntu / Solaris).
#Dated 			: November 2017.
#Author 		: M.S. Arun
#Email 			: msarun003@gmail.com


#Local Declarations (Email ID's seperated by comma ",")
#to_recipient="msarun003@gmail.com"
cc_recipient="msarun003@gmail.com,msarun003@gmail.com"


current_date_time=$(date +'_%m_%d_%Y--%H_%M_%S')
backup_directory="/var/OS_Version_Temp"
mkdir -p "$backup_directory"
input_list="$PWD/input_ip_list.txt"
output_list="$backup_directory/output_os_list.txt"


#****************************************************************** Start of Script ********************************************************************#


current_user=$(echo -e "`logname`|`whoami`")
local_ip=$(ip addr | grep 'UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
local_ip_export="local_ip=$local_ip"


#Function to Confirm Email
confirm_email() {
if [ -z "$to_recipient" ]; then
	echo -e "\nDo you want result the output via email?\nEnter \"y\" or \"n\"\n"
	read yes_no
	case $yes_no in
		[Yy]* )while true; do
				read -p "Enter Email ID: " to_recipient
					if [[ "$to_recipient" =~ [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z] ]]; then
						echo -e "Continue" > /dev/null 2>&1
						break;
					else
						echo -e "\nError: Please enter a valid email address\n"
					fi
				done
				;;
		[Nn]* ) ;;
		* ) echo -e "\nPlease answer Yes(y) or No(n)";;
	esac
else
	yes_no="yes"
fi
}


#Initial Configuration Setup
initial_setup()
{
touch "$input_list"
touch "$output_list"
echo -e "" > "$output_list"
if [ -s "$input_list" ]; then
    echo -e "Input List Exists" > /dev/null 2>&1
else
    echo -e "\nInput List is Empty - $input_list\n"
    exit
fi
cat "$input_list" | awk 'NF' > "$backup_directory/input_os_list.temp"
sed -i.bak '1i\IP_Address|Hostname|OS_Name|OS_Version|AD_Status|' "$output_list"
}


#Fetch Remote Server Details Function
server_details_fetch()
{
/usr/bin/ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "NumberOfPasswordPrompts=0" -o "BatchMode=yes" -o "ConnectTimeout=3" -q "$ip_input_list" "export $local_ip_export && $(cat<<'EOT'
if [ -f /etc/release ]; then
    current_os="Solaris"
fi
if [ -f /etc/lsb-release ]; then
    current_os="Ubuntu"
fi
if [ -f /etc/redhat-release ]; then
    current_os="Rhel_Centos"
fi
if [ -f /etc/oracle-release ] && [ -f /etc/redhat-release ]; then
    current_os="Oracle"
fi

ip_address=$(ip -o route get $local_ip 2>/dev/null | sed -e 's/^.* src \([^ ]*\) .*$/\1/')


#AIX
os_aix()
{
host_name=$()
ip_address=$()
os_name=$()
os_version=$()
os_version_short=$(echo -e "$os_version" | cut -d "." -f1)
echo -e "$ip_address|$host_name|$os_name|$os_version|" >> "/var/server_output_list.temp"
}
#Oracle
os_oracle()
{
host_name=$(/bin/hostname)
#ip_address=$(/sbin/ifconfig -a | grep -i 'inet addr:10' | cut -d ":" -f2 | sed -e 's/[[:alpha:]][[:blank:]]*//g' | awk '{$1=$1;print}')
os_name=$(cat /etc/oracle-release | sed -e 's/[[:digit:]][[:punct:]]*//g' | awk '{$1=$1;print}')
os_version=$(cat /etc/oracle-release | sed -e 's/.*release[[:blank:]]*\([[:digit:]][[:graph:]]*\).*/\1/')
os_version_short=$(echo -e "$os_version" | cut -d "." -f1)
echo -e "$ip_address|$host_name|$os_name|$os_version|" >> "/var/server_output_list.temp"
}
#Solaris
os_solaris()
{
host_name=$(/bin/hostname)
ip_address=$(/sbin/ifconfig -a | grep -i "inet 10" | awk '{print $2}')
os_name=$(cat /etc/release | head -1 | awk '{print $1,$2}')
os_version=$(cat /etc/release | head -1 | cut -d "." -f1 | awk '{print $NF"."}')$(cat /etc/release | head -1 | cut -d "." -f2 | awk '{print $1}')
os_version_short=$(echo -e "$os_version" | cut -d "." -f1)
echo -e "$ip_address|$host_name|$os_name|$os_version|" >> "/var/server_output_list.temp"
}
#Redhat / CentOS
os_redhat_centos()
{
host_name=$(/bin/hostname)
#ip_address=$(/sbin/ifconfig -a | grep -i 'inet addr:10' | cut -d ":" -f2 | sed -e 's/[[:alpha:]][[:blank:]]*//g' | awk '{$1=$1;print}')
os_name=$(cat /etc/redhat-release | cut -d "\"" -f2 | sed -e 's/[[:digit:]][[:punct:]]*//g')
os_version=$(cat /etc/redhat-release | sed -e 's/.*release[[:blank:]]*\([[:digit:]][[:graph:]]*\).*/\1/')
os_version_short=$(echo -e "$os_version" | cut -d "." -f1)
echo -e "$ip_address|$host_name|$os_name|$os_version|" >> "/var/server_output_list.temp"
}
#Suse
os_suse()
{
host_name=$()
ip_address=$()
os_name=$()
os_version=$()
os_version_short=$(echo -e "$os_version" | cut -d "." -f1)
echo -e "$ip_address|$host_name|$os_name|$os_version|" >> "/var/server_output_list.temp"
}
#Ubuntu
os_ubuntu()
{
host_name=$(/bin/hostname)
#ip_address=$(/sbin/ifconfig -a | grep -i 'inet addr:10' | cut -d ":" -f2 | sed -e 's/[[:alpha:]][[:blank:]]*//g' | awk '{$1=$1;print}')
os_name=$(cat /etc/lsb-release | grep -i description | cut -d "\"" -f2 | sed -e 's/[[:digit:]][[:punct:]]*//g')
os_version=$(cat /etc/lsb-release | grep -i description | cut -d "\"" -f2 | sed -e 's/[[:alpha:]][[:blank:]]*//g')
os_version_short=$(echo -e "$os_version" | cut -d "." -f1)
echo -e "$ip_address|$host_name|$os_name|$os_version|" >> "/var/server_output_list.temp"
}
case "$current_os" in
                Aix)
                os_aix
                ;;
                Oracle)
                os_oracle
                ;;
                Solaris)
                os_solaris
                ;;
                Rhel_Centos)
                os_redhat_centos
                ;;
                Suse)
                os_suse
                ;;
                Ubuntu)
                os_ubuntu
                ;;
                *)
                echo -e "$ip_address|Unknown OS|Failed|Failed|Failed|" >> "/var/server_output_list.temp"
                ;;
esac
cat /var/server_output_list.temp
rm -f /var/server_output_list.temp > /dev/null 2>&1
history -r
EOT
)" >> "$output_list" < /dev/null
}


#Temp Files Deletion Function
temp_deletion()
{
rm -f "$output_list" > /dev/null 2>&1
}


#Send Mail Function
send_mail()
{
echo -e "\nTeam,\n\nPlease find the attachment.\n\nScript Name : OS Version Details\n\nServer Name : `hostname`\n\nCurrent User: $current_user\n\nCurrent Date and Time : `date`\n\n\nRegards,\nUnix Support.\n\n\n\n*** This is an auto generated email.Please do not reply to this mail.\n" | mail -s "OS Details" -a "$backup_directory/output_os_list.txt" -c "$cc_recipient" -r "$to_recipient" "$to_recipient"
}


#Main Program
temp_deletion
initial_setup
confirm_email
echo -e "\nIP_Address|Hostname|OS_Name|OS_Version|"
while read -r ip_input_list; do
/usr/bin/ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "NumberOfPasswordPrompts=0" -o "BatchMode=yes" -o "ConnectTimeout=3" -q "$ip_input_list" "exit" < /dev/null
sftp_connectivity_test_status="$?"
if [ "$sftp_connectivity_test_status" == 0 ]; then
        echo -e "Success" > /dev/null 2>&1
        server_details_fetch "$ip_input_list";
else
        echo -e "$ip_input_list|Unable to Login|Unable to Login|Unable to Login|" >> "$output_list"
fi
cat "$output_list" | tail -1
done < "$backup_directory/input_os_list.temp"
if [[ "$yes_no" =~ ^([yY][eE][sS]|[yY])$ ]]; then
	send_mail
else
	echo -e "Skip Mail Trigger" > /dev/null 2>&1
fi
cp -fp "$output_list" "$PWD/"
#temp_deletion


#****************************************************************** End of the Script ******************************************************************#

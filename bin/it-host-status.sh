#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Author: Brandon Authier (hblkr)
#
#  Date: 25 Oct 2017
#
#  File: it-host-status.sh
#
#  Syntax: it-host-status.sh [OPTIONS]... [PHPIPAM_TEXT_FILE]
#
#  Description:
#
#    This script will take in phpipam text file and output an html file visually
#    representing if a host responded to an Ansible ping, ssh, and ping.
#
#  Notes:
#
#    When first written, this script took about 10 mins and 30 secs to run.
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

################### VARIABLES
# Global Variables
DEBUG="1"
BASE_DIR=${PWD}
ANSIBLE_WD=$(find ~/ -name "ansible-it")
LOG_DIR="log"
FILES_DIR="files"
SCRIPTS_DIR="scripts"

# Host files
IPAM_HOSTS=""
HOST_1040="ipam-10.40-display.txt"
WORK_HOST_1040="ipam-10.40-work.txt"
SUCCESSFUL_ANSIBLE_HOSTS="successful-ansible-hosts.log"
SUCCESSFUL_SSH_HOSTS="successful-ssh-hosts.log"

# Helper files
NOTFOUND_ANSIBLE="notfound-ansible.log"
FOUND_ANSIBLE="found-ansible.log"
PING_OUT="ping-out.log"
IPS_ONLY="ips.txt"

# Scripts
AWK_CLEAN_SCRIPT="clean-host-output.awk"
AWK_HOST_HTML_SCRIPT="host-html.awk"

# Output files
HOST_STATUS_HTML="host-status.html"

################### FUNCTIONS
# Changes to the ansible-it repo and pings everything. It then gets all successful
# and updates hosts to "yes" for ansible ping
ansible_ping()
{
    if [ "$DEBUG" = "0" ] ; then
        echo "[ANSIBLE PINGING] Log here: ${LOG_DIR}/${SUCCESSFUL_ANSIBLE_HOSTS}"
    else
        echo "[ANSIBLE PINGING]"
    fi

    # Get all successfully pingable ansible hosts
    cd ${ANSIBLE_WD}
    ansible all -m ping | egrep "SUCCESS" | awk '{ print $1 }' | \
    sort > ${BASE_DIR}/${LOG_DIR}/${SUCCESSFUL_ANSIBLE_HOSTS}

    # There are a couple successful hosts that come back with a FQDN
    remove_fqdn ${BASE_DIR}/${LOG_DIR}/${SUCCESSFUL_ANSIBLE_HOSTS}

    # Change back to base directory to perfom tasks
    cd ${BASE_DIR}

    # Go through and update all hosts that respond to ansible ping
    # Clear text files
    if [ "$DEBUG" = "0" ] ; then
        > ${LOG_DIR}/${NOTFOUND_ANSIBLE}
        > ${LOG_DIR}/${FOUND_ANSIBLE}
    fi

    # Loop through successful ansible hosts
    while read -r line ; do
        host_found=""
        updated_host=""

        # Try to find host
        if egrep "\s${line}\s" ${LOG_DIR}/${WORK_HOST_1040} &> /dev/null; then
            host_found=$(egrep "\s${line}\s" ${LOG_DIR}/${WORK_HOST_1040})
        elif egrep "\s${line}\b" ${LOG_DIR}/${WORK_HOST_1040} &> /dev/null; then
            host_found=$(egrep "\s${line}\b" ${LOG_DIR}/${WORK_HOST_1040})
        fi

        # This fixes hosts that have 2 ip addresses (This has to do with ipam)
        host_found=$(echo -E -n ${host_found} | awk '{ print $1, $2, $3, $4, $5 }')

        # Write hosts to found/notfound files and replace string with "yes" for found ones
        if [ -z "${host_found}" ] ; then
            if [ "$DEBUG" = "0" ] ; then
                echo ${line} >> ${LOG_DIR}/${NOTFOUND_ANSIBLE}
            fi
        else
            if [ "$DEBUG" = "0" ] ; then
                echo ${line} >> ${LOG_DIR}/${FOUND_ANSIBLE}
            fi
            updated_host=$(echo -E -n ${host_found} | awk '{ print $1, $2, "yes", $4, $5 }')
            sed -i 's/'"$host_found"'/'"$updated_host"'/' ${LOG_DIR}/${WORK_HOST_1040}
        fi
    done < ${LOG_DIR}/${SUCCESSFUL_ANSIBLE_HOSTS}
}

# Cleans up unwanted files
clean_up()
{
    echo "Cleaning up"

    # Save the host display text since it can be useful
    mv ${LOG_DIR}/${HOST_1040} ${FILES_DIR}/

    # If debug (logging) is off, delete all logs and remove directory
    if ! [ "$DEBUG" = "0" ] ; then
        rm -f ${LOG_DIR}/${WORK_HOST_1040} \
              ${LOG_DIR}/${IPS_ONLY} \
              ${LOG_DIR}/${PING_OUT} \
              ${LOG_DIR}/${SUCCESSFUL_ANSIBLE_HOSTS} \
              ${LOG_DIR}/${SUCCESSFUL_SSH_HOSTS} \
              ${LOG_DIR}/${NOTFOUND_ANSIBLE} \
              ${LOG_DIR}/${FOUND_ANSIBLE}
        rmdir ${LOG_DIR}
    fi
}

# Error when the ansible-it repo is not installed
error_ansible()
{
    echo "[ERROR: ANSIBLE]"
    echo " There was an ansible error. Either \`hash ansible\` didn't work or the"
    echo " ansible repository path is bad."
    echo " ANSIBLE_PATH=$ANSIBLE_WD"
    echo " \"Ansible Ping\" will all be no."
}

# Error when the phpipam text file is not passed in
error_arguments()
{
    echo "[ERROR: ARGUMENT]"
    echo " At least one argument is expected. The phpipam text file should be given."
    echo ""
}

# Gets ping status and sets the ping value to "yes". Tries to use fping since
# that reduces ping time substantially. Will fail to regular ping if fping is not installed
ping_status()
{
    if [ "$DEBUG" = "0" ] ; then
        echo "[PINGING HOSTS]   Log here: ${BASE_DIR}/${LOG_DIR}/${PING_OUT}"
    else
        echo "[PINGING HOSTS]"
    fi

    # Ping hosts to file (fping preffered)
    echo "Using standard ping"
    if hash fping &> /dev/null ; then
        fping -c 2 -a < ${LOG_DIR}/${IPS_ONLY} |& grep "2/2/0%" | \
        awk '{ print $1 }' > ${LOG_DIR}/${PING_OUT}
    else
        # Clear ping-out text
        > ${LOG_DIR}/${PING_OUT}
        for ip in $(cat ${LOG_DIR}/${IPS_ONLY}) ; do
            ping -q -W 1 -c 1 ${ip} &> /dev/null
            if [ ${?} -eq 0 ] ; then
                echo "${ip}" >> ${LOG_DIR}/${PING_OUT}
            fi
      	done
    fi

    # Loop through ping output (all successful ips that responded to ping)
    while read -r ip ; do
        ip_found=""
        updated_ip=""

        # Find ip in working host file and change ping status to yes
        if egrep "${ip}\s" ${LOG_DIR}/${WORK_HOST_1040} &> /dev/null; then
            ip_found=$(egrep "${ip}\s" ${LOG_DIR}/${WORK_HOST_1040})
            updated_host=$(echo -E -n ${ip_found} | awk '{ print $1, $2, $3, $4, "yes" }')
            sed -i 's/'"$ip_found"'/'"$updated_host"'/' ${LOG_DIR}/${WORK_HOST_1040}
        fi
    done < ${LOG_DIR}/${PING_OUT}
}

# Help function
help()
{
    echo "Usage:"
    echo " $0 [OPTION]... [PHPIPAM_TEXT_FILE]"
    echo ""
    echo "Options:"
    echo " -h             Print help menu"
    echo " -d             Turn on debugging (produces logs in ${LOG_DIR}/)"
    echo ""
}

# Check if there is a valid ansible repo "ansible-it" and ansible command
is_ansible_valid()
{
    local IS_VALID="0"

    if [ -z ${ANSIBLE_WD} ] ; then
        IS_VALID="1"
    elif ! cd ${ANSIBLE_WD} &> /dev/null ; then
        IS_VALID="1"
    elif ! hash ansible &> /dev/null ; then
        IS_VALID="1"
    fi

    #cd ${BASE_DIR}
    echo ${IS_VALID}
}

# Preprocessing of the host file that removes fully qalified domain names
remove_fqdn()
{
    # Remove FQDN from list for easier manipulation
    sed -i 's/.sea-001.zonarnetworking.net//' ${1}
    sed -i 's/.sea-001.zonarsystems.net//' ${1}
    sed -i 's/.sea-001.zonarsystems.com//' ${1}
    sed -i 's/.sea-002//' ${1}
    sed -i 's/.zonarsystems.com//' ${1}
    sed -i 's/.zonarsystems.net//' ${1}
}

# Simple timer funtion that spins characters so users don't think it froze
spin_timer()
{
    sleep 1
    spin='-\|/'
    i="0"

    while kill -0 ${1} 2>/dev/null ; do
        i=$(( (i + 1) % 4 ))
        printf "\r${spin:${i}:1}"
        sleep 0.12
    done

    echo -en "\r"
}

# Gets the ssh status of hosts and changes the status to "yes" for successful hosts
ssh_status()
{
    if [ "$DEBUG" = "0" ] ; then
        echo "[SSHING HOSTS] Log here: ${BASE_DIR}/${LOG_DIR}/${SUCCESSFUL_SSH_HOSTS}"
    else
        echo "[SSHING HOSTS]"
    fi

    # Clear file
    > ${LOG_DIR}/${SUCCESSFUL_SSH_HOSTS}

    # Loop through all hosts and test ssh connection
    while read -r line; do
        host=$(echo ${line} | awk '{ print $2 }')

        # Write successful ssh hosts to file and replace string with "yes" for successful ones
        #if nc -w 1s -z -v ${host} 22 &> /dev/null ; then
        if nc -w 1 ${host} 22 < /dev/null &> /dev/null ; then
            echo ${host} >> ${LOG_DIR}/${SUCCESSFUL_SSH_HOSTS}
            updated_host=$(echo -E -n ${line} | awk '{ print $1, $2, $3, "yes", $5 }')
            sed -i 's/'"$line"'/'"$updated_host"'/' ${LOG_DIR}/${WORK_HOST_1040}
        fi
    done < ${LOG_DIR}/${WORK_HOST_1040}
}

################### PREPROCESSING
# Use getopts to get all flags/options
while getopts ":dh" opt ; do
    case ${opt} in
        d)
            DEBUG="0"
            ;;
        h)
            help
            exit 0
            ;;
    esac
done

# Shift the position to utilze the arguments
shift $((OPTIND - 1))

# Check for phpipam text file
if [ "$#" -ne "1" ] ; then
    error_arguments
    help
    exit 1
fi

# Set phpipam text file
IPAM_HOSTS="$1"


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Prequisites ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ansible-it repository must exist, if not error and exit.
IS_VALID=$(is_ansible_valid)
if [ ${IS_VALID} -eq 1 ] ; then
    error_ansible
fi

# Create log directory if dne
if ! [ -d ${LOG_DIR} ] ; then
    mkdir ${LOG_DIR}
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Begin Work ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Create a main file breaking out the 10.40.0.0/16 subnet
cat ${IPAM_HOSTS} | grep "10.40" | awk -f ${SCRIPTS_DIR}/${AWK_CLEAN_SCRIPT} > ${LOG_DIR}/${HOST_1040}

# Remove FQDN .sea-001.zonarsystems.net from list for easier manipulation
remove_fqdn ${LOG_DIR}/${HOST_1040}

# Create and sort a hosts file for manipulation
sort -o ${LOG_DIR}/${WORK_HOST_1040} -k 2 ${LOG_DIR}/${HOST_1040}

# Strip the comment lines from the working hosts file
sed -i '/^#/d' ${LOG_DIR}/${WORK_HOST_1040}

# Assume failed state for ever category
#   <ip> <hostname> <ansible-status> <sshable> <pingable>
#   10.40.0.1 dev-db-001 no no no
sed -i 's/$/ no no no/' ${LOG_DIR}/${WORK_HOST_1040}

# Get Ansible ping status for hosts. Only run if ansible-it exists
if [ ${IS_VALID} -eq 0 ] ; then
    ansible_ping &
    PID=$!
    spin_timer $PID
fi

# Get ssh status for hosts
ssh_status &
PID=$!
spin_timer $PID

# Ping status for hosts and create an IPs file so you don't rely on DNS settings
cat ${LOG_DIR}/${WORK_HOST_1040} | awk '{ print $1 }' > ${LOG_DIR}/${IPS_ONLY}
ping_status &
PID=$!
spin_timer $PID

# Copy over results of working hosts file to display hosts file
echo "starting copying hosts back"
while read -r line ; do
    sed -i 's/'"\b$(echo $line | awk '{ print $1, $2 }')\b"'/'"$line"'/' ${LOG_DIR}/${HOST_1040}
done < ${LOG_DIR}/${WORK_HOST_1040}

# Create host-status.html files
awk -f ${SCRIPTS_DIR}/${AWK_HOST_HTML_SCRIPT} ${LOG_DIR}/${HOST_1040} > ${HOST_STATUS_HTML}

# Clean up and exit
clean_up
exit 0

#!/bin/bash

########################################################################################################################################
##                                                                                                                                    ##
##  Script name: Bd_scan_request.R                                                                                                    ##
##  Purpose of script: Prompt Linux users to start a Bitdefender scan. Meant to be run as a hourly cron job.                          ##
##                     Frequency of promopts increases as time since last scan increases.                                             ##
##                                                                                                                                    ##
##  Dependencies:                                                                                                                     ##
##    bash calculator (bc -v to check)                                                                                                ##
##    zenity (zenity --version to check)                                                                                              ##
##                                                                                                                                    ##
##  Author: Mart Roben                                                                                                                ##
##  Date Created: 18. Aug 2022                                                                                                        ##
##  Contact: mart@altacom.eu                                                                                                          ##
##                                                                                                                                    ##
##  Copyright: MIT License                                                                                                            ##
##  https://github.com/martroben/Bd_scan_Request                                                                                      ##
##                                                                                                                                    ##
##  Contact: mart@altacom.eu                                                                                                          ##
##                                                                                                                                    ##
########################################################################################################################################


Bd_install_location="/opt/bitdefender-security-tools"
Bd_full_scan_identifier="dcf483c4-26d0-4e6f-ba28-6a53a00adae1"	# Bitdefender says it's the same for all agents and devices
Bd_full_scan_logs="$Bd_install_location/var/log/$Bd_full_scan_identifier"

# Get number of days since last full scan
# If would be nicer to use bduitool to get the last scan time, but it produced buggy results in some of my test runs
current_time=$(date +%s)
last_full_scan_time=$(sudo find $Bd_full_scan_logs/*.xml -printf "%T@\n" | sort -n | tail -n 1)
if [[ $last_full_scan_time ]]; then
    days_since_last_scan=$(echo "($current_time - $last_full_scan_time) / 60 / 60 / 24" | bc)
else
    days_since_last_scan=999
fi

# Parameter to increase the frequency of executing the cron task as more time passes from last full scan
frequency_parameter=$(echo "x = 1 + e ( (6 - 2/7 * $days_since_last_scan) * l(2) ); scale=0; x / 1" | bc -l)

# User prompt settings
prompt_title="Hoiame turvalisust!"
prompt_message="Sinu viimane viirustõrje skänn oli $days_since_last_scan päeva tagasi.\n"\
"Kas soovid skänni praegu käivitada?\n"
prompt_agree_option="Jah"
prompt_reject_option="Ei"
prompt_timeout=$(echo "3600 * 24 / (23 / $frequency_parameter + 1)" | bc)

# Check that there are no full scans already running
# Check if it's the correct hour of the day to display the dialogue
# Ask user to start a full scan
active_scan=$(echo $(sudo $Bd_install_location/bin/bduitool get scantasks) | grep -iPo ${Bd_full_scan_identifier}.*running)
current_hour=$(date +%H)

if [[ $(($current_hour % $frequency_parameter)) -eq 0 && -z $active_scan ]]; then

    # Using yad instead of zenity might be a good idea
    # yad might have features to avoid accidentally starting scans by hitting enter
    # However yad is not natively included in Ubuntu
    zenity --question \
      --timeout="$prompt_timeout" \
      --title="$prompt_title" \
      --text="$prompt_message" \
      --ok-label "$prompt_agree_option" \
      --cancel-label "$prompt_reject_option"
    
    # If user agrees, start a full scan and display an info prompt
    prompt_answer=$?
    if [[ $prompt_answer -eq 0 ]]; then
        sudo $Bd_install_location/bin/bduitool scan -s full
        zenity --info \
          --title="Viirusetõrje skänn käivitatud!" \
          --text="Skänni erakorraliseks peatamiseks kasuta käsku 'sudo $Bd_install_location/bin/bduitool scan -q'."
    fi
fi

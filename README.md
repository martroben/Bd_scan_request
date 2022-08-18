# Bitdefender scan request
- Bitdefender is known to have fairly high resource usage during full scans.
- This is a Linux shell script that periodically requests Bitdefender scans from user, to give user more control over when the scans occur.
- The script is meant to be run as an hourly cron task.
- User can postpone the scan forever, but the script keeps increasing the frequency of prompts up to a maximum of once per hour (after ~16 days).
- Prompt timeouts adjust so that there will never be more than two concurrent prompts.
- Upon running the scan, the script also informs user on how to stop a scan in case it was started accidentally.


## Usage
Add the following task to root cron (has to be root cron, because Bitdefender components require elevated privileges to access).
```Shell
sudo crontab -e
```

```Shell
# Edit this file to introduce tasks to be run by cron.

# Bitdefender restart prompt
3 * * * * export DISPLAY=:0 && /opt/management_scripts/Bd_scan_request.sh
```
[Additional info](https://askubuntu.com/questions/85612/how-to-call-zenity-from-cron-script)


## Screenshots
<img src="https://user-images.githubusercontent.com/87522742/185491863-5f622c3c-9841-4784-a81d-130b9b12cf9d.png" width="400">

<img src="https://user-images.githubusercontent.com/87522742/185492012-05076bf6-e560-402b-87f3-713aa5fbd7b2.png" width="400">


## Frequency algorithm
Script increases the frequency of prompting, depending on how much time has passed from last scan:

$frequency\ parameter = 1 + 2^{\[6 - \frac 2 7\ \cdot\ days\ since\ last\ scan\]}\ \ \ \text{(only the whole number part is kept)}$

(current hour of day + 1) is divided by the frequency parameter. Whenever the remainder (modulo) is 0, user is prompted to start a scan.

Eg. if 14 days have passed since last scan the frequency parameter takes the following value:

$1 + 2^{\[6 - \frac {2 \cdot 14} 7\]} = 5$

That means that user is prompted at 9 o'clock, 14 o'clock, 19 o'clock (if the device is still running) etc.


## Dependencies
- Bash Calculator for math. `bc -v` to check.
- Zenity for displaying user dialogues. `zenity --version` to check.


## Cautions
- Due to zenity's limitations, users are liable to start full scans by accidentally pressing return when a prompt appears. Using yad instead of zenity might provide more control over how prompt windows react to accidental keystrokes.

# monitor-android-sms-and-forward-to-dingtalk-webhook-in-Termux
Monitor Android SMS sqlite database, and forward the new SMS received by calling Dingtalk robot webhook API

# First

- You have an Android Phone with SMS card inserted.
- Termux has been installed on your Android Phone
- You've got root privilege
- sqlite has been installed

# Deploy

Add this script to you Termux cornd job, make it run every minute.

If the script finds some new SMS in inbox, it will forward the SMS content, such as Dingtalk Webhook API.

# Command line

```
~ $ ./sms_monitor.sh 
Run with command "sms_monitor.sh --init" first, and then run "sms_monitor.sh --monitor" in crontab
Usage: sms_monitor.sh <cmd>
  --monitor   Start to monitor and forward new sms
  --init      Init forward record table
  --test      Send the last sms to dingtalk

crontab example:"*/1 * * * * sms_monitor.sh --monitor"
```
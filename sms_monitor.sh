#!/data/data/com.termux/files/usr/bin/bash
# Monitor Android SMS sqlite database, and forward the new SMS received by calling Dingtalk robot webhook API

date "+%Y%-m-%d %H:%M:%S" >> /tmp/sms_monitor_running.log

# Get Dingtalk token from your robot configuration interface.
DINGTALK_ACCESS_TOKEN="95337b1ad3482***63"
DINGTALK_API="https://oapi.dingtalk.com/robot/send?access_token="

# pkg install sqlite
SQLITE_BIN="/data/data/com.termux/files/usr/bin/sqlite3"
# You shoud set the specific SMS database file path mannually.
SMS_DB="/data/user_de/0/com.android.providers.telephony/databases/mmssms.db"

# To use alias in bash script, you should run this first
shopt -s expand_aliases
alias sql_exec="sudo $SQLITE_BIN $SMS_DB"

function get_new_sms(){
	new_sms_id=$(sql_exec "select _id from sms where type=1 and _id not in (select sms_id from sms_forwarded) limit 1;")
	if [ "$new_sms_id" != "" ]; then
		#echo "Found new SMS id:$new_sms_id"
		sms_content=$(sql_exec "select t._id, t.address,strftime('%Y-%m-%d %H:%M:%f',datetime(t.date/1000, 'unixepoch', 'localtime')),t.subject,t.body from sms t where t._id=$new_sms_id;")
		echo $sms_content
	fi
}

function dingtalk_message(){
    # https://open.dingtalk.com/document/robots/custom-robot-access
	message="${1//\"/\\\"}"
	# echo $message
	target_result='{"errcode":0,"errmsg":"ok"}'
	send_result=`curl -sL "${DINGTALK_API}${DINGTALK_ACCESS_TOKEN}" \
 		-H "Content-Type: application/json" \
 		-d '{"msgtype": "text","text": {"content":"'"$message"'--SMSCat"}}'`
 	echo $send_result
 	if [ "$target_result" == "$send_result" ]; then
 		return 0
 	else
 		return 1
 	fi
}

function monitor_and_forward(){
    # Get sms and forward it one by one
	sms_content=$(get_new_sms)
	if [ "$sms_content" != "" ]; then
		dingtalk_message "$sms_content"
		if [ $? -eq 0 ]; then
			sms_id=$(echo $sms_content|awk -F '|' '{print $1}')
			sql_exec "INSERT INTO sms_forwarded VALUES ($sms_id);"
			monitor_and_forward
		fi
	fi
}

case "$1" in
	"--monitor" )
		monitor_and_forward
		;;
	"--init" )
		sql_exec "CREATE TABLE IF NOT EXISTS sms_forwarded (sms_id INTEGER PRIMARY KEY);" 
		sql_exec "INSERT INTO sms_forwarded (sms_id) select _id from sms where type=1;"
		echo "database inited..."
		;;
	"--test" )
		message_test=$(sql_exec "select t._id, t.address,strftime('%Y-%m-%d %H:%M:%f',datetime(t.date/1000, 'unixepoch', 'localtime')),t.subject,t.body from sms t where type=1 order by _id desc limit 1;")
		echo $message_test
		ret=$(dingtalk_message "$message_test")
		echo $ret
		;;
	*)
		echo "Run with command \"sms_monitor.sh --init\" first, and then run \"sms_monitor.sh --monitor\" in crontab"
		echo "Usage: sms_monitor.sh <cmd>"
		echo "  --monitor   Start to monitor and forward new sms"
		echo "  --init      Init forward record table"
		echo "  --test      Send the last sms to dingtalk"
		echo ""
		echo "crontab example:\"*/1 * * * * sms_monitor.sh --monitor\""
		;;
esac

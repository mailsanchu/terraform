#!/bin/bash
echo "Waiting for LOAD_BAL_DNS ... "
while true;
do
	HTTP_STATUS=`wget --no-check-certificate --spider -S "http://LOAD_BAL_DNS" 2>&1 | grep "HTTP/" | awk '{print $2}'`
	if [[ $HTTP_STATUS = "200" ]]; then
		echo Status is 200 OK, Application is Up!;
		break;
	fi
	sleep 0.1;
done

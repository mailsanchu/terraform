#!/bin/bash
echo "Waiting for LOAD_BAL_DNS ... "
while true;
do
	wget --no-check-certificate --spider -S "http://LOAD_BAL_DNS";
	if [ $? -eq 0 ]; then
		echo Status is 200 OK, Application is Up!;
		break;
	else
		echo "------------------------------------------- $?"
	fi
	sleep 5;
done

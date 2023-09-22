#!/bin/sh
affinity=$(taskset -pc $$ | awk -F:' ' '{print $2}')
taskset -c affinity ./nginx_/sbin/nginx -g "worker_processes auto;"
sleep 5
sudo echo "1" >> /tmp/waitingprocesses.tmp && while [ "$(grep -c "1" /tmp/waitingprocesses.tmp 2>/dev/null)" -ge "2" ]; do sleep 0.5; done;

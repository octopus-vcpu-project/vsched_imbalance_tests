#!/bin/sh
affinity=$(taskset -pc $$ | awk -F:' ' '{print $2}')
taskset -c $affinity ./nginx_/sbin/nginx -g "worker_processes auto;"
sleep 5
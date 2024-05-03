#!/bin/bash

ssh ubuntu@vsched-1 "sudo tee /sys/kernel/debug/sched/min_granularity_ns <<< 1000000"

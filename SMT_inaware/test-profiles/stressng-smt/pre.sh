#!/bin/sh
sudo echo "1" >> /tmp/waitingprocesses.tmp && while [ "$(grep -c "1" /tmp/waitingprocesses.tmp 2>/dev/null)" -ge "2" ]; do sleep 0.5; done;

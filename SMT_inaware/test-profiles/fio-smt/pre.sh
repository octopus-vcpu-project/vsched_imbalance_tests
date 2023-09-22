#!/bin/sh
cd fio-3.35/
rm -f fiofile
sudo echo "1" >> /home/ubuntu/tmp/waitingprocesses.tmp && while [ "$(grep -c "1" /tmp/waitingprocesses.tmp 2>/dev/null)" -ge "2" ]; do sleep 0.5; done;

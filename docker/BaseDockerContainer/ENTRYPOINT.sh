#!/bin/bash

[[ -f /home/roddy/debugStuff.sh ]] && bash /home/roddy/debugStuff.sh

export HOSTNAME=`hostname`
export HOST=$HOSTNAME


(ps -ef  | grep usr  | grep  sge | awk '{print $2}' | xargs sudo kill 2> /dev/null)

# Prepare SGE so it will start properly
sudo bash -c "hostname > /var/lib/gridengine/default/common/act_qmaster"
sudo rm -rf /var/lib/gridengine/default/common/act_qmaster

sudo /etc/init.d/gridengine-exec stop
sudo /etc/init.d/gridengine-master restart;
sudo /etc/init.d/gridengine-exec start;

# Prepare the host and the queue, without it, it won't run
host=`hostname`
sudo qconf -ah $host
sudo qconf -as $host


echo "host=`hostname`" > /home/roddy/prepareMainQ.sh; 
echo "touch /home/roddy/main.q && chmod a+rw /home/roddy/main.q" >> /home/roddy/prepareMainQ.sh
echo 'qconf -sq main.q | sed "s/hostlist.*/hostlist\t\t${host} @allhosts/g" | sed "s/slots.*/slots\t\t1,[${host}=8]/g" > /home/roddy/main.q' >> /home/roddy/prepareMainQ.sh; 
sudo /bin/bash /home/roddy/prepareMainQ.sh

ls -l /home/roddy/
cat /home/roddy/main.q

qconf -Mq /home/roddy/main.q

echo "sleep 1" | qsub

sleep 2

qstat


# change UID and GID of roddy user to user who launched the docker
[ -n "$RUN_AS_UID" ] && sudo usermod -u $RUN_AS_UID roddy
[ -n "$RUN_AS_GID" ] && sudo groupmod -g $RUN_AS_GID roddy

# give normal users permissions on std* (required with gosu)
sudo chmod 666 /dev/std{err,out,in}

# run workfow as roddy user with gosu
gosu roddy "$@"

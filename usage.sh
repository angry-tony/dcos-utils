# "nameserver 8.8.8.8" >> /etc/resolv.conf

#cd .. & rm -Rf dcos-utils && git clone http://github.com/fernandosanchezmunoz/dcos-utils && cd dcos-utils


export DCOS_IP=10.0.1.138
export USERNAME=bootstrapuser
export PASSWORD=deleteme
export NUM_MASTERS=3
export DCOS_TOKEN=$(./login.py -s $DCOS_IP -u bootstrapuser -p deleteme); echo $DCOS_TOKEN

#after that simply
./get_nodes.py


./get_state.py

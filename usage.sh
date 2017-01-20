echo "nameserver 8.8.8.8" >> /etc/resolv.conf

#cd .. & rm -Rf dcos-utils && git clone http://github.com/fernandosanchezmunoz/dcos-utils && cd dcos-utils


export DCOS_IP=10.0.1.138
export DCOS_TOKEN=$(./login.py -s $DCOS_IP -u bootstrapuser -p deleteme); echo $DCOS_TOKEN

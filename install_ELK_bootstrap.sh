#!/bin/bash
WORKING_DIR=$HOME"/DCOS_install"
CLUSTERNAME=dcoslab
BOOTSTRAP_IP=10.120.1.213
ELK_HOSTNAME=$BOOTSTRAP_IP
ELK_PORT=9200

#Install Java 8
echo "** Installing Java 8..."
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm"
sudo yum -y localinstall jdk-8u73-linux-x64.rpm
rm -f jdk-8u*-linux-x64.rpm
#Install elasticsearch
echo "** Installing Elasticsearch..."
sudo rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch
sudo tee /etc/yum.repos.d/elasticsearch.repo <<-EOF 
[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=http://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF
sudo yum -y install elasticsearch
#configure elasticsearch
echo "** Configuring Elasticsearch..."
sudo cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.BAK
#https://gist.github.com/zsprackett/8546403
sudo tee /etc/elasticsearch/elasticsearch.yml <<-EOF
cluster.name: $CLUSTERNAME
node.name: $CLUSTERNAME
node.master: true
node.data: true
network.host: $BOOTSTRAP_IP
index.number_of_shards: 2
index.number_of_replicas: 1
bootstrap.mlockall: true
gateway.recover_after_nodes: 1
gateway.recover_after_time: 10m
gateway.expected_nodes: 1
action.disable_close_all_indices: true
action.disable_delete_all_indices: true
action.disable_shutdown: true
indices.recovery.max_bytes_per_sec: 100mb
EOF
#start elasticsearch
echo "** Starting Elasticsearch..."
sudo systemctl daemon-reload
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch

#Install Kibana
echo "** Installing Kibana..."
sudo tee /etc/yum.repos.d/kibana.repo <<-EOF
[kibana-4.4]
name=Kibana repository for 4.4.x packages
baseurl=http://packages.elastic.co/kibana/4.4/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF
sudo yum -y install kibana
#configure kibana
echo "** Configuring Kibana..."
sudo cp /opt/kibana/config/kibana.yml /opt/kibana/config/kibana.yml.BAK
sudo tee /opt/kibana/config/kibana.yml  <<-EOF
elasticsearch.url: "http://$BOOTSTRAP_IP:9200"
EOF
#start kibana
echo "** Starting Kibana..."
sudo systemctl start kibana
sudo chkconfig kibana on

#Load Kibana dashboards
echo "** Loading Kibana dashboards..."
mkdir -p $WORKING_DIR/kibana
cd $WORKING_DIR/kibana
curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip
unzip beats-dashboards-*.zip
cd beats-dashboards-*
#modify load.sh to point to Elasticsearch on numbered interface
sudo sed -i -e "s/ELASTICSEARCH=http:\/\/localhost:9200/ELASTICSEARCH=http:\/\/$ELK_HOSTNAME:$ELK_PORT/g" ./load.sh
./load.sh

#Load Filebeat index template in elasticsearch
echo "** Loading Filebeat index templates..."
mkdir -p $WORKING_DIR/filebeat
cd $WORKING_DIR/filebeat
#get filebeat user template from github
curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json
#load into localhost's elasticsearch
curl -XPUT "http://$BOOTSTRAP_IP:9200/_template/filebeat?pretty" -d@filebeat-index-template.json

#End of ELK install on bootstrap node

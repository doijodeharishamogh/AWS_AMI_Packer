sudo yum -y update
sudo yum install -y httpd
sudo yum install -y java-11-openjdk
sudo yum install -y ruby
sudo yum install -y wget
sudo yum install -y mariadb-server
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Tomcat-9 Installation and Path Setup
sudo groupadd tomcat
sudo mkdir /opt/tomcat
sudo useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat
sudo yum -y -q install wget

cd ~
wget -q wget https://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.27/bin/apache-tomcat-9.0.27.tar.gz
tar -zxf apache-tomcat-9.0.27.tar.gz
sudo chmod +x apache-tomcat-9.0.27/bin/*.bat
sudo rm -f apache-tomcat-9.0.27/bin/*.bat
sudo ls -l apache-tomcat-9.0.27/bin
sudo mv apache-tomcat-9.0.27/* /opt/tomcat/

# setting permission for tomcat
cd /opt/tomcat
sudo ls
sudo chgrp -R tomcat conf
sudo chmod g+rwx conf
sudo chmod -R g+r conf
sudo chown -R tomcat logs/ temp/ webapps/ work/

sudo chgrp -R tomcat bin
sudo chgrp -R tomcat lib
sudo chmod g+rwx bin
sudo chmod -R g+r bin

sudo su
sudo chmod -R 777 webapps
sudo chmod -R 777 work

echo "export CATALINA_HOME='/opt/tomcat/'" >> ~/.bashrc

sudo chmod -R 777 /opt/tomcat

#CodeDeploy               
cd ~
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
sudo service codedeploy-agent status

cd ~
touch cloudwatch-config.json
cat > cloudwatch-config.json << EOF
{
    "agent": {
        "metrics_collection_interval": 10,
        "logfile": "/var/logs/amazon-cloudwatch-agent.log"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/opt/tomcat/logs/csye6225.log",
                        "log_group_name": "csye6225_fall2019",
                        "log_stream_name": "webapp"
                    }
                ]
            }
        },
        "log_stream_name": "cloudwatch_log_stream"
    },
    "metrics": {
        "metrics_collected": {
            "statsd": {
                "service_address":":8125",
                "metrics_collection_interval":60,
                "metrics_aggregation_interval":60
            }
        }
    }
}
EOF
touch csye6225.log
sudo chgrp -R tomcat csye6225.log
sudo chmod -R g+r csye6225.log
sudo chmod g+x csye6225.log
sudo mv csye6225.log /opt/tomcat/logs/csye6225.log
sudo mv cloudwatch-config.json

cd ~
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:cloudwatch-config.json \
    -s
sudo systemctl status amazon-cloudwatch-agent.service

# cd ~
# sudo wget https://s3.amazonaws.com/configfileforcloudwatch/amazon-cloudwatch-agent.service
# sudo cp amazon-cloudwatch-agent.service /etc/systemd/system/
# sudo systemctl enable amazon-cloudwatch-agent
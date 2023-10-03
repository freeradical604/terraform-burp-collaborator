#! /bin/bash

DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/9.0.1/linux/splunkforwarder-9.0.1-82c987350fde-Linux-x86_64.tgz"
INSTALL_FILE="splunkforwarder-9.0.1-82c987350fde-Linux-x86_64.tgz"
INSTALL_LOCATION="/opt"

export SPLUNK_HOME="$INSTALL_LOCATION/splunkforwarder"

groupadd -f splunk
id -u splunk >/dev/null 2>&1 || useradd splunk -g splunk

#rm -rf $INSTALL_FILE
chown -R splunk:splunk $SPLUNK_HOME

# Grant splunk user read access to logs
setfacl -R -m u:splunk:r /var/log

#install the forwarder
cd /opt/
wget -O $INSTALL_FILE $DOWNLOAD_URL
tar -zxvf $INSTALL_FILE

# Create boot-start systemd service
$SPLUNK_HOME/bin/splunk stop
sleep 10

# Start splunk forwarder
$SPLUNK_HOME/bin/splunk start --accept-license --no-prompt --answer-yes

$SPLUNK_HOME/bin/splunk enable boot-start -systemd-managed 1 -user splunk -group splunk
chown -R splunk:splunk $SPLUNK_HOME

#$SPLUNK_HOME/bin/splunk start
#cd /opt/splunk-dir/bin/ 
#cd  /opt/splunkforwarder/bin	
#sudo ./splunk start --accept-license 
#sudo ./splunk enable boot-start

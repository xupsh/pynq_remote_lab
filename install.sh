#!/bin/bash

XILINX_HOME=/home/xilinx
XILINX_PWD=temp_pwd_
XILINX_PWD+=$((RANDOM%1000))

pushd $XILINX_HOME

#Here to put your own MySQL info
CONNECT="mysql -hxxx.xxx.xxx -uroot -pxxxxxxxxxxxx -Dpynq"

function set_pynqname {
    echo "rename pynq:"
    read name
    PYNQ_NAME=$name
    checkname
    echo "Name has been updated-->${PYNQ_NAME}"
}

function checkname {
    CHECKNAME="select count(*) from pynq where usrname='${PYNQ_NAME}'"
    RESULT=$(${CONNECT} -s -e "${CHECKNAME}")

    if [[ $RESULT -eq 1 ]]
        then
        echo "Existed. Now Overwrite."
        delete_db
        insert_db_newline
        else
        insert_db_newline
        echo "New Machine added"
    fi
}

function delete_db {
    DELETE="delete from pynq where usrname='${PYNQ_NAME}'"
    ${CONNECT} -e "${DELETE}"
}

function insert_db_newline {
    INSERT="insert into pynq set usrname='${PYNQ_NAME}', pswd='empty', status=1, reset=0, connection=0"
    ${CONNECT} -e "${INSERT}"
}

function setup_password {
    info_msg "Setting password for user 'xilinx'"
    echo "xilinx:$XILINX_PWD" | sudo chpasswd

    info_msg "**************************************"
    info_msg "*** PASSWORD : ${XILINX_PWD}   ****"
    info_msg "**************************************"
    ${CONNECT} -e "update pynq set pswd='${XILINX_PWD}' where usrname='${PYNQ_NAME}'"
    echo "pswd in DB has been changed"
}

function set_httpport {
    echo "http port:"
    read httpport
}

function set_sshport {
    echo "ssh port:"
    read sshport
}

function port_db {
    ${CONNECT} -e "update pynq set ssh_port=${sshport}, http_port=${httpport} where usrname='${PYNQ_NAME}'"
}

function get_ip {
    local_ip=$(ifconfig | grep inet | grep -v inet6 | grep -v 127 |sed 's/^[ \t]*//g' | cut -d ' ' -f2 | head -1)
    ${CONNECT} -e "update pynq set ip='${local_ip}' where usrname='${PYNQ_NAME}'"
}
function info_msg {
  echo -e "INFO: $1"
}

function err_msg {
  echo -e >&2 "ERROR: $1"
}

sudo apt-get update
sudo apt-get install mysql-server
sudo apt-get install mysql-client
sudo apt-get install libmysqlclient-dev
sudo pip3 install pymysql

sudo chmod -R 777 /home/xilinx/Xilinx/remote
sudo cp -r /home/xilinx/Xilinx/remote /etc/pynq_remote
sudo chmod -R 777 /etc/pynq_remote

#check the time
sudo cp /etc/pynq_remote/time/time.service /etc/systemd/system/time.service
sudo systemctl start time
sudo systemctl enable time

set_pynqname
sed -i '2c PYNQ_NAME=\"'${PYNQ_NAME}'\"' /etc/pynq_remote/listen/reset.sh
set_httpport
sed -i '4c delete  remote_port: '${httpport}'' /etc/pynq_remote/ngrok/ngrok.cfg
sed -i '5c delete  subdomain: \"'${PYNQ_NAME}'\"' /etc/pynq_remote/ngrok/ngrok.cfg
set_sshport
sed -i '9c delete  remote_port: '${sshport}'' /etc/pynq_remote/ngrok/ngrok.cfg
port_db

setup_password
sed -i "s/delete/  /g" /etc/pynq_remote/ngrok/ngrok.cfg

#ngrok
sudo cp /etc/pynq_remote/ngrok/ngrok.service /etc/systemd/system/ngrok.service
sudo systemctl start ngrok
sudo systemctl enable ngrok

get_ip
sed -i '7c pynq_name=\"'${PYNQ_NAME}'\"' /etc/pynq_remote/listen/sensor.py

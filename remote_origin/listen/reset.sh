#!/bin/bash
PYNQ_NAME="pynq0001"

XILINX_HOME=/home/xilinx
XILINX_PWD=temp_pwd_
XILINX_PWD+=$((RANDOM%1000))

pushd $CENTOS_HOME

#Here to put your own MySQL info
CONNECT="mysql -hxxx.xxx.xxx.xxx -uroot -pxxxxxxxxxx -Dpynq"
OVERALL="select * from pynq"

function get_deadline {
    GETTIME="select endtime from pynq where usrname='${PYNQ_NAME}'"
    ENDTIME=$(${CONNECT} -s -e "${GETTIME}")
    echo "The instance will be terminate on ${ENDTIME}"
}

function show_db {
    ${CONNECT} -e "${OVERALL}"
}

function delete_db {
    DELETE="delete from pynq where usrname='${PYNQ_NAME}'"
    ${CONNECT} -e "${DELETE}"
}

function insert_db {
    INSERT="insert into pynq set usrname='${PYNQ_NAME}', pswd='${XILINX_PWD}', status=0, reset=0, connection=0"
    ${CONNECT} -e "${INSERT}"
}

function reset {
    #recover
    #delete_db
    setup_password
    #nsert_db
    RESETPSWD="update pynq set pswd='${XILINX_PWD}', status=0, reset=0, connection=0, openid=NULL, starttime=NULL, endtime=NULL where usrname='${PYNQ_NAME}'"
    ${CONNECT} -e "${RESETPSWD}"
    echo "reseted"
    show_db
}

function setup_password {
    info_msg "Setting password for user 'xilinx'"
    echo "xilinx:$XILINX_PWD" | sudo chpasswd

    info_msg "**************************************"
    info_msg "*** PASSWORD : ${XILINX_PWD}   ****"
    info_msg "**************************************"
    #${CONNECT} -e "update pynq set pswd='${XILINX_PWD}' where usrname='${PYNQ_NAME}'"
    #echo "pswd in DB has been changed"
}

show_db
RESET=$(${CONNECT} -s -e "select reset from pynq where usrname='${PYNQ_NAME}'")
if [[ $RESET -eq 1 ]]
    then
        reset
    else
        echo "nothing to do"
fi

STATUS=$(${CONNECT} -s -e "select status from pynq where usrname='${PYNQ_NAME}'")
CONNECTION=$(${CONNECT} -s -e "select connection from pynq where usrname='${PYNQ_NAME}'")
if [[ $STATUS -eq 1 ]] && [[ $RESET -eq 0 ]] && [[ $CONNECTION -eq 0 ]]
    then
        #start with predifined name
        CONNECTED="update pynq set connection=1 where usrname='${PYNQ_NAME}'"
        ${CONNECT} -e "${CONNECTED}"
    else
        echo "start"
fi

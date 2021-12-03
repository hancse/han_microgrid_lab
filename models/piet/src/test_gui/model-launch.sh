#!/bin/bash

COMMAND=${1}
LOG_BASE=${2}
LOG_PATH=${3}
LOG_TO_FILE=${4}
CONTINUOUS_LOGS=${5}
STOP_LOGS=${6}
MODEL=${7}
LS=`which ls`
BINARY=`echo ${COMMAND} | awk '{ print $1 }'`
BINARY_PATH=`dirname ${BINARY}`

TEST=$(which rdmsr | grep -Eo "rdmsr")
if [ "${TEST}" = "rdmsr" ]
then
	CPU_NR=$(cat /proc/cpuinfo | grep -E "processor" | grep -Eo "[0-9]+" | sort -nr | head -1)
	for (( i=0; i<=${CP_NR}; i++))
	do
		declare CPU_SMI_CNT_${i}=""
	done
fi

#echo COMMAND=${COMMAND}
#echo LOG_BASE=${LOG_BASE}
#echo LOG_PATH=${LOG_PATH}
#echo LOG_TO_FILE=${LOG_TO_FILE}
#echo CONTINUOUS_LOGS=${CONTINUOUS_LOGS}
#echo STOP_LOGS=${STOP_LOGS}
#echo MODEL=${MODEL}

pre_start()
{
  SCRIPTS=`${LS} ${BINARY_PATH}/scripts/S* 2>/dev/null`
  if [ $? -eq 0 ]; then
    for script in ${SCRIPTS}
    do
      source ${script} >>${LOG_PATH}/prestart.log 2>&1
    done
  fi
}

post_stop()
{
  SCRIPTS=`${LS} ${BINARY_PATH}/scripts/K* 2>/dev/null`
  if [ $? -eq 0 ]; then
    for script in ${SCRIPTS}
    do
      source ${script} >>${LOG_PATH}/poststop.log 2>&1
    done
  fi
}

function read_smi()
{
	if [ -z ${CPU_NR+x} ]
	then 
		echo -e "msr-tools not installed\ncannot validate constant SMI count" >> ${LOG_PATH}/stderr.log
		return
	fi
	case "$1" in
		"initial")
			for (( i=0; i<=${CPU_NR}; ++i  ))
			do
				declare "CPU_SMI_CNT_${i}=$(rdmsr -p ${i} -u 0x34)"
			done
			;;
		"update")
			for (( i=0; i<=${CPU_NR}; ++i  ))
			do
				dummy="CPU_SMI_CNT_${i}"
				if [ "$(rdmsr -p ${i} -u 0x34)" -gt "${!dummy}" ] #use indirect expansion
				then
					echo "SMI count change for CPU: ${i}" >> ${LOG_PATH}/stderr.log
				fi
			done
			;;
	esac
}

#export environmet variables for license
`awk '{print "export " $1}' /etc/3p/3p.lic`

cd ${LOG_BASE}/..

#remove finished token if it exists
rm -f ${LOG_PATH}/finished.txt

pre_start

#start loggers
LOGGER_PIDS=
for name in ${CONTINUOUS_LOGS}
do
  datalogger ${name} -n -d -c > ${LOG_PATH}/${name}.dat &
  LOGGER_PIDS="${LOGGER_PIDS} $!"
done
for name in ${STOP_LOGS}
do
  datalogger ${name} -n -d  > ${LOG_PATH}/${name}.dat &
  LOGGER_PIDS="${LOGGER_PIDS} $!"
done

read_smi initial

#start model
if [ ${LOG_TO_FILE} -eq 1 ]; then
  ${COMMAND} >${LOG_PATH}/stdout.log 2>${LOG_PATH}/stderr.log 3>${LOG_PATH}/${MODEL}.log
else
  ${COMMAND}
fi

read_smi update

#model has now finished, add finished token
echo 'finished' > ${LOG_PATH}/finished.txt

#stop loggers
if [ ! "${LOGGER_PIDS}" = "" ]; then
  kill ${LOGGER_PIDS}
fi

#log dmesg also
#dmesg -c > ${LOG_PATH}/dmesg.log

#change last & current links
rm -f ${LOG_BASE}/last
ln -f -s ${LOG_PATH} ${LOG_BASE}/last
rm -f ${LOG_BASE}/current

post_stop

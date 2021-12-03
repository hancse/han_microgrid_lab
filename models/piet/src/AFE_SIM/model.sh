#!/bin/bash

MODEL=`grep '^MODEL *=' variables.mk | awk '{print $3}'`
USERNAME=`grep '^USERNAME_LOWERCASE *=' variables.mk | awk '{print $3}'`
EXTMODE=`grep '^TP_EXT_MODE *=' variables.mk | awk '{print $3}'`
EXTMODELIGHT=`grep '^TP_EXT_MODE_LIGHT *=' variables.mk | awk '{print $3}'`
DAYS_TO_PRESERVE_LOG=`grep '^DAYS_TO_PRESERVE_LOG *=' variables.mk | awk '{print $3}'`
CONTINUOUS_LOGS=`grep '^CONTINUOUS_LOGS *=' variables.mk | awk '{for (i=3; i<=NF; i++) { printf("%s ", $i) } printf("\n")}'`
STOP_LOGS=`grep '^STOP_LOGS *=' variables.mk | awk '{for (i=3; i<=NF; i++) { printf("%s ", $i) } printf("\n")}'`
PORT=`grep '^EXTERNAL_MODE_PORT *=' variables.mk | awk '{print $3}'`
TIME=inf
VERBOSE=
LOG_TO_FILE=1
BINARY_PATH=`pwd`
LOG_BASE=/var/log/3p/${USERNAME}/${MODEL}
#SUDO=
#if ! groups triphase | grep xenomai >/dev/null; then
SUDO=sudo
#fi
LS=`which ls`


usage()
{
  cat << EOF

Usage:
    $0 [-p <port>] [-t <time>] [-v] <command> [argument]

    -p      = external mode port (default = 17725)
    -t      = time in seconds (default = inf)
    -v      = verbose, and don't stdout.log & stderr.log
    command = one of
                 loadandstart
                 activateandstart
                 initandstart
                 load
                 activate
                 init
                 kill
                 cleanlogs
                 cleanalllogs
                 tail
                 deletelog date/time
                 showlog [date/time]
                 editcomment [date/time]
                 getlogs
                 getfinishedlogs
                 getlogbase
                 getstatus
                 mode
                 prestart
                 poststop

EOF
                 #debug
}

launch()
{
  COMMAND_BASE="${BINARY_PATH}/${MODEL} -tf ${TIME}"
  LOG_DATE=`date +%y%m%d`
  LOG_TIME=`date +%H%M%S`
  LOG_PATH=${LOG_BASE}/${LOG_DATE}/${LOG_TIME}

  #echo COMMAND_BASE=${COMMAND_BASE}
  #echo LOG_BASE=${LOG_BASE}
  #echo LOG_PATH=${LOG_PATH}

  ${SUDO} mkdir -p ${LOG_PATH}
  ${SUDO} rm -f ${LOG_BASE}/current
  ${SUDO} ln -f -s ${LOG_PATH} ${LOG_BASE}/current

  ${SUDO} ./model-launch.sh "${COMMAND_BASE} ${COMMAND_OPTS}" "${LOG_BASE}" "${LOG_PATH}" "${LOG_TO_FILE}" "${CONTINUOUS_LOGS}" "${STOP_LOGS}" "${MODEL}" > /dev/null 2>&1 &
}

kill_model()
{
  #echo BINARY_PATH=${BINARY_PATH}
  #echo MODEL=${MODEL}

  ${SUDO} killall -w -q ${BINARY_PATH}/${MODEL}
}

clean_logs()
{
  #echo LOG_BASE=${LOG_BASE}
  #echo DAYS_TO_PRESERVE_LOG=${DAYS_TO_PRESERVE_LOG}
  #echo VERBOSE=${VERBOSE}

  if [ ${DAYS_TO_PRESERVE_LOG} -ne -1 ]; then
    DATES_TO_CLEAN=`test -d ${LOG_BASE} && ls ${LOG_BASE} | grep -v "last" | grep -v "current" | head --lines=-${DAYS_TO_PRESERVE_LOG}`
    #echo "DATES_TO_CLEAN=[${DATES_TO_CLEAN}]"
    for date_to_clean in ${DATES_TO_CLEAN}
    do
      if [ ! -z ${VERBOSE} ]; then
        echo Removing log directory for day ${date_to_clean}
      fi
      ${SUDO} rm -rf ${LOG_BASE}/${date_to_clean}
    done
  fi

  # clean current log if it isn't point to a valid directory anymore
  if [ -h ${LOG_BASE}/current -a ! -e ${LOG_BASE}/current ]; then
    ${SUDO} rm -f ${LOG_BASE}/current
  fi

  # clean last log if it isn't point to a valid directory anymore
  if [ -h ${LOG_BASE}/last -a ! -e ${LOG_BASE}/last ]; then
    ${SUDO} rm -f ${LOG_BASE}/last
  fi
}

clean_all_logs()
{
  #echo LOG_BASE=${LOG_BASE}

  ${SUDO} rm -rf ${LOG_BASE}
}

tail_current_log()
{
  #echo LOG_BASE=${LOG_BASE}

  if [ -f ${LOG_BASE}/current/stdout.log ]; then
    ${SUDO} tail -f ${LOG_BASE}/current/stdout.log
  else
    echo "The model is currently not running"
  fi
}

delete_log()
{
  #echo LOG_BASE=${LOG_BASE}
  #echo LOG_SELECT=${LOG_SELECT}

  if [ -e ${LOG_BASE}/${LOG_SELECT} ]; then
    ${SUDO} rm -rf ${LOG_BASE}/${LOG_SELECT}
  else
    echo "No such log directory: ${LOG_SELECT}"
  fi
}

show_log()
{
  #echo LOG_BASE=${LOG_BASE}
  #echo LOG_SELECT=${LOG_SELECT}

  if [ -s ${LOG_BASE}/${LOG_SELECT}/${MODEL}.log ]; then
    echo "*** model log ***"
    ${SUDO} cat ${LOG_BASE}/${LOG_SELECT}/${MODEL}.log
  fi
  if [ -s ${LOG_BASE}/${LOG_SELECT}/stdout.log ]; then
    echo "*** stdout ***"
    ${SUDO} cat ${LOG_BASE}/${LOG_SELECT}/stdout.log
  fi
  if [ -s ${LOG_BASE}/${LOG_SELECT}/stderr.log ]; then
    echo "*** stderr ***"
    ${SUDO} cat ${LOG_BASE}/${LOG_SELECT}/stderr.log
  fi
}

edit_comment()
{
  #echo LOG_BASE=${LOG_BASE}
  #echo LOG_SELECT=${LOG_SELECT}

  EDITOR="nano"
  if [ ! -z ${VISUAL} ]; then
    EDITOR=${VISUAL}
  elif [ ! -z ${EDITOR} ]; then
    EDITOR=${EDITOR}
  fi

  COMMENT_DIR=${LOG_BASE}/${LOG_SELECT}
  if [ -d ${COMMENT_DIR} ]; then
    ${SUDO} ${EDITOR} ${COMMENT_DIR}/comment.txt
  else
    echo "No valid log directory selected: ${LOG_SELECT}"
  fi
}

get_list_of_logs()
{
  #echo LOG_BASE=${LOG_BASE}

  DATES_TO_LIST=`ls ${LOG_BASE} | grep -v "last" | grep -v "current"`
  for date_to_list in ${DATES_TO_LIST}
  do
    TIMES_TO_LIST=`ls ${LOG_BASE}/${date_to_list}`
    for time_to_list in ${TIMES_TO_LIST}
    do
      if [ -f ${LOG_BASE}/${date_to_list}/${time_to_list}/comment.txt ]; then
        COMMENT=`head -1 ${LOG_BASE}/${date_to_list}/${time_to_list}/comment.txt`
      else
        COMMENT=
      fi
      echo ${date_to_list}/${time_to_list}:${COMMENT}
    done
  done
}

get_list_of_finished_logs()
{
  #echo LOG_BASE=${LOG_BASE}

  DATES_TO_LIST=`ls ${LOG_BASE} | grep -v "last" | grep -v "current"`
  for date_to_list in ${DATES_TO_LIST}
  do
    TIMES_TO_LIST=`ls ${LOG_BASE}/${date_to_list}`
    for time_to_list in ${TIMES_TO_LIST}
    do
      if [ -s ${LOG_BASE}/${date_to_list}/${time_to_list}/finished.txt ]; then
        if [ -f ${LOG_BASE}/${date_to_list}/${time_to_list}/comment.txt ]; then
          COMMENT=`head -1 ${LOG_BASE}/${date_to_list}/${time_to_list}/comment.txt`
        else
          COMMENT=
        fi
        echo ${date_to_list}/${time_to_list}:${COMMENT}
      fi
    done
  done
}

get_status()
{
  #echo BINARY_PATH=${BINARY_PATH}
  #echo MODEL=${MODEL}

  PID=`pidof ${BINARY_PATH}/${MODEL}`
  if [ -z ${PID} ]; then
    echo "The model is not loaded"
  else
    echo "The model is loaded: PID = ${PID}"
  fi
}

pre_start()
{
  SCRIPTS=`${LS} ${BINARY_PATH}/scripts/S* 2>/dev/null`
  if [ $? -eq 0 ]; then
    for script in ${SCRIPTS}
    do
      source ${script}
    done
  fi
}

post_stop()
{
  SCRIPTS=`${LS} ${BINARY_PATH}/scripts/K* 2>/dev/null`
  if [ $? -eq 0 ]; then
    for script in ${SCRIPTS}
    do
      source ${script}
    done
  fi
}

debug_print()
{
  echo MODEL=${MODEL}
  echo USERNAME=${USERNAME}
  echo DAYS_TO_PRESERVE_LOG=${DAYS_TO_PRESERVE_LOG}
  echo CONTINUOUS_LOGS=${CONTINUOUS_LOGS}
  echo STOP_LOGS=${STOP_LOGS}
  echo PORT=${PORT}
  echo TIME=${TIME}
  echo VERBOSE=${VERBOSE}
  echo LOG_TO_FILE=${LOG_TO_FILE}
  echo BINARY_PATH=${BINARY_PATH}
}

while getopts "p:t:v" option
do
  case $option in
    p) PORT=$OPTARG ;;
    t) TIME=$OPTARG ;;
    v) VERBOSE="-tpverbose"
       LOG_TO_FILE=0
       ;;
  esac
done
shift $(($OPTIND - 1))

case "$1" in
  loadandstart)
    COMMAND_OPTS="-tpport ${PORT} ${VERBOSE}"
    clean_logs
    launch
    ;;

  load)
    COMMAND_OPTS="-tpport ${PORT} ${VERBOSE} -tpwait"
    clean_logs
    launch
    ;;

  activateandstart)
    COMMAND_OPTS="-port ${PORT}"
    if [ ${EXTMODELIGHT} -eq 1 ]; then
      COMMAND_OPTS+=" ${VERBOSE}"
    fi
    clean_logs
    launch
    ;;

  activate)
    COMMAND_OPTS="-port ${PORT} -w"
    if [ ${EXTMODELIGHT} -eq 1 ]; then
      COMMAND_OPTS+=" ${VERBOSE}"
    fi
    clean_logs
    launch
    ;;

  initandstart)
    if [ ${EXTMODE} -eq 1 ]; then
      $0 loadandstart
    else
      $0 activateandstart
    fi
    ;;

  init)
    if [ ${EXTMODE} -eq 1 ]; then
      $0 load
    else
      $0 activate
    fi
    ;;

  mode)
    if [ ${EXTMODE} -eq 1 ]; then
      echo "3p"
    elif [ ${EXTMODELIGHT} -eq 1 ]; then
      echo "3plight"
    else
      echo "sim"
    fi
    ;;

  kill)
    kill_model
    ;; 

  cleanlogs)
    VERBOSE=1
    clean_logs
    ;;

  cleanalllogs)
    clean_all_logs
    ;;

  tail)
    tail_current_log
    ;;

  deletelog)
    LOG_SELECT=$2
    if [ -z ${LOG_SELECT} ]; then
      echo "No log directory selected"
    else
      delete_log
    fi
    ;;
 
  showlog)
    LOG_SELECT=$2
    if [ -z ${LOG_SELECT} ]; then
      LOG_SELECT="last"
    fi
    show_log
    ;;

  editcomment)
    LOG_SELECT=$2
    if [ -z ${LOG_SELECT} ]; then
      if [ -e ${LOG_BASE}/current ]; then
        LOG_SELECT="current"
      elif [ -e ${LOG_BASE}/last ]; then
        LOG_SELECT="last"
      else
        echo "No current or last log directory found"
      fi
    fi
    edit_comment
    ;;

  getlogs)
    get_list_of_logs
    ;;

  getfinishedlogs)
    get_list_of_finished_logs
    ;;

  getlogbase)
    echo ${LOG_BASE}
    ;;

  getstatus)
    get_status
    ;;

  debug)
    debug_print
    ;;

  prestart)
    pre_start
    ;;

  poststop)
    post_stop
    ;;

  *)
    usage
    exit 1
esac

exit 0

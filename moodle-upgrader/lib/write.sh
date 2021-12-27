#!/bin/bash

escribir () {
  echo -e "[DOING] ${WHITE}${@}${NC}" | tee -a ${LOG_FILE}
}

escribir_debug () {
  if [ $DEBUGGING -gt 0 ]
  then
    echo -e "${DEBUG}[DEBUG] ${WHITE}${@}${NC}" | tee -a ${LOG_FILE}
  fi
}

escribir_exeCute () {
  if [ $DEBUGGING -gt 0 ]
  then
    echo -e "${RUN}[ RUN ] ${WHITE}${@}${NC}" | tee -a ${LOG_FILE}
  fi
}

escribir_exeCute_response () {
  # response= head -n5 $@
  echo -e "${RESPONSE}[RESP.] ${WHITE} $@ ${NC}" | tee -a ${LOG_FILE}
  # if [ $# -gt 1 ]
  # then
  # fi
}

escribir_error () {
  echo -e "${R}[ERROR] ${WHITE}${@}${NC}" | tee -a ${LOG_FILE}
}

escribir_header () {
  echo -e "${@}" | tee -a ${LOG_FILE}
}

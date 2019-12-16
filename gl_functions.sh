#!/bin/bash
#
#   gl_functions.sh
#
#   Copyright (C) 2019  GuideLoom Inc./Trevor Paquette
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# some ideas from here
# http://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/

# setting variable in your scripts to change the behavior of some of these functions.
# see below for list of variables and their functions

# version of this functions script
gl_version=1.02

# syslog enable
# 0 = do not send to syslog
# 1 = send to syslog
# default: 0
gl_syslog=0

# stderr enable
# 0 = do not send to strerr
# 1 = send to stderr
# default: 0
# NOTE: reset to zero after each call!
gl_stderr=0

# syslogid to use when sending to syslog
# set to string to use
# default: not set
gl_syslogid=""

# enable dryrun (aka show, but do not execute command) mode
# not 100% complete. "some" commands still need special consideration
# 0 = run as normal
# 1 = dryrun only. display command only
# default: 0
gl_dryrun=0

# glocal no config file read option
# 0 = read config file options as normal
# 1 = disregard any configile reads
# default: 0
gl_noconf=0

# timeformat to display in logs (syslog uses it;s own format)
gl_timeformat="%Y%m%d-%H%M%S"

# sed command to strip blank lines and comments
gl_sedsbc='sed -e '/^\s*#.*$/d' -e '/^\s*$/d''


# =======================================================
# display the commands passed if gl_dryrun is set
# otherwise, run the actual command
gl_run () {
  if [[ "${gl_dryrun}" -eq 1 ]]; then
    printf "%s\n" "$*"
    return 0
  fi

  eval "$@"
}

# =======================================================
# log a single line function
# set global var gl_syslog to "1" to enable syslog output as well
# set global var gl_timeformat to change the timestamp output to use
#
gl_log() {

  local gl_logtimestamp

  gl_logtimestamp=$(date +${gl_timeformat})
    
  # echo the log message
  if [[ "${gl_stderr}" -eq 1 ]]; then
    printf "%s\n" "${gl_logtimestamp} $*" >&2;
    # force reset
    gl_stderr=0
  else
    printf "%s\n" "${gl_logtimestamp} $*"
  fi      

  # If syslog is enabled, also log the message to syslog
  if [[ "${gl_syslog}" -eq 1 ]]; then
    printf "%s\n" "$*" | logger -t "${gl_syslogid}"
  fi

}

# =======================================================
# log a complete file to screen and syslog (if enabled)
# 
gl_logfile() {

  local gl_file

  gl_file="$*"
    
  if [[ "${gl_file}" != "" ]]; then 
    if [[ -f "${gl_file}" ]]; then
      cat "${gl_file}" | gawk -v TIMEFORMAT="${gl_timeformat}" '{ print strftime(TIMEFORMAT), $0 }'
      # If syslog is enabled, also log the file to syslog
      if [[ "${gl_syslog}" -eq 1 ]]; then
        logger -t "${gl_syslogid}" -f "$@"
      fi
    else
      log "logfile ${gl_file} not found. Cannot log it."
    fi
  fi
}

# =======================================================
# convert raw number of seconds passed to HH:MM:SS format
gl_secstohms() {
  local gl_h
  local gl_m
  local gl_s
    
  ((gl_h=${1}/3600))
  ((gl_m=(${1}%3600)/60))
  ((gl_s=${1}%60))

  printf "%02d:%02d:%02d\n" $gl_h $gl_m $gl_s
}

# =======================================================
# is arguement passed a number?
gl_isnum() {
 gawk -v gl_a="$1" 'BEGIN {print (gl_a == gl_a + 0)}';
}

# =======================================================
# check if array passed contains the passed element
# arg 1 = array
# arg 2 = element
gl_array_contains () {
  # return 1 if sucessful, found
  # return 0 if error, not found
    
  local gl_array="$1[@]"
  local gl_item=$2
  local gl_in=0
  local gl_element
  
  for gl_element in "${!gl_array}"; do
    if [[ $gl_element == $gl_item ]]; then
      gl_in=1
      break
    fi
  done

  echo $gl_in
}

# =======================================================
# check if all items in array passed can be found
# these are programs to use.
# 
# arg 1 = verbose error (1 = output error, 0 = silent)
# arg 2 = array

gl_checkprereqs () {
  # return 0 if all elements found
  # return 1 if missing any element
    
  local gl_verbose=$1
  local -n gl_array=$2
#  local gl_array=${2[@]}

  local gl_element
  local gl_status
  local gl_return=""
  
  for gl_element in "${gl_array[@]}"; do
    # look for file called gl_element
    if [[ ! -f ${gl_element} ]]; then
      # not a file, check if command in path
      command -v ${gl_element} >& /dev/null
      gl_status=$?
      if [[ ${gl_status} -ne 0 ]]; then
        if [[ ${gl_verbose} -ne 0 ]]; then
          gl_log "Error: ${gl_element} command not found. Check path or not installed."
        fi
        gl_return=1
      fi
    fi
  done

  if [[ ${gl_verbose} -eq 0 ]]; then
    echo ${gl_return}
  fi
}

# =======================================================
# get options form a file.
# assumes all options are in "var=value" format
# work on "spaces" allowed around "=" later. ie: var = value
# also assumes variables are case INSENSITIVE

gl_getconfopt () {
  # get config option from conf file
  # 1st arg = filename to use
  # 2nd arg = option to search for
    
  # option to look for in the files is option=value

  local gl_file=$1
  local gl_option=$2
  local gl_result=""
  

  # read config file value, only if --noconf is not set
  if [[ "${gl_noconf}" -eq 0 ]]; then
    # convert option to lowercase
    gl_option=$(printf "%s" "${gl_option}" | tr '[A-Z]' '[a-z]')
  
    if [[ -f "${gl_file}" ]]; then
      gl_result=$(grep -E "^${gl_option}=" ${gl_file} | cut -d= -f2)
    fi
  fi
  
  echo "${gl_result}"
}

# ================================================================================
gl_getvar() {
  # return the value of a variable based on the arguments passed.
  # Arguments passed 
  # variable type to process: "string" or "number"
  # default value
  # default value null/blank ok (1 = ok, 0 = skip blanks)
  # global config file value
  # global config file value null/blank ok (1 = ok, 0 = skip blanks)
  # vm config file value
  # vm config file value null/blank ok (1 = ok, 0 = skip blanks)
  # cli config value
  # cli config value null/blank ok (1 = ok, 0 = skip blanks)

  # set to "string" or "number"
  local vartype=$1

  local dflt_value=$2
  local dflt_value_null=$3

  local glob_value=$4
  local glob_value_null=$5

  local vm_value=$6
  local vm_value_null=$7

  local cli_value=$8
  local cli_value_null=$9

  local result=""
  
  if [[ "${vartype}" == "string" ]]; then
    # check for strings

    # check default value
    if [[ "${dflt_value_null}" -eq 1 ]]; then
      result="${dflt_value}"
    elif [[ "${dflt_value}" != "" ]]; then
      result="${dflt_value}"
    fi

    # check glob, which overrides defaults
    if [[ "${glob_value_null}" -eq 1 ]]; then
      result="${glob_value}"
    elif [[ "${glob_value}" != "" ]]; then
      result="${glob_value}"
    fi

    # check vm
    if [[ "${vm_value_null}" -eq 1 ]]; then
      result="${vm_value}"
    elif [[ "${vm_value}" != "" ]]; then
      result="${vm_value}"
    fi

    # check cli
    if [[ "${cli_value_null}" -eq 1 ]]; then
      result="${cli_value}"
    elif [[ "${cli_value}" != "" ]]; then
      result="${cli_value}"
    fi
      
  elif [[ "${vartype}" == "number" ]]; then
    # check for numbers

    # check default value
    if [[ "${dflt_value_null}" -eq 1 ]]; then
      result="${dflt_value}"
    elif [[ "${dflt_value}" != "" ]]; then
      result="${dflt_value}"
    fi

    # check glob, which overrides defaults
    if [[ "${glob_value_null}" -eq 1 ]]; then
      result="${glob_value}"
    elif [[ "${glob_value}" != "" ]]; then
      result="${glob_value}"
    fi

    # check vm
    if [[ "${vm_value_null}" -eq 1 ]]; then
      result="${vm_value}"
    elif [[ "${vm_value}" != "" ]]; then
      result="${vm_value}"
    fi

    # check cli
    if [[ "${cli_value_null}" -eq 1 ]]; then
      result="${cli_value}"
    elif [[ "${cli_value}" != "" ]]; then
      result="${cli_value}"
    fi

  else
    log "Error in getvar: vartype arguement not set correctly."
    return 1
  fi
  
  echo "${result}"

}

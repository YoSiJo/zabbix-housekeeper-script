#!/usr/bin/env bash

###
# Aoutor: York-Simon Johannsen ( zabbix-housekeeping-script@yosijo.de )
#
# Script for manual runs of zabbix housekeeping jobs on mysql databese.
###

function fCheckEqualChar() {
  echo "${1}" | grep -Pq '^--[a-z\-]+='
}

function fHelp() {
echo -e "Usage: (-d |--database( |=))[OPTION] (-h|--help) …

Script options:
  • --alerts-age( |=)\e[4mtimestamp\e[0m
    Specifies the maximum age of the values, in unix timestamp format.

  • --database( |=)\e[4mdatabese name\e[0m, -d \e[4mdatabese name\e[0m
    The database to use.

  • --debug, -D
    Enable debug mode.

  • --help, -h
    Display a help message and exit.

  • --history-age( |=)\e[4mtimestamp\e[0m
    Specifies the maximum age of the values, in unix timestamp format.

  • --host( |=)\e[4mip or dns\e[0m, -H \e[4mip or dns\e[0m
    Connect to the mysql server on the given host.

  • --limit( |=)\e[4mrow_count\e[0m, -l \e[4mrow_count\e[0m
    Add the \e[4mLIMIT\e[0m \e[4mrow_count\e[0m statement to the \e[4mDELETE\e[0m query.

  • --low-priority, -L
    Add the \e[4mLOW_PRIORITY\e[0m statement to the \e[4mDELETE\e[0m query.

  • --password( |=)\e[4mpassword\e[0m, -p \e[4mpassword\e[0m
    The password to use when connecting to the server.

  • --port( |=)\e[4mport\e[0m, -P \e[4mport\e[0m
    The TCP/IP port number to use for the connection or 0 for default to, in order of preference, my.cnf, $MYSQL_TCP_PORT, /etc/services, built-in default (3306).

  • --socket( |=)\e[4mpath\e[0m, -s \e[4mpath\e[0m
    The TCP/IP port number to use for the connection or 0 for default to, in order of preference, my.cnf, $MYSQL_TCP_PORT, /etc/services, built-in default (3306).

  • --time-log, -t
    Add time output lines. (iso-8601)

  • --trends-age( |=)\e[4mtimestamp\e[0m
    Specifies the maximum age of the values, in unix timestamp format.

  • --user( |=)\e[4musername\e[0m, -u \e[4musername\e[0m
    The MariaDB user name to use when connecting to the server.
"
exit $1
}

function fParseArguments() {
  POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      --alerts-age|--alerts-age=*)
      if fCheckEqualChar "${key}" ; then
        vAlertsAge="${key#*=}"
        shift
      else
        vAlertsAge="$2"
        shift; shift
      fi
      ;;
      -d|--database|--database=*)
      if fCheckEqualChar "${key}" ; then
        vDatabase="${key#*=}"
        shift # past value
      else
        vDatabase="$2"
        shift # past argument
        shift # past value
      fi
      ;;
      -D|--debug)
        vDebug=true
        shift
      ;;
      -h|--help)
        fHelp 0
      ;;
      --history-age|--history-age=*)
      if fCheckEqualChar "${key}" ; then
        vHistoryAge="${key#*=}"
        shift
      else
        vHistoryAge="$2"
        shift; shift
      fi
      ;;
      -H|--host|--host=*)
      if fCheckEqualChar "${key}" ; then
        vHost="${key#*=}"
        shift # past value
      else
        vHost="$2"
        shift # past argument
        shift # past value
      fi
      ;;
      -l|--limit|--limit=*)
      if fCheckEqualChar "${key}" ; then
        vLimit="${key#*=}"
        shift # past value
      else
        vLimit="$2"
        shift; shift
      fi
      ;;
      -L|--low-priority)
        vLowPriority=true
        shift
      ;;
      -p|--password|--password=*)
      if fCheckEqualChar "${key}" ; then
        vPassword="${key#*=}"
        shift # past value
      else
        vPassword="$2"
        shift # past argument
        shift # past value
      fi
      ;;
      -P|--port|--port=*)
      if fCheckEqualChar "${key}" ; then
        vPort="${key#*=}"
        shift # past value
      else
        vPort="$2"
        shift # past argument
        shift # past value
      fi
      ;;
      -s|--socket|--socket=*)
      if fCheckEqualChar "${key}" ; then
        vSocket="${key#*=}"
        shift # past value
      else
        vSocket="$2"
        shift # past argument
        shift # past value
      fi
      ;;
      -t|--time-log)
        vTimeLog=true
        shift
      ;;
      --trends-age|--trends-age=*)
      if fCheckEqualChar "${key}" ; then
        vTrendsAge="${key#*=}"
        shift
      else
        vTrendsAge="$2"
        shift; shift
      fi
      ;;
      -u|--user|--user=*)
      if fCheckEqualChar "${key}" ; then
        vUser="${key#*=}"
        shift # past value
      else
        vUser="$2"
        shift # past argument
        shift # past value
      fi
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
    esac
  done
  set -- "${POSITIONAL[@]}" # restore positional parameters
}

function fTimeLog() {
  echo "$(date --iso-8601=seconds): ${@}"
}

function fRunDelete() {
  vRunAge="${1}"
  vRunTables="${2}"

  if [ ! -z "${vDebug}" ] ; then
    echo "vRunAge:            ${vRunAge}"
    echo "vRunTables:         ${vRunTables}"
    echo "vRunSetLimit:       ${vRunSetLimit}"
    echo "vRunSetLowPriority: ${vRunSetLowPriority}"
  fi
  [ ! -z "${vTimeLog}" ] && fTimeLog "Start run for tables: ${vRunTables}."

  for tTable in ${vRunTables}; do
    [ ! -z "${vTimeLog}" ] && fTimeLog "Start run for table: ${tTable}."
    vRunCount=1
    vRunExitCountSum=0

    if [ ! -z ${vDebug} ] ; then
      echo "tTable: ${tTable}"
    fi

    while true; do
      [ ! -z "${vTimeLog+x}" ] && fTimeLog "Run ${vRunCount} for ${vRunTables} start."
      vRunExitCount=$( ${vMysqlBin} -u ${vUser} ${vDatabase} -p${vPassword} ${vMysqlCon} -e "DELETE ${vRunSetLowPriority} FROM ${tTable} where clock < ${vRunAge} ${vRunSetLimit}; SELECT ROW_COUNT();" | grep -Po '^[0-9]+' )
      fTimeLog "Run: Delete ${vRunExitCount} rows from ${tTable}."
      [ ! -z "${vTimeLog}" ] && fTimeLog "Run ${vRunCount} for ${vRunTables} finish."

      vRunCount=$(( ${vRunCount} + 1 ))
      vRunExitCountSum=$(( ${vRunExitCountSum} + ${vRunExitCount} ))

      [[ ! "${vRunExitCount}" -eq "${vLimit}" ]]      && break
      [ -z ${vRunSetLimit+x} ]                        && break
    done
    [ ! -z "${vTimeLog}" ] && fTimeLog "Finish run for table: ${tTable}."
    fTimeLog "Summery: Delete ${vRunExitCountSum} rows from ${tTable}."
  done
  [ ! -z "${vTimeLog}" ] && fTimeLog "Finish run for tables: ${vRunTables}."
}

fParseArguments "$@"

vMysqlBin="$( which mysql )"
vTablesHistory="history history_uint history_str history_text history_log"
vTablesTrends="trends trends_uint"
vTablesAlerts="alerts"

[ ! -z ${vLimit} ]        && vRunSetLimit="LIMIT ${vLimit}"
[ ! -z ${vLowPriority} ]  && vRunSetLowPriority="LOW_PRIORITY"
if [ ! -z ${vSocket} ] && [ ! -z ${vHost} ]; then
  fHelp 1
elif [ ! -z ${vSocket} ]; then
  vMysqlCon="--socket=${vSocket}"
else
  vMysqlCon="--host=${vHost}"
  [ ! -z ${vPort} ] && vMysqlCon="${vMysqlCon} --port=${vPort}"
fi

if [ ! -z "${vDebug}" ] ; then
echo "ARGUMENTS:
  vDatabase:    ${vDatabase}
  vHost:        ${vHost}
  vPassword:    ${vPassword}
  vPort:        ${vPort}
  vSocket:      ${vSocket}
  vUser:        ${vUser}
  vDebug:       ${vDebug}
  vTimeLog:     ${vTimeLog}
  vLowPriority: ${vLowPriority}
  vAlertsAge:   ${vAlertsAge}
  vHistoryAge:  ${vHistoryAge}
  vTrendsAge:   ${vTrendsAge}
  vLimit:       ${vLimit}

ENV:
  vMysqlBin:    ${vMysqlBin}
"
fi

[ ! -z "${vTimeLog}" ] && fTimeLog "Start Run."

if [ ! -z "${vAlertsAge}" ]; then
  [ ! -z "${vTimeLog}" ] && fTimeLog "Start alerts delete run."
    fRunDelete "${vAlertsAge}" "${vTablesAlerts}"
  [ ! -z "${vTimeLog}" ] && fTimeLog "Start alerts delete run."
fi

if [ ! -z "${vTrendsAge}" ]; then
  [ ! -z "${vTimeLog}" ] && fTimeLog "Start trends delete run."
    fRunDelete "${vTrendsAge}" "${vTablesTrends}"
  [ ! -z "${vTimeLog}" ] && fTimeLog "Start trends delete run."
fi

if [ ! -z "${vHistoryAge}" ]; then
  [ ! -z "${vTimeLog}" ] && fTimeLog "Start trends delete run."
    fRunDelete "${vHistoryAge}" "${vTablesHistory}"
  [ ! -z "${vTimeLog}" ] && fTimeLog "Start trends delete run."
fi

[ ! -z "${vTimeLog}" ] && fTimeLog "Start End."

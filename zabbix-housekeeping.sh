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

  • --dry-run
    Enable dry run mode.

  • --exclude-table( |=)\e[4m'regex'\e[0m, -e \e[4m'regex'\e[0m
    You can define a regular expression, which makes sure that the table is not treated when it is hit.
    Used 'grep -Pq', for more information use 'man grep'
    Use '--dry-run' for test. The skipped step have no output.
    Example: ^(trends|trends_unit)$

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

  • --run-max( |=)\e[4mnumber\e[0m, -s \e[4mnumber\e[0m
    Set the max runs for deletions replays.

  • --socket( |=)\e[4mpath\e[0m, -s \e[4mpath\e[0m
    For connections to localhost, the Unix socket file to use, or, on Windows, the name of the named pipe to use.

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
          shift
        else
          vDatabase="$2"
          shift; shift
        fi
      ;;
      -D|--debug)
        vDebug=true
        shift
      ;;
      --dry-run)
        vDryRun=true
        shift
      ;;
      -e|--exclude-table|--exclude-table=*)
        if fCheckEqualChar "${key}" ; then
          vExcludeTable="${key#*=}"
          shift
        else
          vExcludeTable="${2}"
          shift; shift
        fi
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
          shift
        else
          vHost="$2"
          shift; shift
        fi
      ;;
      -l|--limit|--limit=*)
        if fCheckEqualChar "${key}" ; then
          vLimit="${key#*=}"
          shift
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
          shift
        else
          vPassword="$2"
          shift; shift
        fi
      ;;
      -P|--port|--port=*)
        if fCheckEqualChar "${key}" ; then
          vPort="${key#*=}"
          shift
        else
          vPort="$2"
          shift; shift
        fi
      ;;
      -r|--run-max|--run-max=*)
        if fCheckEqualChar "${key}" ; then
          vRunMax="${key#*=}"
          shift
        else
          vRunMax="$2"
          shift; shift
        fi
      ;;
      -s|--socket|--socket=*)
        if fCheckEqualChar "${key}" ; then
          vSocket="${key#*=}"
          shift
        else
          vSocket="$2"
          shift; shift
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
          shift
        else
          vUser="$2"
          shift; shift
        fi
      ;;
      *)
        echo "Bad options!"
        fHelp 1
      ;;
    esac
  done
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
    vRunCount=0
    vRunExitCountSum=0

    if [ ! -z ${vDebug} ] ; then
      echo "tTable: ${tTable}"
    fi

    while true; do
      echo "${tTable}" | grep -Pq "${vExcludeTable}" && break
      vRunCount=$(( ${vRunCount} + 1 ))

      [ ! -z "${vTimeLog+x}" ] && fTimeLog "Run ${vRunCount} for ${tTable} start."
      if [ -z ${vDryRun} ]; then
        vRunExitCount=$( ${vMysqlBin} ${vMysqlCon} ${vDatabase} --execute="DELETE ${vRunSetLowPriority} FROM ${tTable} WHERE clock < ${vRunAge} ${vRunSetLimit}; SELECT ROW_COUNT();" | grep -Po '^[0-9]+' )
        fTimeLog "Run: Delete ${vRunExitCount} rows from ${tTable}."
      else
        echo "$(date --iso-8601=seconds): Dry run commad: ${vMysqlBin} ${vMysqlCon} ${vDatabase} --execute=\"DELETE ${vRunSetLowPriority} FROM ${tTable} WHERE clock < ${vRunAge} ${vRunSetLimit}; SELECT ROW_COUNT();\" | grep -Po '^[0-9]+'"
        vRunExitCount=0
      fi
      [ ! -z "${vTimeLog}" ] && fTimeLog "Run ${vRunCount} for ${tTable} finish."

      vRunExitCountSum=$(( ${vRunExitCountSum} + ${vRunExitCount} ))

      [[ ! "${vRunExitCount}" -eq "${vLimit}" ]] && break
      [ -z ${vRunSetLimit+x} ]                   && break
      [[ "${vRunCount}" -eq "${vRunMax}" ]]      && break
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

[ ! -z ${vLimit} ]       && vRunSetLimit="LIMIT ${vLimit}"
[ ! -z ${vLowPriority} ] && vRunSetLowPriority="LOW_PRIORITY"
[ ! -z ${vUser} ]        && vMysqlCon="${vMysqlCon} --user=\"${vUser}\""
[ ! -z ${vPassword} ]    && vMysqlCon="${vMysqlCon} --password=\"${vPassword}\""
if [ ! -z ${vSocket} ]   && [ ! -z ${vHost} ]; then
  fHelp 1
elif [ ! -z ${vSocket} ]; then
  vMysqlCon="${vMysqlCon} --socket=${vSocket}"
else
  [ ! -z ${vHost} ] && vMysqlCon="${vMysqlCon} --host=${vHost}"
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

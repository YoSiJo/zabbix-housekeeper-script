# zabbix-housekeeper-script
Script for manual housekkeping of zabbix

## WARNING
This script has not yet been extensively tested and has not yet been reviewed by others.
Use at your own risk.

## Usage

```
Usage: (-d |--database( |=))[OPTION] (-h|--help) …
```

## Options

### --alerts-age( |=)timestamp
Specifies the maximum age of the values, in unix timestamp format.

### --database( |=)databese name, -d databese name
The database to use.

### --debug, -D
Enable debug mode.

### --help, -h
Display a help message and exit.

### --history-age( |=)timestamp
Specifies the maximum age of the values, in unix timestamp format.

### --host( |=)ip or dns, -H ip or dns
Connect to the mysql server on the given host.

### --limit( |=)row_count, -l row_count
Add the LIMIT row_count statement to the DELETE query.

### --low-priority, -L
Add the LOW_PRIORITY statement to the DELETE query.

### --password( |=)password, -p password
The password to use when connecting to the server.

### --port( |=)port, -P port
The TCP/IP port number to use for the connection or 0 for default to, in order of preference, my.cnf, , /etc/services, built-in default (3306).

### --run-max( |=)number, -s number
Set the max runs for deletions replays.

### --socket( |=)path, -s path
The TCP/IP port number to use for the connection or 0 for default to, in order of preference, my.cnf, , /etc/services, built-in default (3306).

### --time-log, -t
Add time output lines. (iso-8601)

### --trends-age( |=)timestamp
Specifies the maximum age of the values, in unix timestamp format.

### --user( |=)username, -u username
The MariaDB user name to use when connecting to the server.

## Example

Delete all values from the trends tables that are older than 354 days with the LOW_PRIORITY specification and a LIMIT of 1000.

```
./zabbix-housekeeping.sh --database=example --host=127.0.0.1 --password='example' --user=example --trends-age=$(expr \`date +%s\` - $((60*60*24*354)) ) --low-priority --limit=1000
```


Delete all values from the alerts table that are older than 354 days with the LOW_PRIORITY specification and without LIMIT.

```
./zabbix-housekeeping.sh --database=example --host=127.0.0.1 --password='example' --user=example --trends-age=$(expr `date +%s` - $((60*60*24*354)) ) --low-priority
```


Delete all values from the historys tables that are older than 354 days without the LOW_PRIORITY specification and without LIMIT.

```
./zabbix-housekeeping.sh --database=example --host=127.0.0.1 --password='example' --user=example --trends-age=$(expr `date +%s` - $((60*60*24*354)) )
```

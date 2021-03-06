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

### --exclude-table( |=)'regex', -e 'regex'
You can define a regular expression, which makes sure that the table is not treated when it is hit.

Used `grep -Pq`, for more information use 'man grep'

Use `--dry-run` for test. The skipped step have no output.
Example: `--exclude-table '^(history|history_uints)$'`

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
For connections to localhost, the Unix socket file to use, or, on Windows, the name of the named pipe to use.

### --table-history-age( |=)timestamp
Run the DELETE query for the 'history' table.

### --table-history-log-age( |=)timestamp
Run the DELETE query for the 'history_log' table.

### --table-history-str-age( |=)timestamp
Run the DELETE query for the 'history_str' table.

### --table-history-text-age( |=)timestamp
Run the DELETE query for the 'history_text' table.

### --table-history-uint-age( |=)timestamp
Run the DELETE query for the 'history_uint' table.

### --table-trends-age( |=)timestamp
Run the DELETE query for the 'trends' table.

### --table-trends-uint-age( |=)timestamp
Run the DELETE query for the 'trends_uint' table.


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

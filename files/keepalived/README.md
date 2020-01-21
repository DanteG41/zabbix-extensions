Monitoring keepalived process using Zabbix 3.X
##############################################
Monitoring doesn't require any additional application, just one sudo command to zabbix.

### Zabbix will alert when:
- No keepalived process on host
- Keepalived on host has state FAIL
- Split-brain: two host have keepalived status MASTER (or have virtual IP from keepalived list)

### Userparameters and script check:
- State of keepalived host (MASTER, BACKUP, FAULT)
- Number of IP addresses asigned to host

### Installation notes:
On all keepalived hosts:
- Put `keepalived.conf` to zabbix userparameters directory (usually `/etc/zabbix/zabbix.agent.d/`)
- Put script `keepalived_addr_num.sh` to `/etc/zabbix/scripts/` or where you want (but you will ned to update userparameter file)
- Ensure that zabbix user has read access to keepalived configuration (usually `/etc/keepalived/keepalived.conf`)
- Give zabbix user privileges to sudo comand: 
```
#allow zabbix option to generate /tmp/keepalived.data
zabbix ALL=NOPASSWD:/usr/bin/pkill -USR1 keepalived
```
On zabbix server: 
- Import template "Template App Keepalived"
- After configuring keepalived host (host1, host2) to Keepalived App Template you should create one additional Trigger, asigned to host (not possible to create it using Template). Description explain its purpose:
```
Name: Two Keepalived MASTERS, seen from {HOSTNAME}
Expression: ({ohst1:keepalived.host_status.str(MASTER)}=1 and {host2:keepalived.host_status.str(MASTER)}=1) or ({host1:keepalived.addr_num.last(0)}>1 and {host2:keepalived.addr_num.last(0)}>1)
Description: Alert when keepalived state is MASTER on two loadbalancers - split brain situation. Two ways of detection: two host with status MASTER or two hosts have some virtual IP.
Severity: High
```

### Tested on:
- Debian 9.X, with Zabbix 3.0 and keepalived 1.3

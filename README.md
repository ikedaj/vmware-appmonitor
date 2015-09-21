# README
These OCF RA works with vSphere Guest SDK + Pacemaker.

Note: Tested with Guest SDK 9.0 for vSphere 5.1

- vSphere Guest SDK
 - https://www.vmware.com/support/developer/guest-sdk/
- Pacemaker
 - http://clusterlabs.org/

# TODO
- test case
- add sfex configuration to 2node

# How to setup
- Must run as root.

## vSphere Guest SDK
Download SDK
- https://my.vmware.com/group/vmware/get-download?downloadGroup=VSP510-GUESTSDK-510

Deploy SDK
```
# tar zxf VMware-GuestSDK-9.0.0-782409.tar.gz
# cp -pr GuestSDK /opt
```

## OCF RA
Deploy RA
```
# chmod +x appmonitor
# mkdir /usr/lib/ocf/resource.d/vmware
# cp -p appmonitor /usr/lib/ocf/resource.d/vmware
```

## Sample crm configuration
- 2 nodes configuration(sfex is required)
 - https://github.com/ikedaj/vmware-appmonitor/blob/master/2node-sample.crm
- 1 node configuration
 - https://github.com/ikedaj/vmware-appmonitor/blob/master/1node-sample.crm

## kdump setup
```
# cp -p /opt/GuestSDK/bin/bin64/vmware-appmonitor /bin
# cp -p /opt/GuestSDK/lib/lib64/libappmonitorlib.so /lib64

# vim /bin/kdump-pre.sh
-------------------------------------------------------------------------------
#!/bin/hush

/bin/vmware-appmonitor disable
exit 0
-------------------------------------------------------------------------------

# chmod +x /bin/kdump-pre.sh

# vim /etc/kdump.conf (Add the following 2 lines)
-------------------------------------------------------------------------------
kdump_pre /bin/kdump-pre.sh
extra_bins /bin/vmware-appmonitor /lib64/libappmonitorlib.so /bin/kdump-pre.sh
-------------------------------------------------------------------------------

# service kdump restart
# zcat /boot/initrd-`uname -r`kdump.img | cpio -tv | egrep "appmonitor|kdump-pre"
```

## Maintenance mode
appmonitor RA run "vSphereHA heartbeat" during its monitor action.
When the status of Pacemaker changes to maintenance-mode="true", appmonitor RA' monitor will be stopped without explicit stop(= disable vSphereHA heartbeat) aciton.
It means vSphereHA judge that the target VM is in something wrong status, so VM will be rebooted by vSphereHA.
To avoid this behavior, you should care about the status of "vSphereHA heartbeat" before/after maintenance-mode operation.

- maintenace-mode true
```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/GuestSDK/lib/lib64
export APPMON_BIN=/opt/GuestSDK/bin/bin64/vmware-appmonitor

cibadmin --modify --xml-text '<op id="prmAppmon-monitor-10s" enabled="false"/>'
${APPMON_BIN} disable
crm configure property maintenance-mode=true
```

- maintenace-mode false
```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/GuestSDK/lib/lib64
export APPMON_BIN=/opt/GuestSDK/bin/bin64/vmware-appmonitor

crm configure property maintenance-mode=false
${APPMON_BIN} enable
cibadmin --modify --xml-text '<op id="prmAppmon-monitor-10s" enabled="true"/>'
```

- Sample script
 - https://github.com/ikedaj/vmware-appmonitor/blob/master/maintenance-mode.sh
 
Per architecture Installation files :
-------------------------------------

-> install-server32.cmd (Hard link = install-win2k3.cmd)

-> install-server64.cmd (Hard link = install-win2k8.cmd/install-win2k12.cmd/install-win2k16.cmd)

-> install-workstation64.cmd (Hard link = install-win7.cmd/install-win10.cmd)

-> install-master.cmd


Sub-Modules :
-------------

install-jdk.cmd       -> Install/upgrade JDK for Jenkins
install-git.cmd       -> Install/Upgrade Windows Git for Jenkins
install-svn.cmd       -> Install/upgrade SVN client for Jenkins
ntp.cmd               -> NTP setup and update
clone-tooling.cmd     -> Git clone/update of tooling repository

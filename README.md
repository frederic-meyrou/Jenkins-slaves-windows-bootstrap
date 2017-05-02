# Jenkins-slaves-windows-bootstrap
<br>
<b>Script for fast deployment of Windows Jenkins Slaves</b><br>
<br>
Tested with Windows 2003 / 2008 / 2012 / Seven <br>
<br>
Step 1 : Create Slave on Master from a Template (Manual opération)<br>
Step 2 : Bootstrap from a batch file located on the Master shared folder \\[MASTER]\SLAVE-BOOTSTRAP\install.cmd<br>
              The script take care of all system configuration operations and verifications<br>
              Clone a Git repository with the complete slave tooling<br>
              Change the rights<br>
              And finally install the Jenkins client as a Service (JNLP)<br>
Step 3 : Check/correct Slave configuration on console and Enjoy<br>
<br>
Folders on Share :<br>
------------------<br>
\SLAVE = slave.jar and config files <br>
\INSTALL = binaries to install <br>
\BIN = scripts <br>
\CONFIG = Configuration files for the tools

<br>
The Configuration variables in main <b>setup.cmd</b> script can be tweaked :<br>
---------------------------------------------------------------------
<br>
SET MASTER=DNS Alias name of Master Jenkins server<br>
SET MASTER_HOST=FQDN host name of Jenkins master server<br>
SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\<br>  
SET GIT_REPO=URL to local Git repository for Slave tooling<br>
SET SLAVE_NAME=%COMPUTERNAME%<br>
SET SLAVE_FOLDER=CI (folder name for Slave)<br>
SET SLAVE_HOME=D:\DEV\%SLAVE_FOLDER% (Root folder full PATH for Slave)<br>
SET SLAVE_USER= (Define Slave running user)<br>
SET SLAVE_USER_PASS= <br>
SET LOCAL_TOOLS=D:\sApps (Root PATH for local tooling)<br> 
SET NTP_SERVER=ntp.agfa.be (Define NTP server for time sync)<br>
SET ERRORLOG=D:\DEV\slave_setup.log (Log installation file for errors)<br>
SET SERVICE_NAME="jenkins_slave" (Name of windows service for Jenkins slave)<br>

<br>
<br>

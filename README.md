# Jenkins-slaves-windows-bootstrap
Script for fast installation of Windows Jenkins Slaves

Tested with Windows 2003 / 2008 / 2012 / Seven

Step 1 : Create Slave on Master from a Template (Manual opération)
Step 2 : Bootstrap from a batch file located on the Master shared folder \\[MASTER]\SLAVE-BOOTSTRAP\install.cmd
              The script take care of all system configuration operations and verifications
              Clone a Git repository with the complete slave tooling
              Change the rights
              And finally install the Jenkins client as a Service (JNLP)
Step 3 : Check/correct Slave configuration on console and Enjoy

The Configuration variables in main setup.cmd script can be tweaked :
---------------------------------------------------------------------

SET MASTER=DNS Alias name of Master Jenkins server
SET MASTER_HOST=FQDN host name of Jenkins master server
SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\  
SET GIT_REPO=URL to local Git repository for Slave tooling
SET SLAVE_NAME=%COMPUTERNAME%
SET SLAVE_FOLDER=CI (folder name for Slave)
SET SLAVE_HOME=D:\DEV\%SLAVE_FOLDER% (Root folder full PATH for Slave)
SET LOCAL_TOOLS=D:\sApps (Root PATH for local tooling) 
SET ERRORLOG=D:\DEV\slave_setup.log (Log installation file for errors)
SET SERVICE_NAME="jenkins_slave" (Name of windows service for Jenkins slave)


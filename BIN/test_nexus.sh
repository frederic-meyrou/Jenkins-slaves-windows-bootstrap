#!/bin/bash

# -- WGET test script : Frederic Meyrou (ICS\ALM) Feb 2016

export RETRY=1 # -- 0=infinite / 20=default
export TIMEOUT=5 # -- TIMEOUT in Sec / 900=default
export NEXUSSERVER=orbis-maven.agfahealthcare.com
export LOGFILE=$0.log
export TEMP_LOGFILE=$0.tmp.log

export MAXCOUNTER=1000
export URLS="http://${NEXUSSERVER}/agfa-central/commons-lang/commons-lang/2.6/commons-lang-2.6.jar
http://${NEXUSSERVER}/agfa-central/commons-io/commons-io/2.2/commons-io-2.2.jar
http://${NEXUSSERVER}/agfa-central/commons-httpclient/commons-httpclient/3.1/commons-httpclient-3.1.jar
http://${NEXUSSERVER}/agfa-central/com/agfa/orbis/platform/owp/owp-native-full/84.2500.15/owp-native-full-84.2500.15-dlls.zip
http://${NEXUSSERVER}/agfa-central/com/agfa/orbis/platform/cpl/cpl-core/1.25.117-rc30/cpl-core-1.25.117-rc30-cpl-core.zip
http://${NEXUSSERVER}/agfa-central/com/agfa/orbis/documentation/user/be/orbis-manual-be/84.250.3/orbis-manual-be-84.250.3-doc.zip
http://${NEXUSSERVER}/agfa-central/com/agfa/orbis/platform/cpl/cpl-kernel-addon/1.5.10-rc01/cpl-kernel-addon-1.5.10-rc01-cpl.zip
http://orbis-maven.agfahealthcare.com/agfa-snapshots/com/agfa/orbis/modules/imedical/icu-aims-app/84.2600.24-SNAPSHOT/icu-aims-app-84.2600.24-20160222.143354-3-bos.jar
http://orbis-maven.agfahealthcare.com/agfa-snapshots/com/agfa/orbis/modules/imedical/icu-aims-app/84.2600.24-SNAPSHOT/icu-aims-app-84.2600.24-20160222.143354-3.jar
http://orbis-maven.agfahealthcare.com/agfa-snapshots/com/agfa/orbis/modules/coding/coding-lu-dao/84.260.1-rc20-SNAPSHOT/coding-lu-dao-84.260.1-rc20-20160222.014210-45.jar
http://orbis-maven.agfahealthcare.com/agfa-snapshots/com/agfa/orbis/platform/dbrep/orbis-rep/08.04.26.10-beta01-SNAPSHOT/orbis-rep-08.04.26.10-beta01-20160227.233852-31.rep"



# -- Create temp folder
mkdir temp
cd temp
pwd

# -- create LOG FILE and display start time
date "+%x-%T" | tee $LOGFILE

# -- Loop n Times
COUNTER=1
NBURL=0
ERROR=0
TOTAL=0
while [  $COUNTER -le $MAXCOUNTER ]; do
  echo "... Test #$COUNTER" | tee -a $LOGFILE
  # -- Loop on URLs
  for URL in $URLS
	do
	echo "--- Test URL : $URL" | tee -a $LOGFILE
	
    # -- Test with wget	on single URL. Test return code.
	wget --tries=$RETRY --timeout=$TIMEOUT --server-response --no-cache --no-http-keep-alive --output-document=downloadedfile $URL > $TEMP_LOGFILE 2>&1
	if [ "$?" != "0" ]; then
       	  echo "KO" | tee -a $LOGFILE		
	  let ERROR=ERROR+1
	  cat $TEMP_LOGFILE >> $LOGFILE
  	else
	  echo "Ok" | tee -a $LOGFILE
	fi
	
	# -- Delete file downloaded from wget
	rm -f downloadedfile
	let NBURL=NBURL+1

	# -- pause for 1 sec
	sleep 1
	
  done
  let COUNTER=COUNTER+1 
done

# -- display count of errors and tests
let TOTAL=COUNTER*COUNTER
# -- START
date "+%x-%T" | tee -a $LOGFILE
echo ">>> Result : $ERROR Errors of $TOTAL total tests for $NBURL URLs tested. (should be 11)" | tee -a $LOGFILE
echo ">>> Check LOG file here : $LOGFILE" | tee -a $LOGFILE







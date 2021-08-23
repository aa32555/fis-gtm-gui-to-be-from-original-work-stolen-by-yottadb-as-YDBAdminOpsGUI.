%YDBWEBXUSCNT ;Job counting for YottaDB; 05-07-2021 
	;#################################################################
	;#                                                               #
	;# Copyright (c) 2021 YottaDB LLC and/or its subsidiaries.       #
	;# All rights reserved.                                          #
	;#                                                               #
	;#   This source code contains the intellectual property         #
	;#   of its copyright holder(s), and is made available           #
	;#   under a license.  If you do not know the terms of           #
	;#   the license, please stop and do not read further.           #
	;#                                                               #
	;#################################################################		
count(inc,job) ;keep count of jobs
	; decommision *10002*
	new xucnt,x
	set job=$get(job,$job)
	;return current count
	if inc=0 do touch quit +$get(^YDBWEB("YDBWEBZSY","XUSYS","CNT"))
	;increment count
	if inc>0 do  quit
	. set x=$get(^YDBWEB("YDBWEBZSY","XUSYS",job,"NM")) kill ^YDBWEB("ydbwebzsy","xusys",job) set ^YDBWEB("YDBWEBZSY","XUSYS",job,"NM")=x
	. do touch
	. lock +^YDBWEB("YDBWEBZSY","XUSYS","CNT"):5
	. set xucnt=$get(^YDBWEB("YDBWEBZSY","XUSYS","CNT"))+1,^YDBWEB("YDBWEBZSY","XUSYS","CNT")=xucnt
	. lock -^YDBWEB("YDBWEBZSY","XUSYS","CNT")
	. quit
	;decrement count
	if inc<0 do  quit
	. lock +^YDBWEB("YDBWEBZSY","XUSYS","CNT"):5
	. set xucnt=$get(^YDBWEB("YDBWEBZSY","XUSYS","CNT"))-1,^YDBWEB("YDBWEBZSY","XUSYS","CNT")=$select(xucnt>0:xucnt,1:0)
	. lock -^YDBWEB("YDBWEBZSY","XUSYS","CNT")
	. kill ^YDBWEB("YDBWEBZSY","XUSYS",job)
	quit
	;
check(job) ;check if job number active
	; 0 = job doesn't seem to be running
	; 1 = job maybe running
	; 2 = job still has lock out. ;
	quit:$get(job)'>0 0
	if '$data(^YDBWEB("YDBWEBZSY","XUSYS",job)) quit 0
	new lk,%t
	set %t=0,lk=$$getlock()
	if $length(lk) lock +@lk:0 set %t=$test lock:%t -@lk
	quit $select(%t:2,1:1)
	;
setlock(nlk) ;set the lock we will keep
	if $length($get(nlk)) set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"LOCK")=nlk
	else  kill ^YDBWEB("YDBWEBZSY","XUSYS",$job,"LOCK")
	do touch ;update the time
	quit
	;
touch ;update the time
	set ^ydbweb("ydbwebzsy","xusys",$job,0)=$horolog
	quit
	;
getlock() ;get the node to lock
	quit $get(^YDBWEB("YDBWEBZSY","XUSYS",$JOB,"LOCK"))
	;
clear(db) ;check for locks and time clear old ones. ;
	new %j,%t,cnt,ct,lk,im,image,h kill ^tmp($job)
	do touch ;see that we are current
	;s %j=0 f  s %j=$zpid(%j) q:%j'>0  s ^tmp($j,%j)="",^tmp($j,%j,1)=$zgetjpi(%j,"imagname")
	set db=+$get(db),image="mumps" ;$zgetjpi($j,"imagname") ; ours
	set %j=0,cnt=0,h=$horolog,ct=$$h3($horolog)
	if db write !,"current job count: ",$$count(0)
	for  set %j=$order(^YDBWEB("YDBWEBZSY","XUSYS",%j)) quit:%j'>0  do
	. set cnt=cnt+1
	. if db write !,cnt," job: ",%j
	. set lk=$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"LOCK")) ;get lock name
	. if '$length(lk) write:db " no lock node"
	. if $length(lk) lock +@lk:0 set %t=$test do  quit:'%t  lock -@lk ;quit if lock still held
	. . if '%t,db write " lock held"
	. . if %t,db write " lock fail"
	. set im=$get(^tmp($job,%j,1))
	. if im=image write:db " image match: ",im  quit
	. if im["zfoo.exe" write:db " zfoo image" quit  ;quit if in same image
	. set h=$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,0)) if h>0 set h=$$h3(h)
	. if h+60>ct do  quit  ;updated in last 30 seconds. ;
	. . if db write " current timestamp"
	. set nm=$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"NM"))
	. if nm["task " set tm=+$piece(nm,"task ",2) if tm>0 do  quit:%
	. . set tm(1)=$get(^%ztsk(tm,.1)),%=(tm(1)=5)
	. . if db,% write " running task"
	. . quit
	. ;more checks
	. do count(-1,%j) if db write " not active: removed" ;not active
	. quit
	lock +^YDBWEB("YDBWEBZSY","XUSYS","CNT"):3
	set cnt=0,%j=0 for  set %j=$order(^YDBWEB("YDBWEBZSY","XUSYS",%j)) quit:%j'>0  set cnt=cnt+1
	set ^YDBWEB("YDBWEBZSY","XUSYS","CNT")=cnt
	lock -^YDBWEB("YDBWEBZSY","XUSYS","CNT")
	if db write !,"new job count: ",cnt
	quit
	;
h3(%h) ;just seconds
	quit %h*86400+$piece(%h,",",2)
	;
	;called from the x-ref both the volume and max signon from file 8989.3
xref(x1,v) ;v="s" or "k"
	new %,n
	set %=$get(^xtv(8989.3,1,4,x1,0)),n=$piece(%,"^") quit:%=""
	if v="k" kill ^xtv(8989.3,"amax",n) quit
	set ^xtv(8989.3,"amax",n)=$piece(%,"^",3)
	quit
	;
	;
YDBWEBZSY ; YottaDB system status display; 05-07-2021 
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
	;
en ; [public] main entry point
	;from the top just show by pid
	new done,args,i,currentjob
	set done=0
	for i=1:1:$length($zcmdline," ") do
	. set args(i)=$piece($zcmdline," ",i)
	if $length($get(args(1)))&($get(args(1))=+$get(args(1))) set currentjob=args(1)
	new mode
	lock +^YDBWEB("YDBWEBZSY","XUSYS","COMMAND"):1 if '$test goto lw
	set mode=0 do work(mode)
	quit
	;
query ; [public] alternate entry point
	new mode,x
	lock +^YDBWEB("YDBWEBZSY","XUSYS","COMMAND"):1 if '$test goto lw
	set x=$$ask write ! if x=-1 lock -^YDBWEB("YDBWEBZSY","XUSYS","COMMAND") quit
	set mode=+x do work(mode)
	quit
	;
tmmgr ; [public] show only taskman manager tasks
	new mode
	lock +^YDBWEB("YDBWEBZSY","XUSYS","COMMAND"):1 if '$test goto lw
	new filter set filter("%ZTM")="",filter("%ZTM0")=""
	set mode=0 do work(mode,.filter)
	quit
	;
tmsub ; [public] show only taskman submanager tasks
	new mode
	lock +^YDBWEB("YDBWEBZSY","XUSYS","COMMAND"):1 if '$test goto lw
	new filter set filter("%ZTMS1")=""
	set mode=0 do work(mode,.filter)
	quit
	;
ask() ;ask sort item
	; zexcept: %utanswer
	if $data(%utanswer) quit %utanswer
	new res,x,group
	set res=0,group=2
	write !,"1 pid",!,"2 cpu time"
	for  read !,"1// ",x:600 set:x="" x=1 quit:x["^"  quit:(x>0)&(x<3)  write " not valid"
	quit:x["^" -1
	set x=x-1,res=(x#group)_"~"_(x\group)
	quit res
	;
	;
jobexam(%zpos) ; [public; called by ^%YDBWEBZU]
	; preserve old state for process
	new oldio set oldio=$io set u=""
	new %reference set %reference=$reference
	kill ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE")
	;
	; halt the job if requested - no need to do other work
	if $get(^YDBWEB("YDBWEBZSY","XUSYS",$job,"CMD"))="HALT" goto halt^%YDBWEBZU
	;
	;
	; save these
	set ^YDBWEB("YDBWEBZSY","XUSYS",$job,0)=$horolog
	set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","INTERRUPT")=$get(%zpos)
	set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","ZMODE")=$zmode ; smh - interactive or other
	if %zpos'["GTM$DMOD" set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","CODELINE")=$text(@%zpos)
	if $get(duz) set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","UNAME")=$piece($get(^va(200,duz,0)),"^")
	else           set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","UNAME")=$get(^YDBWEB("YDBWEBZSY","XUSYS",$job,"NM"))
	;
	;
	; default system status. ;
	; s -> stack
	; d -> devices
	; g -> global stats
	; l -> locks
	if '$data(^YDBWEB("YDBWEBZSY","XUSYS",$job,"CMD")) zshow "SGDL":^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE") ; default case -- most of the time this is what happens. ;
	;
	; examine the job
	; zshow "*" is "bdgilrv"
	; b is break points
	; d is devices
	; g are global stats
	; i is isvs
	; l is locks
	; r is routines with hash (similar to s)
	; v is variables
	; zshow "*" does not include:
	; a -> autorelink information
	; c -> external programs that are loaded (presumable with d &)
	; s -> stack (use r instead)
	if $get(^YDBWEB("YDBWEBZSY","XUSYS",$job,"CMD"))="EXAM" zshow "*":^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE")
	;
	; just grab the default region only. decreases the stats as a side effect from this utility
	new glostat
	new i for i=0:0 set i=$order(^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","G",i)) quit:'i  if ^(i)[$zgld,^(i)["DEFAULT" set glostat=^(i)
	if glostat]"" new i for i=1:1:$length(glostat,",") do
	. new eachstat set eachstat=$piece(glostat,",",i)
	. new sub,obj set sub=$piece(eachstat,":"),obj=$piece(eachstat,":",2)
	. set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","GSTAT",sub)=obj
	;
	; capture io statistics for this process
	; zexcept: readonly,rewind
	if $zconvert($zversion,"l")["linux" do
	. new f set f="/proc/"_$job_"/io"
	. open f:(readonly:rewind):0 else  quit
	. use f
	. new done set done=0 ; $zeof doesn't seem to work (https://github.com/yottadb/yottadb/issues/120)
	. new x for  read x:0 use f do  quit:done
	. . if $zconvert(x,"l")["read_bytes"  set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","RBYTE")=$piece(x,": ",2)
	. . if $zconvert(x,"l")["write_bytes" set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","WBYTE")=$piece(x,": ",2) set done=1
	. use oldio close f
	;
	; capture string pool stats: full size - freed data
	; spstat 2nd piece is the actual size--but that fluctuates wildly
	; i use the full size allocated (defaults at 0.10 mb) - the size freed. ;
	new spstat set spstat=$view("spsize")
	;
	set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","SPOOL")=spstat
	set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","HEAP_MEM")=$piece(spstat,",",1)-$piece(spstat,",",3)
	;
	; done. we can tell others we are ready
	set ^YDBWEB("YDBWEBZSY","XUSYS",$job,"JE","COMPLETE")=1
	;
	;
	; restore old io and $r
	use oldio
	if %reference
	quit 1
	;
work(mode,filter) ; [private] main driver, will release lock
	; int mode
	; filter ref
	new users,group,procid
	new tname,i,sort,tab
	new $estack,$etrap
	new %ps,rtn,%os,done
	;
	;save $zinterrupt, set new one
	new oldint
	set oldint=$zinterrupt,$zinterrupt="i $$jobexam^%YDBWEBZU($zposition) s done=1"
	;
	;clear old data
	set ^YDBWEB("YDBWEBZSY","XUSYS","COMMAND")="STATUS"
	;
	set i=0 for  set i=$order(^YDBWEB("YDBWEBZSY","XUSYS",i)) quit:'i  kill ^YDBWEB("YDBWEBZSY","XUSYS",i,"CMD"),^("JE")
	;
	; counts; turn on ctrl-c. ;
	; zexcept: ctrap,noescape,nofilter
	new users set users=0
	use $principal:(ctrap=$char(3):noescape:nofilter)
	;
	;go get the data
	do unix(mode,.users,.sort)
	;
	;now show the results
	if users do
	. ;d header(.tab),
	. ; pid   pname   device       routine                                cpu time
	. do ushow(.tab,.sort,.filter)
	. ;w !!,"total ",users," user",$s(users>1:"s.",1:"."),!
	. quit
	;e  w !,"no current gt.m users.",!
	;
	;
exit ;
	lock -^YDBWEB("YDBWEBZSY","XUSYS","COMMAND") ;release lock and let others in
	if $length($get(oldint)) set $zinterrupt=oldint
	use $principal:ctrap=""
	quit
	;
err ;
	use $principal write !,$piece($zs,",",2,99),!
	do exit
	quit
	;
lw ;lock wait
	write !,"someone else is running the system status now."
	quit
	;
header(tab) ;display header
	; zexcept: ab
	write #
	set iom=+$$automarg
	;w !,"yottadb system status users on ",$$datetime($h)
	set tab(0)=0,tab(1)=6,tab(2)=14,tab(3)=18,tab(4)=27,tab(5)=46,tab(6)=66
	set tab(7)=75,tab(8)=85,tab(9)=100,tab(10)=110,tab(11)=115,tab(12)=123
	set tab(13)=130,tab(14)=141,tab(15)=150
	use 0:filter="ESCAPE"
	write !
	do eachheader("PID",tab(0))
	do eachheader("PName",tab(1))
	do eachheader("Device",tab(2))
	do eachheader("Routine",tab(4))
	do eachheader("CPU Time",tab(6))
	quit
eachheader(h,tab) ; [internal]
	; zexcept: ab
	new bold set bold=$char(27,91,49,109)
	new reset set reset=$char(27,91,109)
	write ?tab,bold,h,reset
	quit
ushow(tab,sort,filter) ;display job info, sorted by pid
	; zexcept: ab
	new si,i
	set si=""
	for  set si=$order(sort(si)) quit:si=""  for i=1:1:sort(si) do
	. new x,tname,procid,procname,ctime,ps,pid,place
	. set x=sort(si,i)
	. set pid=$piece(x,"~",8)
	. set place=$get(^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","INTERRUPT"))
	. ; debug
	. new rtnname set rtnname=$piece(place,"^",2)
	. if $data(filter)=10 quit:$$filtrout(.filter,rtnname,pid)
	. new dev do dev(.dev,pid)
	. set tname=$$devsel(.dev),procid=$piece(x,"~",1) ; tname is terminal name, i.e. the device. ;
	. set procname=$piece(x,"~",5),ctime=$piece(x,"~",6)
	. if $get(^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","ZMODE"))="OTHER" set tname="Background-"_tname
	. new uname set uname=$get(^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","UNAME"))
	. write procid,$char(9),procname,$char(9),tname,$char(9),place,$char(9),ctime,!
	. quit
	quit
	;
filtrout(filter,rtnname,pid) ; [private] should this item be filtered out?
	if rtnname="" quit 1  ; yes, filter out processes that didn't respond
	new found set found=0
	new i for i=1:1 quit:'$data(^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","S",i))  do  quit:found
	. if ^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","S",i)["call-in" quit
	. if ^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","S",i)["gtm$dmod" quit
	. new rtnname set rtnname=$piece(^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","S",i),"^",2)
	. if rtnname[" " set rtnname=$piece(rtnname," ")
	. new each set each=""
	. for  set each=$order(filter(each)) quit:each=""  do  quit:found
	. . if $data(filter(rtnname)) set found=1
	;
	; if we find it, we don't want to filter it out. ;
	quit 'found
	;
dev(dev,pid) ; [private] device processing
	new devcnt,x
	set devcnt=0
	new di for di=1:1 quit:'$data(^YDBWEB("YDBWEBZSY","XUSYS",pid,"JE","D",di))  set x=^(di) do
	. if x["CLOSED" quit  ; don't print closed devices
	. if pid=$job,$extract(x,1,2)="PS" quit  ; don't print our ps device
	. if $extract(x)'=" " set devcnt=devcnt+1,dev(devcnt)=x
	. else  set dev(devcnt)=dev(devcnt)_" "_$$trim(x)
	;
	; second pass, identify devices
	set devcnt="" for  set devcnt=$order(dev(devcnt)) quit:devcnt=""  do
	. set x=dev(devcnt)
	. new upx set upx=$zco(x,"u")
	. if $extract(x)=0 set dev("4JOB")="0"
	. if $piece(x," ")["/dev/" set dev("3TERM")=$piece(x," ")
	. if $piece(x," ")["/",$piece(x," ")'["/dev/" set dev("1FILE")=$piece(x," ")
	. if upx["SOCKET",upx["SERVER" set dev("2SOCK")=+$piece(upx,"PORT=",2)
	quit
	;
devsel(dev) ; [private] select device to print
	new devtyp set devtyp=$order(dev(" "))
	quit:devtyp="" ""
	if devtyp="4JOB" quit "0"
	if devtyp="2SOCK" quit "S"_dev(devtyp)
	if devtyp="3TERM" quit dev(devtyp)
	if devtyp="1FILE" quit dev(devtyp)
	quit "ERROR"
	;
trim(str) ; [private] trim spaces
	quit $$FUNC^%TRIM(str)
	;
datetime(horolog) ;
	quit $ZDATE(horolog,"dd-mon-yy 24:60:ss")
	;
unix(mode,users,sort) ;pug/toad,fis/ksb,ven/smh - kernel system status report for gt.m
	new %i,u,$etrap,$estack
	set $etrap="d uerr^%YDBWEBZSY"
	set %i=$io,u="^"
	new procs
	do intrptall(.procs)
	hang .205 ; 200ms for tcp read processes; 5ms b/c i am nice. ;
	new procgrps
	new done set done=0
	new j set j=1
	new i set i=0 for  set i=$order(procs(i)) quit:'i  do
	. set procgrps(j)=$get(procgrps(j))_procs(i)_" "
	. if $length(procgrps(j))>220 set j=j+1 ; max gt.m pipe len is 255
	for j=1:1 quit:'$data(procgrps(j))  do
	. new %line,%text,cmd
	. if $zconvert($zversion,"l")["linux" set cmd="ps o pid,tty,stat,time,cmd -p"_procgrps(j)
	. if $zconvert($zversion,"l")["darwin" set cmd="ps o pid,tty,stat,time,args -p"_procgrps(j)
	. if $zconvert($zversion,"l")["cygwin" set cmd="for p in "_procgrps(j)_"; do ps -p $p; done | awk '{print $1"" ""$5"" n/a ""$7"" ""$8"" n/a ""}'"
	. ; zexcept: command,readonly,shell
	. open "ps":(shell="/bin/sh":command=cmd:readonly)::"pipe" use "ps"
	. for  read %text quit:$zeo  do
	. . set %line=$$vpe(%text," ",u) ; parse each line of the ps output
	. . quit:$piece(%line,u)="PID"  ; header line
	. . do jobset(%line,mode,.users,.sort)
	. use %i close "ps"
	quit
	;
uerr ;linux error
	new ze set ze=$zs,$ecode="" use $principal
	zshow "*"
	quit  ;halt
	;
jobset(%line,mode,users,sort) ;get data from a linux job
	new %j
	new uname,ps,tname,ctime
	set (uname,ps,tname,ctime)=""
	new %j,pid,procid set (%j,pid,procid)=$piece(%line,u)
	set tname=$piece(%line,u,2) set:tname="?" tname="" ; tty, ? if none
	set ps=$piece(%line,u,3) ; process state
	set ctime=$piece(%line,u,4) ;cpu time
	new procname set procname=$piece(%line,u,5) ; process name
	if procname["/" set procname=$piece(procname,"/",$length(procname,"/")) ; get actual image name if path
	if $data(^YDBWEB("YDBWEBZSY","XUSYS",%j)) set uname=$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"NM"))
	else  set uname="UNKNOWN"
	new si set si=$select(mode=0:pid,mode=1:ctime,1:pid)
	new i set i=$get(sort(si))+1
	set sort(si)=i
	set sort(si,i)=procid_"~"_uname_"~"_ps_"~"_tname_"~"_procname_"~"_ctime_"~"_""_"~"_pid
	set users=users+1
	quit
	;
vpe(%oldstr,%olddel,%newdel) ; $piece extract based on variable length delimiter
	new %len,%piece,%newstr
	set %olddel=$get(%olddel) if %olddel="" set %olddel=" "
	set %len=$length(%olddel)
	; each %olddel-sized chunk of %oldstr that might be delimiter
	set %newdel=$get(%newdel) if %newdel="" set %newdel="^"
	; each piece of the old string
	set %newstr="" ; new reformatted string to retun
	for  quit:%oldstr=""  do
	. set %piece=$piece(%oldstr,%olddel)
	. set $piece(%oldstr,%olddel)=""
	. set %newstr=%newstr_$select(%newstr="":"",1:%newdel)_%piece
	. for  quit:%olddel'=$extract(%oldstr,1,%len)  set $extract(%oldstr,1,%len)=""
	quit %newstr
	;
	; sam's entry points
unixlsof(procs) ; [public] - get all processes
	; (return) .procs(n)=unix process number
	; zexcept: shell,parse
	new %cmd set %cmd="lsof -t $ydb_dist/yottadb && lsof -t $ydb_dist/mumps" ;_$view("gvfile","default")
	;s %cmd="ps ax | grep -i yottadb | awk '{print $1}'"
	if $zconvert($zversion,"l")["cygwin" set %cmd="ps -a | grep yottadb | grep -v grep | awk '{print $1}'"
	new oldio set oldio=$io
	open "lsof":(shell="/bin/bash":command=%cmd:parse)::"pipe"
	use "lsof"
	new i,k,tprocs for k=1:1 quit:$zeof  read tprocs(k):1
	set k="" for  set k=$order(tprocs(k)) quit:k=""  do
	. if tprocs(k)="" quit 
	. if tprocs(k)=$job quit
	. if $get(currentjob),tprocs(k)=currentjob quit
	. set procs($increment(i))=tprocs(k)
	use oldio close "lsof"
	new cnt set cnt=0
	new i for i=0:0 set i=$order(procs(i)) quit:'i  if $increment(cnt)
	quit:$quit cnt quit
	;
intrpt(%j) ; [public] send mupip interrupt (currently sigusr1)
	new sigusr1,a
	if $zconvert($zversion,"l")["linux" set sigusr1=10
	if $zconvert($zversion,"l")["darwin" set sigusr1=30
	if $zconvert($zversion,"l")["cygwin" set sigusr1=30
	;n % s %=$zsigproc(%j,"sigusr1")
	do RunShellCommand^%YDBUTILS("$ydb_dist/mupip INTRPT "_%j,.a)
	quit
	;
intrptall(procs) ; [public] send mupip interrupt to every single database process
	new sigusr1,a
	if $zconvert($zversion,"l")["linux" set sigusr1=10
	if $zconvert($zversion,"l")["darwin" set sigusr1=30
	if $zconvert($zversion,"l")["cygwin" set sigusr1=30
	; collect processes
	do unixlsof(.procs)
	; signal all processes
	new i,% set i=0 for  set i=$order(procs(i)) quit:'i  do RunShellCommand^%YDBUTILS("$ydb_dist/mupip INTRPT "_procs(i),.a) ;s %=$zsigproc(procs(i),"sigusr1")
	quit
	;
haltall ; [public] gracefully halt all jobs accessing current database
	; calls ^xusclean then halt^%YDBWEBZU
	;clear old data
	set ^YDBWEB("YDBWEBZSY","XUSYS","COMMAND")="STATUS"
	new i for i=0:0 set i=$order(^YDBWEB("YDBWEBZSY","XUSYS",i)) quit:'i  kill ^YDBWEB("YDBWEBZSY","XUSYS",i,"JE"),^("INTERUPT")
	;
	; get jobs accessing this database
	new procs do unixlsof(.procs)
	;
	; tell them to stop
	new i for i=1:1 quit:'$data(procs(i))  set ^YDBWEB("YDBWEBZSY","XUSYS",procs(i),"CMD")="HALT"
	kill ^YDBWEB("YDBWEBZSY","XUSYS",$job,"CMD")  ; but not us
	;
	; sayonara
	new j for j=0:0 set j=$order(^YDBWEB("YDBWEBZSY","XUSYS",j)) quit:'j  do intrpt(j)
	;
	; wait; long hang for tcp jobs that can't receive interrupts for .2 seconds
	hang .25
	;
	; check that they are all dead. if not, kill it "softly". ;
	; need to do this for node and java processes that won't respond normally. ;
	new j for j=0:0 set j=$order(^YDBWEB("YDBWEBZSY","XUSYS",j)) quit:'j  if $zgetjpi(j,"isprocalive"),j'=$job do kill(j)
	;
	quit
	;
haltone(%j) ; [public] halt a single process
	set ^YDBWEB("YDBWEBZSY","XUSYS",%j,"CMD")="halt"
	do intrpt(%j)
	hang .25 ; long hang for tcp jobs that can't receive interrupts
	if $zgetjpi(%j,"isprocalive") do kill(%j)
	quit
	;
kill(%j) ; [private] kill %j
	; zexcept: shell
	new %cmd set %cmd="kill "_%j
	open "kill":(shell="/bin/sh":command=%cmd)::"pipe" use "kill" close "kill"
	quit
	;
zjob(pid) goto jobviewz ; [public, interactive] examine a specific job -- written by osehra/smh
examjob(pid) goto jobviewz ;
viewjob(pid) goto jobviewz ;
jobview(pid) goto jobviewz ;
jobviewz ;
	; zexcept: ctrap,noescape,nofilter,pid
	use $principal:(ctrap=$char(3):noescape:nofilter)
	if $get(pid) do jobviewz2(pid) quit
	do ^%YDBWEBZSY
	new x,done
	set done=0
	; nasty read loop. i hate read loops
	for  do  quit:done
	. read !,"enter a job number to examine (^ to quit): ",x:$get(dtime,300)
	. else  set done=1 quit
	. if x="^" set done=1 quit
	. if x="" do ^%YDBWEBZSY quit
	. if x["?" do ^%YDBWEBZSY quit
	. ;
	. do jobviewz2(x)
	. do ^%YDBWEBZSY
	quit
	;
PROCESSDETAILS
processdetails
	new i,args,currentjob
	for i=1:1:$length($zcmdline," ") set args(i)=$piece($zcmdline," ",i)
	new x,cmd
	set x=args(1)
	set cmd=$get(args(2))
	do jobviewz2(x,cmd)
	quit
	;	
	;
jobviewz2(x,cmd) ; [private] view job information
	;	
	;	
	;	
	;	
	if x'?1.n write !,"not a valid job number." quit
	if '$zgetjpi(x,"isprocalive") write !,"this process does not exist" quit
	;
	;	
	new examread
	new doneone set doneone=0
	do ; this is an inner read loop to refresh a process. ;
	. new % set %=$$examinejobbypid(x)
	. if %'=0 write !,"the job didn't respond to examination for 305 ms. you may try again." set doneone=1 quit
	. do printexamdata(x,cmd)
	. ;w "enter to refersh, v for variables, i for isvs, k to kill",!
	. ;w "l to load variables into your st and quit, ^ to go back: ",!
	. ;w "d to debug (broken), z to zshow all data for debugging."
	. ;r examread:$g(dtime,300)
	. set doneone=1
	. ;i examread="^" s doneone=1
	. ;i $tr(examread,"k","k")="k" d haltone(x) s doneone=1
	quit
	;
examinejobbypid(%j) ; [$$, public, silent] examine job by pid; non-zero output failure
	quit:'$zgetjpi(%j,"isprocalive") -1
	kill ^YDBWEB("YDBWEBZSY","XUSYS",%j,"CMD"),^("JE")
	set ^YDBWEB("YDBWEBZSY","XUSYS",%j,"CMD")="EXAM"
	do intrpt(%j)
	new i for i=1:1:5 hang .001 quit:$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE"))
	if '$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE")) hang .2
	if '$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE")) hang .2
	if '$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE")) quit -1
	quit 0
	;
printexamdata(%j,flag) ; [private] print the exam data
	new ydbwebzsy merge ydbwebzsy=^YDBWEB("YDBWEBZSY","XUSYS",%j)
	;
	new bold set bold="" ;$c(27,91,49,109)
	new reset set reset="" ;$c(27,91,109)
	new under set under="" ;$c(27,91,52,109)
	new dim set dim=$$automarg()
	;
	; list variables?
	if $translate(flag,"V","v")="v" do  quit
	. ;w bold,"variables: ",reset,!
	. new v for v=0:0 set v=$order(ydbwebzsy("JE","V",v)) quit:'v  write ydbwebzsy("JE","V",v),!
	;
	;
	; list isvs?
	if $translate(flag,"I","i")="i" do  quit
	. ;w bold,"isvs: ",reset,!
	. new i for i=0:0 set i=$order(ydbwebzsy("JE","I",i)) quit:'i  write ydbwebzsy("JE","I",i),!
	;
	; normal display: job info, stack, locks, devices
	;w under,"job information for "_%j," (",$zdate(ydbwebzsy(0),"yyyy-mon-dd 24:60:ss"),")",reset,!
	write bold,"at: ",reset,ydbwebzsy("JE","INTERRUPT"),": ",$get(ydbwebzsy("JE","CODELINE")),!!
	;
	new cnt set cnt=1
	write bold,"Stack: ",reset,!
	; stack is funny -- print just to $zinterrupt
	new s for s=$order(ydbwebzsy("JE","R"," "),-1):-1:1 quit:$zconvert(ydbwebzsy("JE","R",s),"l")["$zinterrupt"  do
	. new place set place=$piece(ydbwebzsy("JE","R",s),":")
	. if $extract(place)=" " quit  ; gtm adds an extra level sometimes for display -- messes me up
	. write cnt,". "
	. if place'["GTM$DMOD" write place,?40,$text(@place)
	. write !
	. set cnt=cnt+1
	write cnt,". ",ydbwebzsy("JE","INTERRUPT"),":",?40,$get(ydbwebzsy("JE","CODELINE")),!
	;
	write !
	write bold,"Locks: ",reset,!
	new l for l=0:0 set l=$order(ydbwebzsy("JE","L",l)) quit:'l  write ydbwebzsy("JE","L",l),!
	;
	write !
	write bold,"Devices: ",reset,!
	new d for d=0:0 set d=$order(ydbwebzsy("JE","D",d)) quit:'d  write ydbwebzsy("JE","D",d),!
	;
	write !
	write bold,"Breakpoints: ",reset,!
	new b for b=0:0 set b=$order(ydbwebzsy("JE","B",b)) quit:'b  write ydbwebzsy("JE","B",b),!
	;
	write !
	write bold,"Global stats for default region: ",reset,!
	write !!
	new g set g=""
	new slots set slots=+dim\15
	new slot set slot=0
	for  set g=$order(ydbwebzsy("JE","GSTAT",g)) quit:g=""  do
	. if g="gld" quit
	. new v set v=ydbwebzsy("JE","GSTAT",g)
	. if v>9999 set v=$justify(v/1024,"",0)_"k"
	. if v>9999,v["k" set v=$justify(v/1024,"",0)_"m"
	. write ?(slot*15),g,": ",v," "
	. set slot=slot+1
	. if slot+1>slots set slot=0 write !
	write !!
	;
	write bold,"string pool (size,currently used,freed): ",reset,ydbwebzsy("JE","SPOOL"),!!
	quit
	;
loadst ; [private] load the symbol table into the current process
	kill
	new v for v=0:0 set v=$order(^tmp("YDBWEBZSY",$job,v)) quit:'v  set @^(v)
	kill ^tmp("YDBWEBZSY",$job)
	quit
	;
debug(%j) ; [private] debugging logic
		quit
	quit:'$zgetjpi(%j,"isprocalive") -1
	kill ^YDBWEB("YDBWEBZSY","XUSYS",%j,"CMD"),^("JE")
	set ^YDBWEB("YDBWEBZSY","XUSYS",%j,"CMD")="DEBUG"
	do intrpt(%j)
	new i for i=1:1:5 hang .001 quit:$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE"))
	if '$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE")) hang .2
	if '$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE")) hang .1
	if '$get(^YDBWEB("YDBWEBZSY","XUSYS",%j,"JE","COMPLETE")) quit -1
	new ydbwebzsy merge ydbwebzsy=^YDBWEB("YDBWEBZSY","XUSYS",%j)
	;
	new bold set bold=$char(27,91,49,109)
	new reset set reset=$char(27,91,109)
	new under set under=$char(27,91,52,109)
	new dim set dim=$$automarg()
	;
	; normal display: job info, stack, locks, devices
	write #
	write under,"job information for "_%j," (",$zdate(ydbwebzsy(0),"yyyy-mon-dd 24:60:ss"),")",reset,!
	write bold,"at: ",reset,ydbwebzsy("JE","INTERRUPT"),": ",ydbwebzsy("JE","CODELINE"),!!
	;
	new cnt set cnt=1
	write bold,"Stack: ",reset,!
	; stack is funny -- print just to $zinterrupt
	new s for s=$order(ydbwebzsy("JE","R"," "),-1):-1:1 quit:ydbwebzsy("JE","R",s)["$ZINTERRUPT"  do
	. new place set place=$piece(ydbwebzsy("JE","R",s),":")
	. if $extract(place)=" " quit  ; gtm adds an extra level sometimes for display -- messes me up
	. write cnt,". "
	. if place'["GTM$DMOD" write place,?40,$text(@place)
	. write !
	. set cnt=cnt+1
	write cnt,". ",ydbwebzsy("JE","INTERRUPT"),":",?40,ydbwebzsy("JE","CODELINE"),!
	;
	write !
	write bold,"locks: ",reset,!
	new l for l=0:0 set l=$order(ydbwebzsy("JE","L",l)) quit:'l  write ydbwebzsy("JE","L",l),!
	;
	write !
	write bold,"devices: ",reset,!
	new d for d=0:0 set d=$order(ydbwebzsy("JE","D",d)) quit:'d  write ydbwebzsy("JE","D",d),!
	write !
	write bold,"breakpoints: ",reset,!
	new b for b=0:0 set b=$order(ydbwebzsy("JE","B",b)) quit:'b  write ydbwebzsy("JE","B",b),!
	;
	new x read "press key to continue",x
	quit
	;
automarg() ;returns iom^iosl if it can and resets terminal to those dimensions; gt.m
	; zexcept: apc,term,noecho,width
	if $principal'["/dev/" quit:$quit "" quit
	use $principal:(width=0)
	new %i,%t,esc,dim set %i=$io,%t=$test do
	. ; resize terminal to match actual dimensions
	. set esc=$char(27)
	. use $principal:(term="r":noecho)
	. write esc,"7",esc,"[r",esc,"[999;999h",esc,"[6n"
	. read dim:1 else  quit
	. write esc,"8"
	. if dim?.apc use $principal:(term="":echo) quit
	. if $length($get(dim)) set dim=+$piece(dim,";",2)_"^"_+$piece(dim,"[",2)
	. use $principal:(term="":echo:width=+$piece(dim,";",2):length=+$piece(dim,"[",2))
	; restore state
	use %i if %t
	; extra just for ^zjob - don't wrap
	use $principal:(width=0)
	quit:$quit $select($get(dim):dim,1:"") 
	quit
	;
	;
	;
%YDBWEBXUSCLEAN	; CLEANUP BEFORE EXIT; 05-07-2021 
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
	lock  ;unlock any locks
	set u="^"
	;unwind exit actions
	if $data(^YDBWEB("YDBWEBZSY","XQ",$JOB,"T")) set %xqea=^("t") do
	. for %xqea1=%xqea:-1:1 if $data(^YDBWEB("YDBWEBZSY","XQ",$JOB,%XQEA1)),$piece(^(%xqea1),u,16) set %xqea2=+^(%xqea1) if $data(^dic(19,%xqea2,15)),$length(^(15)) xecute ^(15)
	kill %xqea,%xqea1,%xqea2
	;jump if the home device was closed
	goto:$data(io("c")) h2
	;clear the screen
	if $select($data(iost)[0:1,iost="":1,iost["c-":1,1:0),'$data(xuerf) write !!!!!!!!!!!!!!!!!!!!!!!
	if $data(xqnolog) write !!,"==>  sorry, all activity on this volume set is being halted!  try again later.",*7,*7,*7,!!!!
	;w !!,"halting at " s x=$p($h,",",2),y=$e(x#3600\60+100,2,3),x=x\3600,z=0 s:x>11 z=1 s:'x x=12 s:x>12 x=x-12 w x,":",y," ",$s(z:"pm",1:"am")
	write !!,"logged out at "_$$hte^xlfdt($horolog,"1fmp")
	do:$data(duz("newcode")) newcode
	;non-r/s exit thru here also. ;
h2	;no talking after this point
	do c,xutl
	;un-comment the following line if you want fm space recall cleared
	;after each session. ;
	;k ^disv($g(duz,0))
	set:'($data(xqxflg)#2) xqxflg="" if $data(xqch),xqch="halt" set $piece(xqxflg,u,3)=""
	if ($data(xqnohalt)#2)!($data(ztqueued)#2)!($piece(xqxflg,u,3)="xup") kill xqnohalt,xqxflg quit  ;return to rest^xq12, ^xup or taskman. ;
	;this was for modem hang up code. obsolete now
	if $data(^%zis("h"))#2 xecute ^("h")
	;go to zu to do final halt. ;
	goto halt^zu
	;
touch	;sr. api to set the keepalive node, only set once a day
	quit:+$get(^YDBWEB("YDBWEBZSY","XQ",$JOB,"KEEPALIVE"))=+$horolog
	set ^YDBWEB("YDBWEBZSY","XQ",$JOB,"KEEPALIVE")=$horolog
	quit
	;
c	;do device close execute, user exit. ;
	new xudev
	set xudev=$select($data(^YDBWEB("YDBWEBZSY","XQ",$JOB,"IOS")):^("ios"),1:"")
	do ^%zisc,bye
	quit
	;
	;called from broker, vistalink, r/s
bye	;set flags to show user has left. called from anyplace the user exits
	new da,dik,r0,%
	if $get(^va(200,+$get(duz),1.1)) set $piece(^va(200,duz,1.1),"^",3)=0
	set da=+$get(^YDBWEB("YDBWEBZSY","XQ",$JOB,0)) do lout(da)
	if $data(^xusec(0,da,0)) do
	. set r0=^xusec(0,da,0)
	. if $get(io("ip"))]"",$piece(r0,"^",13)]"" set %=$$cmd^xwbcagnt(.r0,"xwb delete handle",$piece(r0,"^",13))
	kill ^YDBWEB("YDBWEBZSY","XQ",$JOB)
	quit
	;
lout(da)	;enter log-out time, in sign-on log
	new dik
	if $data(^xusec(0,da,0)) do
	. set r0=^(0),$piece(^(0),"^",4)=$$now^xlfdt,dik="^xusec(0,",dik(1)="3" do en1^dik
	quit
	;
xutl	;cleanup job temporary globals
	new xqn do clean^dilf ;cleanup fm too. ;
	kill ^YDBWEB("YDBWEBZSY",$JOB),^utility($job),^tmp($job)
	set xqn=" " for  set xqn=$order(^YDBWEB("YDBWEBZSY",xqn)) quit:xqn=""  kill:"^xqo^xgatr^xgkb^"'[xqn ^YDBWEB("YDBWEBZSY",xqn,$job)
	set xqn=" " for  set xqn=$order(^tmp(xqn)) quit:xqn=""  kill ^tmp(xqn,$job)
	set xqn=" " for  set xqn=$order(^utility(xqn)) quit:xqn=""  kill:"^rou^glo^lrltr"'[xqn ^utility(xqn,$job)
	kill ^YDBWEB("YDBWEBZSY","ZISPARAM",$io)
	quit
	;
newcode	;remind user they changed there vc. ;
	quit
	;
	;entry point to clear symbol table
kill	;sr. this is what was requested. ;
	kill %1,%2,%3 set %3=+$get(^YDBWEB("YDBWEBZSY","XQ",$JOB,"T"))
	;see if menu stack has variable to protect. ;
	for %1=%3:-1:1 set %2=+$get(^YDBWEB("YDBWEBZSY","XQ",$JOB,%1)),%2=$get(^dic(19,%2,"nokill")) if %2]"" new @%2
	;fall into next part of kill. ;
kill1	;to clean up all but kernel variables. ;
	if $$broker^xwblib set %2=$piece($text(varlst^xwblib),";;",2) if %2]"" new @%2 ;protect broker variables. ;
	new xgwin,xgdi,xgevent ;p434 remove kwapi
	new xqaexit,xqauser,xqx1,xqakill,xqaid
	;p434 add dilocktm, remove xrtl, %zh0
	kill (duz,dtime,dilocktm,dt,disys,io,iobs,iof,iom,ion,iosl,iost,iot,ios,ioxy,u,xqvol,xqy,xqy0,xqdic,xqpsm,xqpt,xqaudit,xqxflg,ztstop,ztqueued,ztreq)
	kill io("c"),io("q")
	quit
	;
xmr	;entry point from xus to do xmr and cleanup after. ;
	new xqxflg ;p434
	do next^xus1 set xqxflg="",xqxflg("halt")=1 goto h2
	;
	;
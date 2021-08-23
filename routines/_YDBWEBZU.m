%YDBWEBZU ;Job Exam Routine; 05-07-2021
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
en ;see that escape processing is off, conflict with screenman
	use $principal:(nocenable:noescape)
	new $estack,$etrap set $etrap="d err^%YDBWEBZU q:$quit -9 q"
	set $zinterrupt="i $$jobexam^%YDBWEBZU($zposition)"
	do count^%YDBWEBXUSCNT(1)
	;
	;
err ;come here on error
	; handle stack overflow errors specifically
	if $piece($zs,",",3)["stackcrit"!("stackoflow"[$piece($zs,",",3)) set $etrap="q:$st>"_($stack-8)_"  g err2^%YDBWEBZU" quit
	;
err2 ;
	set $etrap="d unwind^%YDBWEBZU" lock  ;backup trap
	use $principal:nocenable
	quit:$ecode["<prog>"
	;
	set $etrap="d halt^%YDBWEBZU"
	;
	if $zconvert($piece($zs,",",3),"l")'["-ctrlc" set xuerf="" goto ^%YDBWEBXUSCLEAN ;419
ctrlc use $principal
	write !,"--interrupt acknowledged",!
	do kill1^%YDBWEBXUSCLEAN ;clean up symbol table
	set $ecode=",<<pop>>,"
	quit
	;
unwind ;unwind the stack
	quit:$estack>1  goto ctrlc2:$ecode["<<pop>>"
	set $ecode=""
	quit
	;
ctrlc2 set $ecode="" goto:$get(^YDBWEB("YDBWEBZSY","XQ",$job,"T"))<2 ^%YDBWEBXUSCLEAN
	set ^YDBWEB("YDBWEBZSY","XQ",$job,"T")=1,xqy=$get(^(1)),xqy0=$piece(xqy,"^",2,99)
	goto:$piece(xqy0,"^",4)'="m" halt
	set xqpsm=$piece(xqy,"^",1),xqy=+xqpsm,xqpsm=$piece(xqpsm,xqy,2,3)
	goto:'xqy ^%YDBWEBXUSCLEAN
	set $ecode="",$etrap="d err^%YDBWEBZU q:$quit 0 q"
	use $principal:noescape
	goto m1^xq
	;
halt if $data(^YDBWEB("YDBWEBZSY","XQ",$job)) do:$get(duz)>0 bye^%YDBWEBXUSCLEAN
	do count^%YDBWEBXUSCNT(-1)
	halt
	;
jobexam(%zpos) ;
	quit $$jobexam^%YDBWEBZSY(%zpos)  ; foia improved by sam
	;
JOBEXAM(%zpos) ;
	quit $$jobexam^%YDBWEBZSY(%zpos)  ; foia improved by sam
	;
%YDBWEB; YottaDB Web Server; 05-07-2021
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
	quit
	;
	;
routes
	set ydbweb(":ws","routes","POST","ydbwebapi","api^%YDBWEBAPI")=""
	set ydbweb(":ws","routes","OPTIONS","ydbwebapi","api^%YDBWEBAPI")=""
	set ydbweb(":ws","routes","GET","YottaDB","servestatic^%YDBWEBAPI")=""
	;
	quit	
	;
Start(port) ;
	new i,args
	for i=1:1:$zlength($zcmdline," ") do
	. set args(i)=$zpiece($zcmdline," ",i)
	if $zlength($get(args(1)))&($get(args(1))=+$get(args(1))) set port=args(1)
	kill (port)
	if '$get(port) set port=8089
	set noglb=1
	if 1 job job(port) hang 1 if '$test write !,"YottaDB web server could not be started!" quit
	set job=$zjob
	if '$$DirectoryExists^%YDBUTILS("/tmp") do
	. write !,"creating /tmp ..."
	. write:$$CreateDirectoryTree^%YDBUTILS("/tmp") " succeeded" 
	zsy "echo ""pid:"_job_",port:"_port_""" > /tmp/ydbweb.info"
	write !,"YottaDB web server started successfully. port: ",port," - pid: ",job,!
	quit
Stop;
	kill
	write ! new src,line
	set src="/tmp/ydbweb.info"
	open src:(readonly)
	use src read line close src set line=$translate(line,$char(13))
	new port,pid
	set pid=$zpiece($zpiece(line,","),":",2)
	set port=$zpiece($zpiece(line,",",2),":",2)
	if 'pid write !!,"YottaDB web server could not be stopped!" quit
	zsy "kill "_pid
	write !,"killed pid: "_pid_". yottadb web server stopped successfully.",!
	;zsy "netstat -ano -p tcp | grep "_port
	quit
	;
check
	kill
	write ! new src,line
	set src="/tmp/ydbweb.info"
	open src:(readonly)
	use src read line close src set line=$translate(line,$char(13))
	new port
	set port=$zpiece($zpiece(line,",",2),":",2)
	zsy "netstat -ano -p tcp | grep "_port
	quit 
	;       
run(httpreq,httprsp,httpargs)
	set httprsp("mime")="text/html"
	write ! new src,line
	set src="/tmp/ydbweb.info"
	open src:(readonly)
	use src read line close src set line=$translate(line,$char(13))
	new port,pid
	set pid=$zpiece($zpiece(line,","),":",2)
	set port=$zpiece($zpiece(line,",",2),":",2)
	set @httprsp@(1)="YottaDB web server running on pid:"_pid_" and "_"port:"_port
	quit       
	;
job(tcpport)
	set @("$zinterrupt=""if $$JOBEXAM^%YDBWEBZU($zposition)""")
	set tcpio="SCK$"_tcpport
	open tcpio:(listen=tcpport_":TCP":delim=$char(13,10):attach="server":chset="M"):15:"socket" 
	else  use 0 write !,"error cannot open port "_tcpport quit
	use tcpio:(chset="m")
	write /listen(5)
	new parsock set parsock=$zpiece($key,"|",2) 
	new childsock
loop
	do  goto loop
	. for  write /wait quit:$key]""
	. if $zpiece($key,"|")="CONNECT" do 
	. . set childsock=$zpiece($key,"|",2)
	. . use tcpio:(detach=childsock)
	. . new q set q=""""
	. . new arg set arg=q_"SOCKET:"_childsock_q
	. . new j set j="child($g(tlsconfig),$g(nogbl)):(input="_arg_":output="_arg_")"
	. . job @j
	quit
child(tlsconfig,nogbl)
	new %wtcp set %wtcp=$get(tcpio,$principal)
	set httplog=0
	set httplog("dt")=+$horolog
	do incrlog
	;new $et set $et="g etsock^%YDBWEB"
	;
next
	kill httpreq,httprsp,httperr
wait
	use %wtcp:(delim=$char(13,10):chset="m")
	read tcpx:10 if '$test goto etdc
	if '$zlength(tcpx) goto etdc
	set httpreq("method")=$zpiece(tcpx," ")
	set httpreq("path")=$zpiece($zpiece(tcpx," ",2),"?")
	set httpreq("query")=$zpiece($zpiece(tcpx," ",2),"?",2,999)
	set httpreq("body")="%ydbwebbody" kill @httpreq("body")
	if $zextract($zpiece(tcpx," ",3),1,4)'="HTTP" goto next
	for  set tcpx=$$rdcrlf() quit:'$zlength(tcpx)  do addhead(tcpx)
	use %wtcp:(nodelim)
	if $get(httpreq("header","content-length"))>0 do
	. do rdlen(httpreq("header","content-length"),99)
	set $et="g etcode^%YDBWEB"
	set httperr=0
	do respond
	set $et="g etsock^%YDBWEB"
	use %wtcp:(nodelim:chset="m")
	if $get(httperr) do rsperror
	do sendata close %wtcp  halt
	if $zconvert($get(httprsp("header","connection")),"l")="close" close %wtcp
	goto next
rdcrlf()
	new x,line,retry
	set line=""
	for retry=1:1 read x:1 set line=line_x quit:$ascii($zb)=13  quit:retry>10
	quit line
rdchnks 
	quit
rdlen(remain,timeout)
	new x,line,length
	set line=0
rdloop
	set length=remain if length>1600 set length=1600
	read x#length:timeout
	if '$test set line=line+1,@httpreq("body")@(line)=x quit
	set remain=remain-$zlength(x),line=line+1,@httpreq("body")@(line)=x
	goto:remain rdloop
	quit
addhead(line)
	new name,value
	set name=$$low($$ltrim($zpiece(line,":")))
	set value=$$ltrim($zpiece(line,":",2,99))
	if line'[":" set name="",value=line
	if '$zlength(name) set name=$get(httpreq("header"))
	if '$zlength(name) quit
	if $data(httpreq("header",name)) do
	. set httpreq("header",name)=httpreq("header",name)_","_value
	else  do
	. set httpreq("header",name)=value,httpreq("header")=name
	quit
etsock
	do logerr
	close %wtcp
	halt
etcode
	set $et="g etbail^%YDBWEB"
	if $tlevel trollback
	do logerr,seterror(501,"log id:"_httplog("id")),rsperror,sendata
	set $et="q:$estack&$quit 0 q:$estack  s $ecode="""" g next"
	quit
etdc
	close $principal
	halt
etbail
	use %wtcp
	write "HTTP/1.1 500 internal server error-",$char(13,10),$char(13,10),!
	close %wtcp
	halt
incrlog
	new dt,id
	set dt=+$horolog
	set id=$horolog_"."_$job set httplog("id")=id
	quit
logerr
	quit
up(string) quit $zconvert(string,"u")
low(string) quit $zconvert(string,"l")
ltrim(%x)
	new %l,%r
	set %l=1,%r=$zlength(%x)
	for %l=1:1:$zlength(%x) quit:$ascii($zextract(%x,%l))>32
	quit $zextract(%x,%l,%r)
respond
	new routine,location,httpargs,httpbody,ads
	set routine=""
	do match(.routine,.httpargs) if $get(httperr) quit
	do qsplit(.httpargs) if $get(httperr) quit
	set httprsp="%ydbwebresp" kill @httprsp
	if routine="" set routine="run"
	do @(routine_"(.httpreq,.httprsp,.httpargs)")
	quit
qsplit(query)
	new i,x,name,value
	for i=1:1:$zlength(httpreq("query"),"&") do
	. set x=$$urldec($zpiece(httpreq("query"),"&",i))
	. set name=$zpiece(x,"="),value=$zpiece(x,"=",2,999)
	. if $zlength(name) set query($$low(name))=value
	quit
match(routine,args)
	new authnode
	set routine=""
	do matchf(.routine,.args,.authnode) quit
	if routine="" set routine="run"
	quit
matchf(routine,args,authnode)
	new path set path=httpreq("path")
	set:$zextract(path)="/" path=$zextract(path,2,$zlength(path))
	new done set done=0
	new path1 set path1=$$urldec($zpiece(path,"/",1,9999),1)
	new path1 set path1=$$urldec($zpiece(path,"/",1),1)
	new pattern set pattern=path1
	if pattern="" set pattern="/"
	if pattern=""  set pattern="YottaDB"
	if pattern="/" set pattern="YottaDB"
	if '$data(ydbweb(":ws","routes")) do routes
	if $data(ydbweb(":ws","routes",httpreq("method"),pattern)) do
	. set routine=$order(ydbweb(":ws","routes",httpreq("method"),pattern,""))
	quit
	;	
sendata
	new %wbuff set %wbuff=""
	new size,rsptype,preamble,start,limit
	set rsptype=$select($zextract($get(httprsp))="%":2,$zextract($get(httprsp))'="^":1,1:2)
	if rsptype=1 set size=$$varsize(.httprsp)
	if rsptype=2 set size=$$refsize(.httprsp)
	do w($$rspline()_$char(13,10))
	if $data(httprsp("header")) do
	. new tmp set tmp="" for  set tmp=$order(httprsp("header",tmp)) quit:tmp=""  do
	. . do w(tmp_": "_httprsp("header",tmp)_$char(13,10))
	. kill httprsp("header")
	if $data(httprsp("mime")) do
	. do w("Content-Type: "_httprsp("mime")_$char(13,10)) kill httprsp("mime")
	else  do w("Content-Type: application/json; charset=utf-8"_$char(13,10))
	do w("Content-Length: "_size_$char(13,10)_$char(13,10))
	if 'size do flush quit
	new i,j,ind
	if rsptype=1 do
	. if $data(httprsp)#2 do w(httprsp)
	. if $data(httprsp)>1 set i=0 for  set i=$order(httprsp(i)) quit:'i  do w(httprsp(i))
	if rsptype=2 do
	. if $data(@httprsp)#2 do w(@httprsp)
	. if $data(@httprsp)>1 set i=0 for  set i=$order(@httprsp@(i)) quit:'i  do
	. . set ind=@httprsp@(i)
	. . if $ze(ind,1,4)="$na(" do  quit
	. . . set tmp=$zpiece($zpiece(ind,"$na(",2),")",1,$zl(ind,")")-1) if '$data(@tmp) quit
	. . . do w(@tmp)
	. . do w(ind) quit
	do flush
	quit
w(data)
	if ($zlength(%wbuff)+$zlength(data))>4080 do flush
	set %wbuff=%wbuff_data
	quit
flush
	write %wbuff
	set %wbuff=""
	quit
rsperror
	;
	quit
rspline()
	if $data(httprsp("partial")) quit "HTTP/1.1 206 partial content"
	if '$get(httperr),'$data(httpreq("location")) quit "HTTP/1.1 200 ok"
	if '$get(httperr),$data(httpreq("location")) quit "HTTP/1.1 201 created"
	if $get(httperr)=400 quit "HTTP/1.1 400 bad request"
	if $get(httperr)=401 quit "hHTTPttp/1.1 401 unauthorized"
	if $get(httperr)=404 quit "HTTP/1.1 404 not found"
	if $get(httperr)=405 quit "HTTP/1.1 405 method not allowed"
	if $get(httperr)=302 quit "HTTP/1.1 302 moved temporarily"
	quit "HTTP/1.1 500 internal server error"
seterror(errcode,message)
	new nexterr,errname,topmsg
	set httperr=400,topmsg="bad request"
	if errcode=101 set errname="missing name of index"
	if errcode=102 set errname="invalid index name"
	if errcode=103 set errname="parameter error"
	if errcode=104 set httperr=404,topmsg="not found",errname="bad key"
	if errcode=105 set errname="template required"
	if errcode=106 set errname="bad filter parameter"
	if errcode=107 set errname="unsupported field name"
	if errcode=108 set errname="bad order parameter"
	if errcode=109 set errname="operation not supported with this index"
	if errcode=110 set errname="order field unknown"
	if errcode=111 set errname="unrecognized parameter"
	if errcode=112 set errname="filter required"
	if errcode=201 set errname="unknown collection"
	if errcode=202 set errname="unable to decode json"
	if errcode=203 do
	. set httperr=404,topmsg="not found",errname="unable to determine patient"
	if errcode=204 do
	. set httperr=404,topmsg="not found",errname="unable to determine collection"
	if errcode=205 set errname="patient mismatch with object"
	if errcode=207 set errname="missing uid"
	if errcode=209 set errname="missing range or index"
	if errcode=210 set errname="unknown uid format"
	if errcode=211 do
	. set httperr=404,topmsg="not found",errname="missing patient identifiers"
	if errcode=212 set errname="mismatch of patient identifiers"
	if errcode=213 set errname="delete demographics only not allowed"
	if errcode=214 set httperr=404,errname="patient id not found in database"
	if errcode=215 set errname="missing collection name"
	if errcode=216 set errname="incomplete deletion of collection"
	if errcode=400 set errname="bad request"
	if errcode=401 set errname="unauthorized"
	if errcode=404 set errname="not found"
	if errcode=405 set errname="method not allowed"
	if errcode=501 set errname="m execution error"
	if errcode=502 set errname="unable to lock record"
	if '$zlength($get(errname)) set errname="unknown error"
	if errcode>500 set httperr=500,topmsg="internal server error"
	if errcode<500,errcode>400 set httperr=errcode,topmsg=errname
	quit
urlenc(x)
	new i,y,z,last
	set y=$zpiece(x,"%") for i=2:1:$zlength(x,"%") set y=y_"%25"_$zpiece(x,"%",i)
	set x=y,y=$zpiece(x,"&") for i=2:1:$zlength(x,"&") set y=y_"%26"_$zpiece(x,"&",i)
	set x=y,y=$zpiece(x,"=") for i=2:1:$zlength(x,"=") set y=y_"%3d"_$zpiece(x,"=",i)
	set x=y,y=$zpiece(x,"+") for i=2:1:$zlength(x,"+") set y=y_"%2b"_$zpiece(x,"+",i)
	set x=y,y=$zpiece(x,"{") for i=2:1:$zlength(x,"{") set y=y_"%7b"_$zpiece(x,"{",i)
	set x=y,y=$zpiece(x,"}") for i=2:1:$zlength(x,"}") set y=y_"%7d"_$zpiece(x,"}",i)
	set y=$translate(y," ","+")
	set z="",last=1
	for i=1:1:$zlength(y) if $ascii(y,i)<32 do
	. set code=$$dec2hex($ascii(y,i)),code=$translate($justify(code,2)," ","0")
	. set z=z_$zextract(y,last,i-1)_"%"_code,last=i+1
	set z=z_$zextract(y,last,$zlength(y))
	quit z
urldec(x,path) ; decode a url-encoded string
	new i,out,frag,asc
	set:'$get(path) x=$translate(x,"+"," ") ; don't convert '+' in path fragment
	for i=1:1:$zlength(x,"%") do
	. if i=1 set out=$zpiece(x,"%") quit
	. set frag=$zpiece(x,"%",i),asc=$zextract(frag,1,2),frag=$zextract(frag,3,$zlength(frag))
	. if $zlength(asc) set out=out_$char($$hex2dec(asc))
	. set out=out_frag
	quit out
refsize(root)
	quit:'$data(root) 0 quit:'$zlength(root) 0
	new size,i
	set size=0
	if $data(@root)#2 set size=$zl(@root)
	if $data(@root)>1 set i=0 for  set i=$order(@root@(i)) quit:'i  do
	. if $ze(@root@(i),1,4)="$na(" do  quit
	. . set tmp=$zpiece($zpiece(@root@(i),"$na(",2),")",1,$zl(@root@(i),")")-1)
	. . set size=size+$zl(@tmp) quit
	. set size=size+$zl(@root@(i))
	quit size
varsize(v)
	quit:'$data(v) 0
	new size,i
	set size=0
	if $data(v)#2 set size=$zlength(v)
	if $data(v)>1 set i="" for  set i=$order(v(i)) quit:'i  set size=size+$zlength(v(i))
	quit size
	;
encode(vvroot,vvjson,vverr)
	if '$zlength($get(vvroot)) quit
	if '$zlength($get(vvjson)) quit
	new vvline,vvmax,vverrors
	set vvline=1,vvmax=4080,vverrors=0
	set @vvjson@(vvline)=""
	do serobj(vvroot)
	quit
serobj(vvroot)
	new vvfirst,vvsub,vvnxt
	set @vvjson@(vvline)=@vvjson@(vvline)_"{"
	set vvfirst=1
	set vvsub="" for  set vvsub=$order(@vvroot@(vvsub)) quit:vvsub=""  do
	. set:'vvfirst @vvjson@(vvline)=@vvjson@(vvline)_"," set vvfirst=0
	. do sername(vvsub)
	. if $$isvalue(vvroot,vvsub) do serval(vvroot,vvsub) quit
	. if $data(@vvroot@(vvsub))=10 set vvnxt=$order(@vvroot@(vvsub,"")) do  quit
	. . if +vvnxt do serary($name(@vvroot@(vvsub))) if 1
	. . else  do serobj($name(@vvroot@(vvsub)))
	. do errx("sob",vvsub)
	set @vvjson@(vvline)=@vvjson@(vvline)_"}"
	quit
serary(vvroot)
	new vvfirst,vvi,vvnxt
	set @vvjson@(vvline)=@vvjson@(vvline)_"["
	set vvfirst=1
	set vvi=0 for  set vvi=$order(@vvroot@(vvi)) quit:'vvi  do
	. set:'vvfirst @vvjson@(vvline)=@vvjson@(vvline)_"," set vvfirst=0
	. if $$isvalue(vvroot,vvi) do serval(vvroot,vvi) quit 
	. if $data(@vvroot@(vvi))=10 set vvnxt=$order(@vvroot@(vvi,"")) do  quit
	. . if +vvnxt do serary($name(@vvroot@(vvi))) if 1
	. . else  do serobj($name(@vvroot@(vvi)))
	. do errx("sar",vvi)
	set @vvjson@(vvline)=@vvjson@(vvline)_"]"
	quit
sername(vvsub)
	if ($zlength(vvsub)+$zlength(@vvjson@(vvline)))>vvmax set vvline=vvline+1,@vvjson@(vvline)=""
	set @vvjson@(vvline)=@vvjson@(vvline)_""""_vvsub_""""_":"
	quit
serval(vvroot,vvsub)
	new vvx,vvi
	if $data(@vvroot@(vvsub,":")) do  quit
	. set vvx=$get(@vvroot@(vvsub,":")) do:$zlength(vvx) concat
	. set vvi=0 for  set vvi=$order(@vvroot@(vvsub,":",vvi)) quit:'vvi  set vvx=@vvroot@(vvsub,":",vvi) do concat
	set vvx=$get(@vvroot@(vvsub))
	if '$data(@vvroot@(vvsub,"\s")),$$numeric(vvx) do concat quit
	if (vvx="true")!(vvx="false")!(vvx="null") do concat quit
	set vvx=""""_$$esc(vvx)
	do concat
	if $data(@vvroot@(vvsub,"\")) do
	. set vvi=0 for  set vvi=$order(@vvroot@(vvsub,"\",vvi)) quit:'vvi   do
	. . set vvx=$$esc(@vvroot@(vvsub,"\",vvi))
	. . do concat
	set vvx="""" do concat
	quit
concat
	if ($zlength(vvx)+$zlength(@vvjson@(vvline)))>vvmax set vvline=vvline+1,@vvjson@(vvline)=""
	set @vvjson@(vvline)=@vvjson@(vvline)_vvx
	quit
isvalue(vvroot,vvsub)
	if $data(@vvroot@(vvsub))#2 quit 1
	new vvx set vvx=$order(@vvroot@(vvsub,""))
	quit:vvx="\" 1
	quit:vvx=":" 1
	quit 0
numeric(x) 
	if $zlength(x,".")>2 quit 0
	if $zextract(x,1,2)="-." quit 0
	if x=+x,$zlength(x)'=$zlength(+x) quit 0
	if $zextract(x)="." quit 0
	if x=+x quit 1
	quit 0
esc(x)
	new y,%DH
	set y=x
	if x["\"  set y=$$replace(y,"\","\\")
	if x["""" set y=$$replace(y,"""","\""")
	if x["/"  set y=$$replace(y,"/","\/")
	if x[$char(8) set y=$$replace(y,$char(8),"\"_$char(98))
	if x[$char(12) set y=$$replace(y,$char(12),"\"_$char(102))
	if x[$char(10) set y=$$replace(y,$char(10),"\"_$char(110))
	if x[$char(13) set y=$$replace(y,$char(13),"\"_$char(114))
	if x[$char(9) set y=$$replace(y,$char(9),"\"_$char(116))
	new i for i=1:1:$zlength(x) do
	. if $ascii($zextract(x,i))=8   quit 
	. if $ascii($zextract(x,i))=12  quit 
	. if $ascii($zextract(x,i))=10  quit 
	. if $ascii($zextract(x,i))=13  quit 
	. if $ascii($zextract(x,i))=9   quit 
	. if $ascii($zextract(x,i))>=33 quit
	. set %DH=$ascii($zextract(x,i))
	. do ^%DH
	. set y=$$replace(y,$zextract(x,i),"\u"_$zextract(%DH,$zlength(%DH)-3,$zlength(%DH)))
	quit y 
	;
errx(id,val)
	new errmsg
	if id="stl{" set errmsg="stack too large for new object." goto xerrx
	if id="suf}" set errmsg="stack underflow - extra } found" goto xerrx
	if id="stl[" set errmsg="stack too large for new array." goto xerrx
	if id="suf]" set errmsg="stack underflow - extra ] found." goto xerrx
	if id="obm" set errmsg="array missmatch - expected ] got }." goto xerrx
	if id="arm" set errmsg="object mismatch - expected } got ]." goto xerrx
	if id="mpn" set errmsg="missing property name." goto xerrx
	if id="ext" set errmsg="expected true, got "_val goto xerrx
	if id="exf" set errmsg="expected false, got "_val goto xerrx
	if id="exn" set errmsg="expected null, got "_val goto xerrx
	if id="tkn" set errmsg="unable to identify type of token, value was "_val goto xerrx
	if id="sct" set errmsg="stack mismatch - exit stack level was  "_val goto xerrx
	if id="eiq" set errmsg="close quote not found before end of input." goto xerrx
	if id="eiu" set errmsg="unexpected end of input while unescaping." goto xerrx
	if id="rsb" set errmsg="reverse search for \ past beginning of input." goto xerrx
	if id="orn" set errmsg="overrun while scanning name." goto xerrx
	if id="or#" set errmsg="overrun while scanning number." goto xerrx
	if id="orb" set errmsg="overrun while scanning boolean." goto xerrx
	if id="esc" set errmsg="escaped character not recognized"_val goto xerrx
	if id="sob" set errmsg="unable to serialize node as object, value was "_val goto xerrx
	if id="sar" set errmsg="unable to serialize node as array, value was "_val goto xerrx
	set errmsg="unspecified error "_id_" "_$get(val)
xerrx
	set @vverr@(0)=$get(@vverr@(0))+1
	set @vverr@(@vverr@(0))=errmsg
	set vverrors=vverrors+1
	quit
	;
decode(vvjson,vvroot,vverr)
direct
	new vvmax set vvmax=4080
	if $data(@vvjson)=1 new vvinput set vvinput(1)=@vvjson,vvjson="vvinput"
	set vvroot=$name(@vvroot@("z")),vvroot=$zextract(vvroot,1,$zlength(vvroot)-4) ; make open array ref
	new vvline,vvidx,vvstack,vvprop,vvtype,vverrors
	set vvline=$order(@vvjson@("")),vvidx=1,vvstack=0,vvprop=0,vverrors=0
	for  set vvtype=$$nxtkn() quit:vvtype=""  do  if vverrors quit
	. if vvtype="{" set vvstack=vvstack+1,vvstack(vvstack)="",vvprop=1 do:vvstack>64 errx("stl{") quit
	. if vvtype="}" do:$$numeric(vvstack(vvstack)) errx("obm") set vvstack=vvstack-1 do:vvstack<0 errx("suf}") quit
	. if vvtype="[" set vvstack=vvstack+1,vvstack(vvstack)=1 do:vvstack>64 errx("stl[") quit
	. if vvtype="]" do:'$$numeric(vvstack(vvstack)) errx("arm") set vvstack=vvstack-1 do:vvstack<0 errx("suf]") quit
	. if vvtype="," do  quit
	. . if vvstack(vvstack) set vvstack(vvstack)=vvstack(vvstack)+1  ; next in array
	. . else  set vvprop=1                                   ; or next property name
	. if vvtype=":" set vvprop=0 do:'$zlength($get(vvstack(vvstack))) errx("mpn") quit
	. if vvtype="""" do  quit
	. . if vvprop set vvstack(vvstack)=$$nampars() if 1
	. . else  do addstr
	. set vvtype=$translate(vvtype,"tfn","tfn")
	. if vvtype="t"  do  quit
	. . if $zlength(@vvjson@(vvline))<=vvidx+2,$data(@vvjson@(vvline+1)) do
	. . . set @vvjson@(vvline)=@vvjson@(vvline)_$zextract(@vvjson@(vvline+1),1,2),@vvjson@(vvline+1)=$zextract(@vvjson@(vvline+1),3,$zlength(@vvjson@(vvline+1)))
	. . if $translate($zextract(@vvjson@(vvline),vvidx,vvidx+2),"rue","rue")="rue" do setbool("true") if 1
	. . else  break  do errx("ext",vvtype)
	. if vvtype="f" do  quit
	. . if $zlength(@vvjson@(vvline))<=vvidx+3,$data(@vvjson@(vvline+1)) do
	. . . set @vvjson@(vvline)=@vvjson@(vvline)_$zextract(@vvjson@(vvline+1),1,3),@vvjson@(vvline+1)=$zextract(@vvjson@(vvline+1),4,$zlength(@vvjson@(vvline+1)))
	. . if $translate($zextract(@vvjson@(vvline),vvidx,vvidx+3),"alse","alse")="alse" do setbool("false") if 1
	. . else  do errx("exf",vvtype)
	. if vvtype="n" do  quit
	. . if $zlength(@vvjson@(vvline))<=vvidx+2,$data(@vvjson@(vvline+1)) do
	. . . set @vvjson@(vvline)=@vvjson@(vvline)_$zextract(@vvjson@(vvline+1),1,2),@vvjson@(vvline+1)=$zextract(@vvjson@(vvline+1),3,$zlength(@vvjson@(vvline+1)))
	. . if $translate($zextract(@vvjson@(vvline),vvidx,vvidx+2),"ull","ull")="ull" do setbool("null") if 1
	. . else  do errx("exn",vvtype)
	. if "0123456789+-.ee"[vvtype set @$$curnode()=$$numpars(vvtype) quit
	. do errx("tkn",vvtype_"["_$zextract(@vvjson@(vvline),vvidx,vvidx+2)_"] ")
	if vvstack'=0 do errx("sct",vvstack)
	quit
nxtkn()
	new vvdone,vveof,vvtoken
	set vvdone=0,vveof=0 for  do  quit:vvdone!vveof
	. if vvidx>$zlength(@vvjson@(vvline)) set vvline=$order(@vvjson@(vvline)),vvidx=1 if 'vvline set vveof=1 quit
	. if $ascii(@vvjson@(vvline),vvidx)>32 set vvdone=1 quit
	. set vvidx=vvidx+1
	quit:vveof ""
	set vvtoken=$zextract(@vvjson@(vvline),vvidx),vvidx=vvidx+1
	quit vvtoken
addstr
	new vvend,vvx
	set vvend=$find(@vvjson@(vvline),"""",vvidx)
	if vvend,($zextract(@vvjson@(vvline),vvend-2)'="\") do setstr  quit
	if vvend,$$iscloseq(vvline) do setstr quit
	new vvdone,vvtline
	set vvdone=0,vvtline=vvline
	for  do  quit:vvdone  quit:vverrors
	. if 'vvend set vvtline=vvtline+1,vvend=1 if '$data(@vvjson@(vvtline)) do errx("eiq") quit
	. set vvend=$find(@vvjson@(vvtline),"""",vvend)
	. if vvend,$zextract(@vvjson@(vvtline),vvend-2)'="\" set vvdone=1 quit
	. set vvdone=$$iscloseq(vvtline)
	quit:vverrors
	do uesext
	set vvline=vvtline,vvidx=vvend
	quit
setstr
	new vvx
	set vvx=$zextract(@vvjson@(vvline),vvidx,vvend-2),vvidx=vvend
	set @$$curnode()=$$ues(vvx)
	if vvidx>$zlength(@vvjson@(vvline)) set vvline=vvline+1,vvidx=1
	quit
uesext
	new vvi,vvy,vvstart,vvstop,vvdone,vvbuf,vvnode,vvmore,vvto
	set vvnode=$$curnode(),vvbuf="",vvmore=0,vvstop=vvend-2
	set vvi=vvidx,vvy=vvline,vvdone=0
	for  do  quit:vvdone  quit:vverrors
	. set vvstart=vvi,vvi=$find(@vvjson@(vvy),"\",vvi)
	. if (vvy=vvtline) set vvto=$select('vvi:vvstop,vvi>vvstop:vvstop,1:vvi-2) if 1
	. else  set vvto=$select('vvi:99999,1:vvi-2)
	. do addbuf($zextract(@vvjson@(vvy),vvstart,vvto))
	. if (vvy'<vvtline),(('vvi)!(vvi>vvstop)) set vvdone=1 quit
	. if 'vvi set vvy=vvy+1,vvi=1 quit 
	. if vvi>$zlength(@vvjson@(vvy)) set vvy=vvy+1,vvi=1 if '$data(@vvjson@(vvy)) do errx("eiu")
	. do addbuf($$realchar($zextract(@vvjson@(vvy),vvi),@vvjson@(vvy),.vvi))
	. set vvi=vvi+1
	. if (vvy'<vvtline),(vvi>vvstop) set vvdone=1
	quit:vverrors
	do savebuf
	quit
addbuf(vvx)
	if $zlength(vvx)+$zlength(vvbuf)>vvmax do savebuf
	set vvbuf=vvbuf_vvx
	quit
savebuf
	if 'vvmore set @vvnode=vvbuf set:+vvbuf=vvbuf @vvnode@("\s")="" if 1
	else  set @vvnode@("\",vvmore)=vvbuf
	set vvmore=vvmore+1,vvbuf=""
	quit
iscloseq(vvbline)
	new vvback,vvbidx
	set vvback=0,vvbidx=vvend-2
	for  do  quit:$zextract(@vvjson@(vvbline),vvbidx)'="\"  quit:vverrors
	. set vvback=vvback+1,vvbidx=vvbidx-1
	. if (vvbline=vvline),(vvbidx=vvidx) quit
	. quit:vvbidx
	. set vvbline=vvbline-1 if vvbline<vvline do errx("rsb") quit
	. set vvbidx=$zlength(@vvjson@(vvbline))
	quit vvback#2=0
nampars()
	new vvend,vvdone,vvname
	set vvdone=0,vvname=""
	for  do  quit:vvdone  quit:vverrors
	. set vvend=$find(@vvjson@(vvline),"""",vvidx)
	. if vvend set vvname=vvname_$zextract(@vvjson@(vvline),vvidx,vvend-2),vvidx=vvend,vvdone=1
	. if 'vvend set vvname=vvname_$zextract(@vvjson@(vvline),vvidx,$zlength(@vvjson@(vvline)))
	. if 'vvend!(vvend>$zlength(@vvjson@(vvline))) set vvline=vvline+1,vvidx=1 if '$data(@vvjson@(vvline)) do errx("orn")
	quit vvname
numpars(vvdigit)
	new vvdone,vvnum
	set vvdone=0,vvnum=vvdigit
	for  do  quit:vvdone  quit:vverrors
	. if '("0123456789+-.ee"[$zextract(@vvjson@(vvline),vvidx)) set vvdone=1 quit
	. set vvnum=vvnum_$zextract(@vvjson@(vvline),vvidx)
	. set vvidx=vvidx+1 if vvidx>$zlength(@vvjson@(vvline)) set vvline=vvline+1,vvidx=1 if '$data(@vvjson@(vvline)) do errx("or#")
	quit vvnum
setbool(vvx)
	set @$$curnode()=vvx
	set vvidx=vvidx+$zlength(vvx)-1
	new vvdiff set vvdiff=vvidx-$zlength(@vvjson@(vvline))
	if vvdiff>0 set vvline=vvline+1,vvidx=vvdiff if '$data(@vvjson@(vvline)) do errx("orb")
	quit
curnode()
	new vvi,vvsubs
	set vvsubs=""
	for vvi=1:1:vvstack set:vvi>1 vvsubs=vvsubs_"," do
	. if $$numeric(vvstack(vvi))  set vvsubs=vvsubs_vvstack(vvi)
	. else  set vvsubs=vvsubs_""""_vvstack(vvi)_""""
	quit vvroot_vvsubs_")"
ues(x)
	new pos,y,start
	set pos=0,y=""
	for  set start=pos+1 do  quit:start>$zlength(x)
	. set pos=$find(x,"\",pos+1)
	. if 'pos set y=y_$zextract(x,start,$zlength(x)),pos=$zlength(x) if 1
	. else  set y=y_$zextract(x,start,pos-2)_$$realchar($zextract(x,pos),x,.pos)
	quit y
realchar(c,x,pos)
	new opos
	if c="""" quit """"
	if c="/" quit "/"
	if c="\" quit "\"
	if c="b" quit $char(8)
	if c="f" quit $char(12)
	if c="n" quit $char(10)
	if c="r" quit $char(13)
	if c="t" quit $char(9)
	if c="u" set opos=pos set pos=pos+4 quit $char($$FUNC^%HD($zextract(x,opos+1,opos+4)))
	quit c
	;
hash(x)
	quit $$crc32(x)
sysid() ;
	set x=$system
	quit $$crc16hex(x)
crc16hex(x)
	quit $$base($$crc16(x),10,16)
crc32hex(x)
	quit $$base($$crc32(x),10,16)
dec2hex(num)
	quit $$base(num,10,16)
hex2dec(hex)
	quit $$base(hex,16,10)
crc32(string,seed) ;
	new i,j,r
	if '$data(seed) set r=4294967295
	else  if seed'<0,seed'>4294967295 set r=4294967295-seed
	else  set $ecode=",m28,"
	for i=1:1:$zlength(string) do
	. set r=$$xor($ascii(string,i),r,8)
	. for j=0:1:7 do
	. . if r#2 set r=$$xor(r\2,3988292384,32)
	. . else  set r=r\2
	. . quit
	. quit
	quit 4294967295-r
xor(a,b,w) new i,m,r
	set r=b,m=1
	for i=1:1:w do
	. set:a\m#2 r=r+$select(r\m#2:-m,1:m)
	. set m=m+m
	. quit
	quit r
base(%x1,%x2,%x3) ;convert %x1 from %x2 base to %x3 base
	if (%x2<2)!(%x2>16)!(%x3<2)!(%x3>16) quit -1
	quit $$cnv($$dec(%x1,%x2),%x3)
dec(n,b) ;cnv n from b to 10
	quit:b=10 n new i,y set y=0
	for i=1:1:$zlength(n) set y=y*b+($find("0123456789abcdef",$zextract(n,i))-2)
	quit y
cnv(n,b) ;cnv n from 10 to b
	quit:b=10 n new i,y set y=""
	for i=1:1 set y=$zextract("0123456789abcdef",n#b+1)_y,n=n\b quit:n<1
	quit y
crc16(string,seed) ;
	; polynomial x**16 + x**15 + x**2 + x**0
	new i,j,r
	if '$data(seed) set r=0
	else  if seed'<0,seed'>65535 set r=seed\1
	else  set $ecode=",m28,"
	for i=1:1:$zlength(string) do
	. set r=$$xor($ascii(string,i),r,8)
	. for j=0:1:7 do
	. . if r#2 set r=$$xor(r\2,40961,16)
	. . else  set r=r\2
	. . quit
	. quit
	quit r
	;
htfm(%h,%f) ;$h to fm, %f=1 for date only
	new x,%,%t,%y,%m,%d set:'$data(%f) %f=0
	if $$hr(%h) quit -1 ;check range
	if '%f,%h[",0" set %h=(%h-1)_",86400"
	do ymd set:%t&('%f) x=x_%t
	quit x
ymd ;21608 = 28 feb 1900, 94657 = 28 feb 2100, 141 $h base year
	set %=(%h>21608)+(%h>94657)+%h-.1,%y=%\365.25+141,%=%#365.25\1
	set %d=%+306#(%y#4=0+365)#153#61#31+1,%m=%-%d\29+1
	set x=%y_"00"+%m_"00"+%d,%=$zpiece(%h,",",2)
	set %t=%#60/100+(%#3600\60)/100+(%\3600)/100 set:'%t %t=".0"
	quit
hr(%v) ;check $h in valid range
	quit (%v<2)!(%v>99999)
	;
hte(%h,%f) ;$h to external
	quit:$$hr(%h) %h ;range check
	new y,%t,%r
	set %f=$get(%f,1) set y=$$htfm(%h,0)
t2 set %t="."_$zextract($zpiece(y,".",2)_"000000",1,7)
	do fmt quit %r
fmt ;
	new %g set %g=+%f
	goto f1:%g=1,f2:%g=2,f3:%g=3,f4:%g=4,f5:%g=5,f6:%g=6,f7:%g=7,f8:%g=8,f9:%g=9,f1
	quit
	;
f1 ;apr 10, 2002
	set %r=$zpiece($$m()," ",$select($zextract(y,4,5):$zextract(y,4,5)+2,1:0))_$select($zextract(y,4,5):" ",1:"")_$select($zextract(y,6,7):$zextract(y,6,7)_", ",1:"")_($zextract(y,1,3)+1700)
	;
tm ;all formats come here to format time. ;
	new %,%s quit:%t'>0!(%f["d")
	if %f'["p" set %r=%r_"@"_$zextract(%t,2,3)_":"_$zextract(%t,4,5)_$select(%f["m":"",$zextract(%t,6,7)!(%f["s"):":"_$zextract(%t,6,7),1:"")
	if %f["p" do
	. set %r=%r_" "_$select($zextract(%t,2,3)>12:$zextract(%t,2,3)-12,+$zextract(%t,2,3)=0:"12",1:+$zextract(%t,2,3))_":"_$zextract(%t,4,5)_$select(%f["m":"",$zextract(%t,6,7)!(%f["s"):":"_$zextract(%t,6,7),1:"")
	. set %r=%r_$select($zextract(%t,2,7)<120000:" am",$zextract(%t,2,3)=24:" am",1:" pm")
	. quit
	quit
	;return month names
m() quit "  jan feb mar apr may jun jul aug sep oct nov dec"
	;
f2 ;4/10/02
	set %r=$justify(+$zextract(y,4,5),2)_"/"_$justify(+$zextract(y,6,7),2)_"/"_$zextract(y,2,3)
	set:%f["z" %r=$translate(%r," ","0") set:%f'["f" %r=$translate(%r," ")
	goto tm
f3 ;10/4/02
	set %r=$justify(+$zextract(y,6,7),2)_"/"_$justify(+$zextract(y,4,5),2)_"/"_$zextract(y,2,3)
	set:%f["z" %r=$translate(%r," ","0") set:%f'["f" %r=$translate(%r," ")
	goto tm
f4 ;02/4/10
	set %r=$zextract(y,2,3)_"/"_$justify(+$zextract(y,4,5),2)_"/"_$justify(+$zextract(y,6,7),2)
	set:%f["z" %r=$translate(%r," ","0") set:%f'["f" %r=$translate(%r," ")
	goto tm
f5 ;4/10/2002
	set %r=$justify(+$zextract(y,4,5),2)_"/"_$justify(+$zextract(y,6,7),2)_"/"_($zextract(y,1,3)+1700)
	set:%f["z" %r=$translate(%r," ","0") set:%f'["f" %r=$translate(%r," ")
	goto tm
f6 ;10/4/2002
	set %r=$justify(+$zextract(y,6,7),2)_"/"_$justify(+$zextract(y,4,5),2)_"/"_($zextract(y,1,3)+1700)
	set:%f["z" %r=$translate(%r," ","0") set:%f'["f" %r=$translate(%r," ")
	goto tm
f7 ;2002/4/10
	set %r=($zextract(y,1,3)+1700)_"/"_$justify(+$zextract(y,4,5),2)_"/"_$justify(+$zextract(y,6,7),2)
	set:%f["z" %r=$translate(%r," ","0") set:%f'["f" %r=$translate(%r," ")
	goto tm
f8 ;10 apr 02
	set %r=$select($zextract(y,6,7):$zextract(y,6,7)_" ",1:"")_$zpiece($$m()," ",$select($zextract(y,4,5):$zextract(y,4,5)+2,1:0))_$select($zextract(y,4,5):" ",1:"")_$zextract(y,2,3)
	goto tm
f9 ;10 apr 2002
	set %r=$select($zextract(y,6,7):$zextract(y,6,7)_" ",1:"")_$zpiece($$m()," ",$select($zextract(y,4,5):$zextract(y,4,5)+2,1:0))_$select($zextract(y,4,5):" ",1:"")_($zextract(y,1,3)+1700)
	goto tm
	;
parse10(body,parsed)
	new ll set ll="" ; last line
	new l set l=1 ; line counter. ;
	kill parsed ; kill return array
	new i set i="" for  set i=$order(body(i)) quit:'i  do  ; for each 4080 character block
	. new j for j=1:1:$zlength(body(i),$char(10)) do  ; for each line
	. . set:(j=1&(l>1)) l=l-1 ; replace old line (see 2 lines below)
	. . set parsed(l)=$translate($zpiece(body(i),$char(10),j),$char(13)) ; get line; take cr out if there. ;
	. . set:(j=1&(l>1)) parsed(l)=ll_parsed(l) ; if first line, append the last line before it and replace it. ;
	. . set ll=parsed(l) ; set last line
	. . set l=l+1 ; linenumber++
	quit
	;
addcrlf(result) ; add crlf to each line
	if $zextract($get(result))="^" do  quit  ; global
	. new v,ql set v=result,ql=$qlength(v) for  set v=$query(@v) quit:v=""  quit:$name(@v,ql)'=result  set @v=@v_$char(13,10)
	else  do  ; local variable passed by reference
	. if $data(result)#2 set result=result_$char(13,10)
	. new v set v=$name(result) for  set v=$query(@v) quit:v=""  set @v=@v_$char(13,10)
	quit
	;
encode64(x) ;
	new rgz,rgz1,rgz2,rgz3,rgz4,rgz5,rgz6
	set rgz=$$init64,rgz1=""
	for rgz2=1:3:$zlength(x) do
	. set rgz3=0,rgz6=""
	. for rgz4=0:1:2 do
	. . set rgz5=$ascii(x,rgz2+rgz4),rgz3=rgz3*256+$select(rgz5<0:0,1:rgz5)
	. for rgz4=1:1:4 set rgz6=$zextract(rgz,rgz3#64+2)_rgz6,rgz3=rgz3\64
	. set rgz1=rgz1_rgz6
	set rgz2=$zlength(x)#3
	set:rgz2 rgz3=$zlength(rgz1),$zextract(rgz1,rgz3-2+rgz2,rgz3)=$zextract("==",rgz2,2)
	quit rgz1
decode64(x) ;
	new rgz,rgz1,rgz2,rgz3,rgz4,rgz5,rgz6
	set rgz=$$init64,rgz1=""
	for rgz2=1:4:$zlength(x) do
	. set rgz3=0,rgz6=""
	. for rgz4=0:1:3 do
	. . set rgz5=$find(rgz,$zextract(x,rgz2+rgz4))-3
	. . set rgz3=rgz3*64+$select(rgz5<0:0,1:rgz5)
	. for rgz4=0:1:2 set rgz6=$char(rgz3#256)_rgz6,rgz3=rgz3\256
	. set rgz1=rgz1_rgz6
	quit $zextract(rgz1,1,$zlength(rgz1)-$zlength(x,"=")+1)
init64() quit "=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		;
replace(s,f,t)
	if $translate(s,f)=s quit s
	new o,i set o="" for i=1:1:$zlength(s,f)  set o=o_$select(i<$zlength(s,f):$zpiece(s,f,i)_t,1:$zpiece(s,f,i))
	quit o
	;
getmimetype(ext)
	if $get(ext)="" set ext="*"
	set ext=$$low(ext)
	if '$data(ydbweb(":ws","mime")) do
	. set ydbweb(":ws","mime","html")="text/html" 
	. set ydbweb(":ws","mime","htm")="text/html" 
	. set ydbweb(":ws","mime","shtml")="text/html"
	. set ydbweb(":ws","mime","css")="text/css"
	. set ydbweb(":ws","mime","xml")="text/xml"
	. set ydbweb(":ws","mime","gif")="image/gif"
	. set ydbweb(":ws","mime","jpeg")="image/jpeg" 
	. set ydbweb(":ws","mime","jpg")="image/jpeg"
	. set ydbweb(":ws","mime","js")="application/javascript"
	. set ydbweb(":ws","mime","atom")="application/atom+xml"
	. set ydbweb(":ws","mime","rss")="application/rss+xml"
	. set ydbweb(":ws","mime","mml")="text/mathml"
	. set ydbweb(":ws","mime","txt")="text/plain"
	. set ydbweb(":ws","mime","jad")="text/vnd.sun.j2me.app-descriptor"
	. set ydbweb(":ws","mime","wml")="text/vnd.wap.wml"
	. set ydbweb(":ws","mime","htc")="text/x-component"
	. set ydbweb(":ws","mime","png")="image/png"
	. set ydbweb(":ws","mime","tif")="image/tiff" 
	. set ydbweb(":ws","mime","tiff")="image/tiff"
	. set ydbweb(":ws","mime","wbmp")="image/vnd.wap.wbmp"
	. set ydbweb(":ws","mime","ico")="image/x-icon"
	. set ydbweb(":ws","mime","jng")="image/x-jng"
	. set ydbweb(":ws","mime","bmp")="image/x-ms-bmp"
	. set ydbweb(":ws","mime","svg")="image/svg+xml"
	. set ydbweb(":ws","mime","svgz")="image/svg+xml"
	. set ydbweb(":ws","mime","webp")="image/webp"
	. set ydbweb(":ws","mime","woff")="application/font-woff"
	. set ydbweb(":ws","mime","jar")="application/java-archive" 
	. set ydbweb(":ws","mime","war")="application/java-archive"
	. set ydbweb(":ws","mime","ear")="application/java-archive"
	. set ydbweb(":ws","mime","json")="application/json"
	. set ydbweb(":ws","mime","hqx")="application/mac-binhex40"
	. set ydbweb(":ws","mime","doc")="application/msword"
	. set ydbweb(":ws","mime","pdf")="application/pdf"
	. set ydbweb(":ws","mime","ps")="application/postscript" 
	. set ydbweb(":ws","mime","eps")="application/postscript" 
	. set ydbweb(":ws","mime","ai")="application/postscript"
	. set ydbweb(":ws","mime","rtf")="application/rtf"
	. set ydbweb(":ws","mime","m3u8")="application/vnd.apple.mpegurl"
	. set ydbweb(":ws","mime","xls")="application/vnd.ms-excel"
	. set ydbweb(":ws","mime","eot")="application/vnd.ms-fontobject"
	. set ydbweb(":ws","mime","ppt")="application/vnd.ms-powerpoint"
	. set ydbweb(":ws","mime","wmlc")="application/vnd.wap.wmlc"
	. set ydbweb(":ws","mime","kml")="application/vnd.google-earth.kml+xml"
	. set ydbweb(":ws","mime","kmz")="application/vnd.google-earth.kmz"
	. set ydbweb(":ws","mime","7z")="application/x-7z-compressed"
	. set ydbweb(":ws","mime","cco")="application/x-cocoa"
	. set ydbweb(":ws","mime","jardiff")="application/x-java-archive-diff"
	. set ydbweb(":ws","mime","jnlp")="application/x-java-jnlp-file"
	. set ydbweb(":ws","mime","run")="application/x-makeself"
	. set ydbweb(":ws","mime","pl")="application/x-perl"
	. set ydbweb(":ws","mime","pm")="application/x-perl"
	. set ydbweb(":ws","mime","prc")="application/x-pilot" 
	. set ydbweb(":ws","mime","pdb")="application/x-pilot"
	. set ydbweb(":ws","mime","rar")="application/x-rar-compressed"
	. set ydbweb(":ws","mime","rpm")="application/x-redhat-package-manager"
	. set ydbweb(":ws","mime","sea")="application/x-sea"
	. set ydbweb(":ws","mime","swf")="application/x-shockwave-flash"
	. set ydbweb(":ws","mime","sit")="application/x-stuffit"
	. set ydbweb(":ws","mime","tcl")="application/x-tcl"
	. set ydbweb(":ws","mime","tk")="application/x-tcl"
	. set ydbweb(":ws","mime","der")="application/x-x509-ca-cert"
	. set ydbweb(":ws","mime","pem")="application/x-x509-ca-cert"
	. set ydbweb(":ws","mime","crt")="application/x-x509-ca-cert"
	. set ydbweb(":ws","mime","xpi")="application/x-xpinstall"
	. set ydbweb(":ws","mime","xhtml")="application/xhtml+xml"
	. set ydbweb(":ws","mime","xspf")="application/xspf+xml"
	. set ydbweb(":ws","mime","zip")="application/zip"
	. set ydbweb(":ws","mime","bin")="application/octet-stream" 
	. set ydbweb(":ws","mime","exe")="application/octet-stream" 
	. set ydbweb(":ws","mime","dll")="application/octet-stream"
	. set ydbweb(":ws","mime","deb")="application/octet-stream"
	. set ydbweb(":ws","mime","dmg")="application/octet-stream"
	. set ydbweb(":ws","mime","iso")="application/octet-stream"
	. set ydbweb(":ws","mime","img")="application/octet-stream"
	. set ydbweb(":ws","mime","msi")="application/octet-stream"
	. set ydbweb(":ws","mime","msp")="application/octet-stream"
	. set ydbweb(":ws","mime","msm")="application/octet-stream"
	. set ydbweb(":ws","mime","docx")="application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	. set ydbweb(":ws","mime","xlsx")="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
	. set ydbweb(":ws","mime","pptx")="application/vnd.openxmlformats-officedocument.presentationml.presentation"
	. set ydbweb(":ws","mime","mid")="audio/midi"
	. set ydbweb(":ws","mime","midi")="audio/midi"
	. set ydbweb(":ws","mime","kar")="audio/midi"
	. set ydbweb(":ws","mime","mp3")="audio/mpeg"
	. set ydbweb(":ws","mime","ogg")="audio/ogg"
	. set ydbweb(":ws","mime","m4a")="audio/x-m4a"
	. set ydbweb(":ws","mime","ra")="audio/x-realaudio"
	. set ydbweb(":ws","mime","3gpp")="video/3gpp"
	. set ydbweb(":ws","mime","3gp")="video/3gpp"
	. set ydbweb(":ws","mime","ts")="video/mp2t"
	. set ydbweb(":ws","mime","mp4")="video/mp4"
	. set ydbweb(":ws","mime","mpeg")="video/mpeg"
	. set ydbweb(":ws","mime","mpg")="video/mpeg"
	. set ydbweb(":ws","mime","mov")="video/quicktime"
	. set ydbweb(":ws","mime","webm")="video/webm"
	. set ydbweb(":ws","mime","flv")="video/x-flv"
	. set ydbweb(":ws","mime","m4v")="video/x-m4v"
	. set ydbweb(":ws","mime","mng")="video/x-mng"
	. set ydbweb(":ws","mime","asx")="video/x-ms-asf"
	. set ydbweb(":ws","mime","asf")="video/x-ms-asf"
	. set ydbweb(":ws","mime","wmv")="video/x-ms-wmv"
	. set ydbweb(":ws","mime","avi")="video/x-msvideo"
	if $data(ydbweb(":ws","mime",ext)) quit ydbweb(":ws","mime",ext)
	else  quit "application/octet-stream"
	;
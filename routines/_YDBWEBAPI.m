%YDBWEBAPI ; YottaDB Web Server API Entry Point; 05-07-2021
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
api(httpreq,httprsp,httpargs)
	new json
	set httprsp("mime")="application/json"
	set httprsp("header","Access-Control-Allow-Origin")="*"
	set httprsp("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept"
	if '$data(@httpreq("body")) quit
	new input do decode^%YDBWEB(httpreq("body"),"input")
	new %routine set %routine=input("routine")
	kill input("routine") kill json
	new (input,json,%wtcp,%routine,httpreq,httprsp,httpargs,%ydbwebresp)
	do @(%routine_"(.input,.json)")
	kill @httprsp do encode^%YDBWEB("json",httprsp)
	quit
	;
servestatic(httpreq,httprsp,httpargs)	
	new path set path=$get(httpreq("path")) 
	if path="" set path="/YottaDB/index.html"
	if path="/" set path="/YottaDB/index.html"
	if path="/YottaDB" set path="/YottaDB/index.html"
	if path="/YottaDB/" set path="/YottaDB/index.html"
	if $zextract(path,1,9)'="/YottaDB/" do seterror^%YDBWEB(404) quit
	new filepaths
	set filepath="dist/spa/"_$zextract(path,10,$zlength(path))
	if $zpiece(filepath,".",$zlength(filepath,"."))["?" do
	. set $zpiece(filepath,".",$zlength(filepath,"."))=$zpiece($zpiece(filepath,".",$zlength(filepath,".")),"?")
	if '$$FileExists^%YDBUTILS(filepath) do
	. set filepath="dist/spa/index.html"
	new ext set ext=$zpiece(filepath,".",$zlength(filepath,"."))
	set httprsp("mime")=$$getmimetype^%YDBWEB(ext)
	new output
	do ReadFileByChunk^%YDBUTILS(filepath,4080,.output)
	merge @httprsp=output
	quit
	;	
PING(i,o)
	set o("data","RESULT")="pong"
	quit
	;
error ;
	quit
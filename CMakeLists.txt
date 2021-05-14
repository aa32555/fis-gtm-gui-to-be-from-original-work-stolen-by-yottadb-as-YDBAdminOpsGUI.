#################################################################
#                                                               #
# Copyright (c) 2021 YottaDB LLC and/or its subsidiaries.       #
# All rights reserved.                                          #
#                                                               #
#   This source code contains the intellectual property         #
#   of its copyright holder(s), and is made available           #
#   under a license.  If you do not know the terms of           #
#   the license, please stop and do not read further.           #
#                                                               #
#################################################################

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/ydbcmake/")
set(M_EMBED_SOURCE TRUE)
set(M_DYNAMIC_LITERALS TRUE)

project(YDBUI C M)
cmake_minimum_required(VERSION 2.8)

# Find YottaDB
find_package(YOTTADB REQUIRED)
include_directories("${YOTTADB_INCLUDE_DIRS}")

set(ydb_install_dir ${YOTTADB_INCLUDE_DIRS}/plugin)

# Make sure npm & node are installed
find_program(NPM NAMES npm)
find_program(NODE NAMES node)

if(NOT NPM)
  message(FATAL_ERROR "Unable to find 'npm'.  Please install npm and make sure it is available in your path.")
endif()

if(NOT NODE)
  message(FATAL_ERROR "Unable to find 'node'.  Please install node.js and make sure it is available in your path.")
endif()


set(source_files
  routines/_YDBUTILS.m
  routines/_YDBUTILS1.m
  routines/_YDBUTILS2.m
  routines/_YDBUTILS3.m
  routines/_YDBWEB.m
  routines/_YDBWEBAPI.m
  routines/_YDBWEBGDE.m
  routines/_YDBWEBGLBLS.m
  routines/_YDBWEBPRSC.m
  routines/_YDBWEBRTNS.m
  routines/_YDBWEBTBLS.m
  routines/_YDBWEBXUSCLEAN.m
  routines/_YDBWEBXUSCNT.m
  routines/_YDBWEBZSY.m
  routines/_YDBWEBZU.m
)

# Add commands to compile .m files
add_library(ydbui SHARED ${source_files})

SET_TARGET_PROPERTIES(ydbui PROPERTIES PREFIX "")

install(FILES ${source_files} DESTINATION ${ydb_install_dir}/r/)

if(M_UTF8_MODE)
  install(TARGETS ydbui DESTINATION ${ydb_install_dir}/o/utf8)
else()
  install(TARGETS ydbui DESTINATION ${ydb_install_dir}/o/)
endif()


# HTML files
install(DIRECTORY dist/ DESTINATION ${ydb_install_dir}/ui/dist)

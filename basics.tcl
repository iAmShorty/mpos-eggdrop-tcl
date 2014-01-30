#
# Basic TCL Commands used in MPOS Api Scripts
#
# Copyright: 2014, iAmShorty
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
######################################################################
##########           nothing to edit below this line        ##########
##########           use config.tcl for setting options     ##########
######################################################################

#
# key bindings
#
bind pub - !pool pool_info
bind pub - !block block_info
bind pub - !last last_info
bind pub - !user user_info
bind pub - !round round_info
bind pub - !worker worker_info
bind pub - !balance balance_info
bind pub - ?help printUsage

# getting the pool vars from dictionary
# set in config for specific pool
#
proc pool_vars {coinname} {
	global pools
	set pool_found "false"
	#putlog "Number of Pools: [dict size $pools]"
	dict for {id info} $pools {
   	 	if {[string toupper $id] eq [string toupper $coinname]} {
   	 		set pool_found "true"
   	 		#putlog "Pool: [string toupper $id]"
    		dict with info {
       			set pool_data "[string toupper $id] $apiurl $apikey"
    		}
   	 	}
	}
	
	if {$pool_found eq "true"} {
		return $pool_data
	} else {
		return "0"
	}
}

# replace variables
#
proc replacevar {string cookie value} {
	variable zeroconvert
	if {[string length $value] == 0 && [info exists zeroconvert($cookie)]} {
		set value $zeroconvert($cookie)
	}
	return [string map [list $cookie $value] $string]
}

        
# wordwrap proc that accepts multiline data 
# (empty lines will be stripped because there's no way to relay them via irc) 
#
proc wordwrap {data len} { 
   set out {} 
   foreach line [split [string trim $data] \n] { 
      set curr {} 
      set i 0 
      foreach word [split [string trim $line]] { 
         if {[incr i [string len $word]]>$len} { 
            lappend out [join $curr] 
            set curr [list $word] 
            set i [string len $word] 
         } { 
            lappend curr $word 
         } 
         incr i 
      } 
      if {[llength $curr]} { 
         lappend out [join $curr] 
      } 
   } 
   set out 
}

# basic file operations
#
proc file_write {filename blocknumber {AUTOAPPEND 0} {NEWLINE 1}} {
    # when no file exists or not autoappend is on = create/overwrite
    if {![file exists $filename] && $AUTOAPPEND!=1} then {
        # open for writemode
        set FILE [open $filename w]
    } else {
        # open for appendmode
        set FILE [open $filename a]
    }
    # write buffer
    if $NEWLINE {puts $FILE $blocknumber} {puts -nonewline $FILE $blocknumber}
    # release and return 1 for OK
    close $FILE
    return 1
}

proc file_read {filename} {
    # check exists and readable
    if {[file exists $filename] && [file readable $filename]} then {
        # open for readmode
        set FILE [open $filename r]
     	set READ [read -nonewline $FILE]
        # release and return
        close $FILE
        return $READ
    } else {
    	return 0
    }
}

proc file_check {filename} {
    # check file exists
    if [file exists $filename] then {
        # file exists
        return 1
    } else {
        # file not exists
        return "0"
    }
}

proc FileTextRead {FILENAME {LINEMODE 0}} {
    # check exists and readable
    if {[file exists $FILENAME] && [file readable $FILENAME]} then {
        # open for readmode
        set FILE [open $FILENAME r]
        if {$LINEMODE!=1} then {
            # read buffer
            set READ [read -nonewline $FILE]
        } else {
            # read line
            set READ [get $FILE]
        }
        # release and return
        close $FILE
        return $READ
    }
    # not readable
    return 0
}

proc FileTextReadLine {FILENAME LINENR {METHODE 1}} {
    # starts with LINENR 0 = line1, 1=line2, ..., 199=line200, ..

    proc ReadWithEof {FILE LINENR} {
        set ReadNUM 0
        # not end of file reached? read nexline
        while ![eof $FILE] {
            set LINE [gets $FILE]
            if {$LINENR==$ReadNUM} {return $LINE}
            incr ReadNUM
        }
        # failed
        return 0
    }

    proc ReadFullAndSplit {FILE LINENR} {
        # read full file
        set BUFFER [read -nonewline $FILE]
        # convert to a list
        set LIST [split $BUFFER \n]
        # return Result
        return [lindex $LIST $LINENR]
    }

    # check file and parameter, return when failed
    if {![file exist $FILENAME] || ![file readable $FILENAME] || ![string is digit $LINENR]} {return 0}
    # open file
    set FILE [open $FILENAME r]
    if {$METHODE!=1} {
        # use first read method
        set LINE [ReadWithEof $FILE $LINENR]
    } {
        # use second (default) read method
        set LINE [ReadFullAndSplit $FILE $LINENR]
    }
    close $FILE
    return $LINE
}

proc FileDeleteLine {FILENAME LINENR {TOLINENR -1}} {
    if {![file exist $FILENAME] || ![file readable $FILENAME]} {return 0}
    if {![string is digit $LINENR] || ![string is digit $TOLINENR]} {return 0}
    if {$TOLINENR==-1} {set TOLINENR $LINENR}
    # open file and read into a list
    set FILE [open $FILENAME r]
    set LIST [split [read -nonewline $FILE] \n]
    close $FILE
    # remove to lines from list
    set LIST [lreplace $LIST $LINENR $TOLINENR]
    # overwrite file and puts file back
    set FILE [open $FILENAME w]
    puts -nonewline $FILE [join $LIST \n]
    #add new line to the end of file
    #no clue why it deletes the last line
    #and does not add the \n
    puts -nonewline $FILE "\n"
    close $FILE
    return 1
}

proc charfilter {arg} { return [string map {"\\" "\\\\" "\{" "\\\{" "\}" "\\\}" "\[" "\\\[" "\]" "\\\]" "\'" "\\\'" "\"" "\\\""} $arg] }

putlog "===>> Mining-Pool-Basics - Version $scriptversion loaded"
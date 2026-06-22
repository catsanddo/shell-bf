# Notes:
# It is intended that you pass your entire list to these commands so that it can
# parse them directly through the positional params. 
# Example:
#     list='1 2 3 4 5'
#     list-get 2 $list
# This will expand to:
#     list-get 2 1 2 3 4 5
# And will produce an output of '3'.
# This version of the library does not support handling elements with whitespace
# in them or custom delimeters. See list.sh for that.

# Param: idx ...
# Out: ...[idx]
list_get () {
    [ "$1" -lt 0 ] && return 1
    shift $(($1 + 1))
    [ "$#" -le 0 ] && return 1
    echo "$1"
}

# Param: idx val ...
# Out: ... val ...
list_set () {
    local idx val i delim

    idx="$1"
    val="$2"
    shift 2

    [ "$idx" -lt 0 -o "$idx" -ge "$#" ] && echo "$@" && return 1

    i=0
    delim=" "
    for x in "$@"; do
        [ "$i" -eq $((${#} - 1)) ] && delim=''
        [ "$idx" -eq "$i" ] && printf '%s' "$val$delim" || printf '%s' "$x$delim"
        i=$((i+1))
    done
}

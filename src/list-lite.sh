# Notes:
# It is intended that you pass your entire list to these commands so that it can
# parse them directly through the positional params. 
# Example:
#     list='1 2 3 4 5'
#     list-get 2 $list
# This will expand to:
#     list-get 2 1 2 3 4 5
# And will produce an output of '3'. If your list contains elements with spaces,
# you can store it with the element wrapped in quotes, but due to field
# splitting it will split them up into separate words anyway. To avoid this, use
# eval like so:
#     list="a 'b c' d"
#     eval list-get 1 $list
# This will expand to:
#     list-get 1 a 'b c' d
# Which will result in 'b c' being output. If you want to set an element to a
# value containing spaces, all that is required is to double wrap it in quotes
# like so:
#     list-set 1 "'b c'" $list
#
# Using IFS
# The lists described here are based on the default value of IFS. By default, it
# contains the characters space, tab, and newline which means that your elements
# can actually be separated by any of those characters, not just space. You can
# even set IFS yourself to use custom delimeters. This is useful if you want
# elements that contain spaces, but will not some other delimeter.
# Example:
#     IFS=':'
#     list='hello world:goodbye world:how do you do?'
#     list-get 1 $list
# This results in 'goodbye world' being output.
# When using a custom IFS, it is important to tell list-set what delimeter to
# use by setting the list_delimeter variable. You can reset behavior back to the
# defaults by using unset on both IFS and list_delimeter

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
    local idx val i

    idx="$1"
    val="$2"
    shift 2

    [ "$idx" -lt 0 -o "$idx" -ge "$#" ] && echo "$@" && return 1

    i=0
    for x in "$@"; do
        #[ "$idx" -eq "$i" ] && echo -n "$val " || echo -n "$x "
        shift
        [ "$idx" -eq "$i" ] && break
        echo -n "$x${list_delimeter:- }"
        i=$((i+1))
    done
    echo -n "$val"
    [ "$#" -eq 0 ] || echo -n "${list_delimeter:- }"
    echo "$@"
}

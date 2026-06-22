#!/bin/sh

SRC_DIR="$(dirname "$0")"

. "$SRC_DIR/list.sh"
. "$SRC_DIR/string.sh"
. "$SRC_DIR/gap-buffer.sh"
. "$SRC_DIR/util.sh"

tape="0"
tape_head=0
tape_length=1

input_buffer=''
char=''
newline_present=

shift-left () {
    tape_head=$((tape_head - 1))
    if [ "$tape_head" -lt 0 ]; then
        tape="0 $tape"
        tape_head=0
        tape_length=$((tape_length + 1))
    fi
}

shift-right () {
    tape_head=$((tape_head + 1))
    if [ "$tape_head" -ge "$tape_length" ]; then
        tape="$tape 0"
        tape_length=$((tape_length + 1))
    fi
}

read-input () {
    if [ -z "$input_buffer" ] && [ -z "$newline_present" ]; then
        read -r input_buffer || return 1
        newline_present=1
    fi

    [ -z "$input_buffer" ] && [ -n "$newline_present" ] && return
    
    #char="`substr 0 1 "$input_buffer"`"
    #input_buffer=`substr 1 $((${#input_buffer} - 1)) "$input_buffer"`
    char="$(get-char "$input_buffer")"
    input_buffer="${input_buffer#?}"
}

get-instruction () {
    instruction="$buffer_cursor"
    buffer-next || return 1
}

jump-to-close () {
    local depth
    depth=1

    while [ "$depth" -gt 0 ]; do
        [ "$buffer_cursor" = '[' ] && depth=$((depth + 1))
        [ "$buffer_cursor" = ']' ] && depth=$((depth - 1))
        buffer-next || return 1
    done
}

jump-to-open () {
    local depth
    depth=1

    buffer-prev
    while [ "$depth" -gt 0 ]; do
        buffer-prev || return 1
        [ "$buffer_cursor" = ']' ] && depth=$((depth + 1))
        [ "$buffer_cursor" = '[' ] && depth=$((depth - 1))
    done
}

[ "$1" = "-z" ] && DEBUGGER=1 && shift

program="$1"

[ -z "$program" ] && error 'No input program!'
[ -f "$program" ] && program="$(read-program "$program" 3)"
buffer-set "$program"

while get-instruction; do
    if [ -n "$DEBUGGER" ]; then
        foo_pc="${#buffer_lhs}"
        echo "$program"
        pad "$((foo_pc-1))"; echo '^'
        echo "$tape"
        echo "H: $tape_head"
        echo "PC: $foo_pc"
        [ "$instruction" = ',' ] || read -p '> '
    fi
    case $instruction in
        '+')
            cell=`list-get $tape_head $tape`
            cell=$((cell + 1))
            [ "$cell" -gt 255 ] && cell=0
            tape=`list-set $tape_head $cell $tape`
            ;;
        '-')
            cell=`list-get $tape_head $tape`
            cell=$((cell - 1))
            [ "$cell" -lt 0 ] && cell=255
            tape=`list-set $tape_head $cell $tape`
            ;;
        '>')
            shift-right
            ;;
        '<')
            shift-left
            ;;
        '.')
            [ -n "$DEBUGGER" ] && echo -n 'Output: '
            chr "$(list-get $tape_head $tape)"
            [ -n "$DEBUGGER" ] && echo
            ;;
        ',')
            read-input || newline_present=
            if [ -n "$char" ]; then
                tape="$(list-set $tape_head $(ord "$char") $tape)"
                char=
            elif [ -n "$newline_present" ]; then
                tape="$(list-set $tape_head 10 $tape)"
                newline_present=
            else # EOF
                tape="$(list-set $tape_head 0 $tape)"
            fi
            ;;
        '[')
            if [ "`list-get $tape_head $tape`" -eq 0 ]; then
                old_pc="${#buffer_lhs}"
                cached_pc="$(eval echo -n '$'cache_open_"${old_pc}")"
                if [ -z "$cached_pc" ]; then
                    jump-to-close || error "Could not find matching ']'"
                    eval cache_open_"${old_pc}"="${#buffer_lhs}"
                else
                    buffer-goto "$cached_pc"
                fi
            fi
            ;;
        ']')
            old_pc="${#buffer_lhs}"
            cached_pc="$(eval echo -n '$'cache_close_"${old_pc}")"
            if [ -z "$cached_pc" ]; then
                jump-to-open || error "Could not find matching '['"
                eval cache_close_"${old_pc}"="${#buffer_lhs}"
            else
                buffer-goto "$cached_pc"
            fi
            ;;
    esac
done

echo
echo $tape
echo $tape_head

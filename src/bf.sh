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

shift_left () {
    tape_head=$((tape_head - 1))
    if [ "$tape_head" -lt 0 ]; then
        tape="0 $tape"
        tape_head=0
        tape_length=$((tape_length + 1))
    fi
}

shift_right () {
    tape_head=$((tape_head + 1))
    if [ "$tape_head" -ge "$tape_length" ]; then
        tape="$tape 0"
        tape_length=$((tape_length + 1))
    fi
}

read_input () {
    if [ -z "$input_buffer" ] && [ -z "$newline_present" ]; then
        read -r input_buffer || return 1
        newline_present=1
    fi

    [ -z "$input_buffer" ] && [ -n "$newline_present" ] && return
    
    #char="`substr 0 1 "$input_buffer"`"
    #input_buffer=`substr 1 $((${#input_buffer} - 1)) "$input_buffer"`
    char="$(get_char "$input_buffer")"
    input_buffer="${input_buffer#?}"
}

get_instruction () {
    instruction="$buffer_cursor"
    buffer_next || return 1
}

jump_to_close () {
    local depth
    depth=1

    while [ "$depth" -gt 0 ]; do
        [ "$buffer_cursor" = '[' ] && depth=$((depth + 1))
        [ "$buffer_cursor" = ']' ] && depth=$((depth - 1))
        buffer_next || return 1
    done
}

jump_to_open () {
    local depth
    depth=1

    buffer_prev
    while [ "$depth" -gt 0 ]; do
        buffer_prev || return 1
        [ "$buffer_cursor" = ']' ] && depth=$((depth + 1))
        [ "$buffer_cursor" = '[' ] && depth=$((depth - 1))
    done
}

[ "$1" = "-z" ] && DEBUGGER=1 && shift

program="$1"

[ -z "$program" ] && error 'No input program!'
[ -f "$program" ] && program="$(read_program "$program" 3)"
buffer_set "$program"

while get_instruction; do
    if [ -n "$DEBUGGER" ]; then
        foo_pc="${#buffer_lhs}"
        echo "$program"
        pad "$((foo_pc-1))"; echo '^'
        echo "$tape"
        echo "H: $tape_head"
        echo "PC: $foo_pc"
        [ "$instruction" = ',' ] || read -p 'Press RETURN to continue> '
    fi
    case $instruction in
        '+')
            cell=`list_get $tape_head $tape`
            cell=$((cell + 1))
            [ "$cell" -gt 255 ] && cell=0
            tape=`list_set $tape_head $cell $tape`
            ;;
        '-')
            cell=`list_get $tape_head $tape`
            cell=$((cell - 1))
            [ "$cell" -lt 0 ] && cell=255
            tape=`list_set $tape_head $cell $tape`
            ;;
        '>')
            shift_right
            ;;
        '<')
            shift_left
            ;;
        '.')
            [ -n "$DEBUGGER" ] && printf '%s' 'Output: '
            chr "$(list_get $tape_head $tape)"
            [ -n "$DEBUGGER" ] && echo
            ;;
        ',')
            read_input || newline_present=
            if [ -n "$char" ]; then
                tape="$(list_set $tape_head $(ord "$char") $tape)"
                char=
            elif [ -n "$newline_present" ]; then
                tape="$(list_set $tape_head 10 $tape)"
                newline_present=
            else # EOF
                tape="$(list_set $tape_head 0 $tape)"
            fi
            ;;
        '[')
            if [ "`list_get $tape_head $tape`" -eq 0 ]; then
                old_pc="${#buffer_lhs}"
                cached_pc="$(eval printf \'%s\' '$'cache_open_"${old_pc}")"
                if [ -z "$cached_pc" ]; then
                    jump_to_close || error "Could not find matching ']'"
                    eval cache_open_"${old_pc}"="${#buffer_lhs}"
                else
                    buffer_goto "$cached_pc"
                fi
            fi
            ;;
        ']')
            old_pc="${#buffer_lhs}"
            cached_pc="$(eval printf \'%s\' '$'cache_close_"${old_pc}")"
            if [ -z "$cached_pc" ]; then
                jump_to_open || error "Could not find matching '['"
                eval cache_close_"${old_pc}"="${#buffer_lhs}"
            else
                buffer_goto "$cached_pc"
            fi
            ;;
    esac
done

echo
echo "Tape: $tape"
echo "Tape head: $tape_head"

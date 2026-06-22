# Instead of storing the pc as one continous string, and then seeking through it
# all the time with substr (slow!), what if we store it as a sort of gap buffer.
# It would be stored in two variables buffer_lhs and buffer_rhs. Because we only
# every move by one character at a time in the buffer, we can just do so from
# the middle of the buffer. Basically advancing the buffer to get the next
# instruction goes from (start at beginning of buffer, slowly look at each char
# in the buffer $pc times, discard the rest of the buffer and keep the remaining
# char) to (start at $pc where we left off, get the first char, append it to
# buffer_lhs, shift buffer_rhs over). I think this method will be more
# performant.
# Looping and seeking for the matching bracket might get a little more
# complicated, but it shouldn't be by much. I also don't forsee any real
# performace issues cropping up for looping. It may even improve, but this
# requires testing.

buffer_lhs=''
buffer_rhs=''
buffer_cursor=''

# Params: new_buffer
buffer-set () {
    buffer_lhs=''
    buffer_rhs="$1"
    buffer_cursor="$(printf '%c' "$1")"
}

# Effect: shift one character from rhs to lhs buffer
buffer-next () {
    [ -z "$buffer_rhs" ] && return 1
    buffer_lhs="$buffer_lhs$buffer_cursor"
    buffer_rhs="${buffer_rhs#?}"
    buffer_cursor="$(printf '%c' "$buffer_rhs")"
}

# Effect: shift one character from lhs to rhs buffer
buffer-prev () {
    [ -z "$buffer_lhs" ] && return 1
    buffer_cursor="${buffer_lhs#"${buffer_lhs%?}"}"
    buffer_lhs="${buffer_lhs%?}"
    buffer_rhs="$buffer_cursor$buffer_rhs"
}

# Param: idx
# Effect: place the first idx bytes of the buffer into lhs, and the remaining
#         bytes into rhs
buffer-goto () {
    [ "$1" -lt 0 ] && set -- 0
    [ "$1" -gt $((${#buffer_lhs} + ${#buffer_rhs})) ] && \
        set -- "$((${#buffer_lhs} + ${#buffer_rhs}))"
    while [ "$1" -lt "${#buffer_lhs}" ]; do
        buffer-prev
    done
    while [ "$1" -gt "${#buffer_lhs}" ]; do
        buffer-next
    done
}

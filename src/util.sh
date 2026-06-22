# Param: count
# Out: ' '*count
pad () {
    local i
    i=0
    while [ "$i" -lt "$1" ]; do
        echo -n ' '
        i=$((i+1))
    done
}

# Param: msg
# Err: msg
error () {
    echo "$1" >&2
    exit 1
}

# Param: path fd
# Out: program
read-program () {
    local line char
    eval exec "${2:-3}"'<' '"$1"'

    while read -r line <&3; do
        while [ -n "$line" ]; do
            char="${line%"${line#?}"}"
            line="${line#?}"

            case "$char" in
                +|-|'<'|'>'|'['|']'|,|.)
                    echo -n "$char"
                    ;;
            esac
        done
    done

    eval exec "$2"'<&-'
}

# Param: path fd
# Out: file_contents
read-file () {
    local line ifs
    eval exec "$2"'<' '"$1"'
    ifs="$IFS"
    IFS=
    while read -r line <&3; do
        echo "$line"
    done
    IFS="$ifs"
}

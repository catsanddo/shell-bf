# Param: idx len str
# Out: str[idx:len]
substr () {
    local ifs i idx len str result
    ifs="$IFS"
    IFS=
    idx="$1"
    len="$2"
    str="$3"

    i=0
    while [ "$i" -lt "$idx" ]; do
        str="${str#?}"
        i=$((i+1))
    done

    i=0
    result=''
    while [ "$i" -lt "$len" ]; do
        foo=${str%"${str#?}"}
        result="$result$foo"
        str="${str#?}"
        i=$((i+1))
    done

    printf '%s' "$result"
    IFS="$ifs"
}

# Param: string
# Out: string[1:]
pop_char () {
    echo "${1#?}"
}

# Param: string
# Out: string[0]
get_char () {
    echo "${1%"${1#?}"}"
}

# Param: code
# Out: ascii representation of code
chr () {
    printf '%b' "$(printf '\%03o' "$1")"
}

# Param: char
# Out: ascii value of char
ord () {
    printf '%d' "'$1"
}

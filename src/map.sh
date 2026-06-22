# Some documentation of the map library is demanded to justify the soup of
# evals found below and to save people (and myself) the trouble of deciphering
# what it is trying to do. The core of the implementation is the idea that we
# can store namespaced key-value pairs just as regular shell variables in the
# form {namespace}__{key}.
# To give an example, let's say we want to store the pair NY='New York City'
# in a map called state_capitals. We could do this as easily as
# state_captitals__NY='New York City'. If we wanted to add another pair to the
# same map, we could do state_capitals__CA='Sacramento'. Retrieving the value
# is as easy as "$state_capitals__NY". It's easy to do this by hand, but what
# about when you want to have dynamic map names and keys? That's what the mess
# of eval statements is for. Each one just handles some access to or setting of
# these dynamically created variables. Additionally, the variable {namespace}
# is maintained with a space-separated list of all keys so that the map can
# easily be iterated over or deleted programatically.
#
# TL;DR / Notes
# - map entries are actually stored as global shell variables of the form
#   {map_name}__{key} with the value of {value}
# - another variable {map_name} contains a space-separated list of all the
#   keys in the map
# - it will pollute the global variable namespace somewhat, but maps can be
#   unset all at once by calling the map-delete shell function on them

# Param: map_name key
# Out: value
map_get () {
    eval echo -n '$'"$1"__"$2"
}

# Param: map_name key value
map_set () {
    local key is_key_found
    is_key_found=
    for key in `eval echo -n '"$'"$1"'"'`; do
        [ "$key" = "$2" ] && is_key_found=1
    done
    [ -z "$is_key_found" ] && eval "$1"='"$'"$1"' $2"'
    eval "$1"__"$2"="'"$3"'"
}

# Param: map_name
map_delete () {
    local key
    for key in `eval echo -n '"$'"$1"'"'`; do
        eval unset "$1"__"$key"
    done
    eval unset "$1"
}

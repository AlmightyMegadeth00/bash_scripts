# some useful functions to help make things easier

# move to the source root
function croot()
{
    T=$(gettop)
    if [ "$T" ]; then
        \cd $(gettop)
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

# move to the directory of a file
function godir () {
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    T=$(gettop)
    if [[ ! -f $T/filelist ]]; then
        echo -n "Creating index..."
        (\cd $T; find . -wholename ./out -prune -o -wholename ./.repo -prune -o -type f > filelist)
        echo " Done"
        echo ""
    fi
    local lines
    lines=($(\grep "$1" $T/filelist | sed -e 's/\/[^/]*$//' | sort | uniq))
    if [[ ${#lines[@]} = 0 ]]; then
        echo "Not found"
        return
    fi
    local pathname
    local choice
    if [[ ${#lines[@]} > 1 ]]; then
        while [[ -z "$pathname" ]]; do
            local index=1
            local line
            for line in ${lines[@]}; do
                printf "%6s %s\n" "[$index]" $line
                index=$(($index + 1))
            done
            echo
            echo -n "Select one: "
            unset choice
            read choice
            if [[ $choice -gt ${#lines[@]} || $choice -lt 1 ]]; then
                echo "Invalid choice"
                continue
            fi
            pathname=${lines[$(($choice-1))]}
        done
    else
        pathname=${lines[0]}
    fi
    \cd $T/$pathname
}

# grep through makefiles
function mgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk|.*\.cmake|.\/CMakeLists.txt)' -type f -print0 | xargs -0 grep --color -n "$@"
}

# grep through C/C++ classes
function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

# grep through java classes
function jgrep()
{
    find . -name .repo -prune -o -name .git -prune -o  -type f -name "*\.java" -print0 | xargs -0 grep --color -n "$@"
}

# grep through resource classes
function resgrep()
{
    #if we're in a subdir of res, than don't try to find a res directory below us.
    [ `pwd | grep '/res' | wc -l` -gt 0 ] && find . -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@" && return 0
    
    #if not, assume it's below our folder
    foundone=
    for dir in `find . -name .repo -prune -o -name .git -prune -o -name res -type d`; do find $dir -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"; done;
    [ ! -z $foundone ] && return 0

    #if res isn't our parent, and we're not in a parent of res, then res is probably our uncle.
    pushd . >& /dev/null
    T=$(gettop)
    reldir=""
    while [ 1 ]; do
        if [ -d res ]; then
            popd >& /dev/null
            find ${reldir}res -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"
            foundone=1
            return 0
        elif [ "`pwd`" = "$T" ] || [ "`pwd`" = "/" ]; then
            foundone=1
            popd >& /dev/null
            return 1
        fi
        reldir="$reldir../"
        cd ..
    done
}

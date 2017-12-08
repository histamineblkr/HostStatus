BEGIN {
    FS=" "
    RS="\n"
}
{
    if ($1 ~ /^#/) {
        print $0
    }
    else {
        print $1, $2
    }
}

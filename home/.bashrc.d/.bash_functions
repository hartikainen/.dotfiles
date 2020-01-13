#!/bin/bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Create data URI from a file.

disk-usage() {

    set -x
    local folder=""
    [ -z "${1}" ] && folder="/home/"
    sudo du -h -d 1 -t 1G "${folder}" | sort -hr
    set +x

}

disk-free() {

    set -x
    df -h | sort -hr
    set +x

}

github-clone() {

    # https://github.com/rail-berkeley/softlearning.git

    [ -z "${1}" ] && printf "Usage: '%s', e.g. '%s'.\n" \
                            "github-clone [repositoty-path]" \
                            "github-clone rail-berkeley/softlearning"

    local repository_url="${1}"

    local left_trimmed_url="${repository_url##git@github.com:}"
    local trimmed_url="${left_trimmed_url%.git*}"
    local repository_name="$(basename "${trimmed_url}")"
    local user_name="$(basename "${trimmed_url%/${repository_name}}")"

    if [ -z "${repository_name}" ] || [ -z "${user_name}" ]; then
        printf "Incorrect arguments: '${1}'. Usage: '%s', e.g. '%s'.\n" \
               "github-clone [repositoty-path]" \
               "github-clone rail-berkeley/softlearning"
        return
    fi

    local repositories_dir="${HOME}/github"
    local user_dir="${repositories_dir}/${user_name}"
    local repository_dir="${user_dir}/${repository_name}"

    [ -d "${repository_dir}" ] \
        && printf "Already exists: %s (at %s)\n" \
                  "${repository_url}" \
                  "${repository_dir}" \
        && return


    git clone "${repository_url}" "${repository_dir}"

}

datauri() {

    local mimeType=""

    if [ -f "$1" ]; then
        mimeType=$(file -b --mime-type "$1")
        #                └─ do not prepend the filename to the output

        if [[ $mimeType == text/* ]]; then
            mimeType="$mimeType;charset=utf-8"
        fi

        printf "data:%s;base64,%s" \
                    "$mimeType" \
                    "$(openssl base64 -in "$1" | tr -d "\n")"
    else
        printf "%s is not a file.\n" "$1"
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Delete files that match a certain pattern from the current directory.

delete-files() {
    local q="${1:-*.DS_Store}"
    find . -type f -name "$q" -ls -delete
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Get gzip information (gzipped file size + reduction size).

gz() {

    declare -i gzippedSize=0
    declare -i originalSize=0

    if [ -f "$1" ]; then
        if [ -s "$1" ]; then

            originalSize=$( wc -c < "$1" )
            printf "\n original size:   %12s\n" "$(hrfs "$originalSize")"

            gzippedSize=$( gzip -c "$1" | wc -c )
            printf " gzipped size:    %12s\n" "$(hrfs "$gzippedSize")"

            printf " ─────────────────────────────\n"
            printf " reduction:       %12s [%s%%]\n\n" \
                        "$( hrfs $((originalSize - gzippedSize)) )" \
                        "$( printf "%s" "$originalSize $gzippedSize" | \
                            awk '{ printf "%.1f", 100 - $2 * 100 / $1 }' | \
                            sed -e "s/0*$//;s/\.$//" )"
                            #              └─ remove tailing zeros

        else
            printf "\"%s\" is empty.\n" "$1"
        fi
    else
        printf "\"%s\" is not a file.\n" "$1"
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Human readable file size
# (because `du -h` doesn't cut it for me).

hrfs() {

    printf "%s" "$1" |
    awk '{
            i = 1;
            split("B KB MB GB TB PB EB ZB YB WTFB", v);
            value = $1;

            # confirm that the input is a number
            if ( value + .0 == value ) {

                while ( value >= 1024 ) {
                    value/=1024;
                    i++;
                }

                if ( value == int(value) ) {
                    printf "%d %s", value, v[i]
                } else {
                    printf "%.1f %s", value, v[i]
                }

            }
        }' |
    sed -e ":l" \
        -e "s/\([0-9]\)\([0-9]\{3\}\)/\1,\2/; t l"
    #    └─ add thousands separator
    #       (changes "1023.2 KB" to "1,023.2 KB")
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Create new directories and enter the first one.

mkd() {
    if [ -n "$*" ]; then

        mkdir -p "$@"
        #      └─ make parent directories if needed

        cd "$@" \
            || exit 1

    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Process phone photo.

ppp() {

    # Check if ImageMagick's convert command-line tool is installed.

    if ! command -v "convert" $> /dev/null; then
        printf "Please install ImageMagick's 'convert' command-line tool!"
        exit;
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    declare option="$1"
    declare photo="${2:-*.jpg}"
    declare geometry="${3:-50%}"

    if [ "$option" != "clean" ] &&
       [ "$option" != "resize" ]; then
        option="resize"
        photo="${1:-*.jpg}"
        geometry="${2:-50%}"
    fi

    if [[ "$(echo "${photo##*.}" | tr '[:upper:]' '[:lower:]')" != "png" ]]; then
        newPhotoName="${photo%.*}.png"
    else
        newPhotoName="_${photo%.*}.png"
    fi

    if [ "$option" == "resize" ]; then
        convert "$photo" \
            -colorspace RGB \
            +sigmoidal-contrast 11.6933 \
            -define filter:filter=Sinc \
            -define filter:window=Jinc \
            -define filter:lobes=3 \
            -sigmoidal-contrast 11.6933 \
            -colorspace sRGB \
            -background transparent \
            -gravity center \
            -resize "$geometry" \
            +append \
            "$newPhotoName" \
        && printf "* %s (%s)\n" \
            "$newPhotoName" \
            "$geometry"

        return
    fi

    convert "$photo" \
        -morphology Convolve DoG:10,10,0 \
        -negate \
        -normalize \
        -blur 0x1 \
        -channel RBG \
        -level 10%,91%,0.1 \
        "$newPhotoName" \
        && printf "* %s\n" "$newPhotoName"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Search history.

qh() {
    #           ┌─ enable colors for pipe
    #           │  ("--color=auto" enables colors only if
    #           │  the output is in the terminal)
    grep --color=always "$*" "$HISTFILE" |       less -RX
    # display ANSI color escape sequences in raw form ─┘│
    #       don't clear the screen after quitting less ─┘
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Search for text within the current directory.

qt() {
    grep -ir --color=always "$*" --exclude-dir=".git" --exclude-dir="node_modules" . | less -RX
    #     │└─ search all files under each directory, recursively
    #     └─ ignore case
}

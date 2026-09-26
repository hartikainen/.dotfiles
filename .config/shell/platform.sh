#!/bin/sh

get_os_name() {
    case "$(uname -s)" in
        Darwin) printf '%s' macos ;;
        Linux)
            if [ -r /etc/os-release ]; then
                (
                    . /etc/os-release
                    printf '%s' "$ID"
                )
            else
                printf '%s' linux
            fi
            ;;
        *) uname -s ;;
    esac
}

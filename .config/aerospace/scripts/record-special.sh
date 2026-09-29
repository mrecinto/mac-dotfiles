#!/bin/bash

workspace="$1"

case "$workspace" in
    W|A|S|D|I|O)
        echo "$workspace" > "/tmp/aerospace-last-special-$USER"
        ;;
esac

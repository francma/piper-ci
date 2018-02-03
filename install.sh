#!/bin/sh

set -eu

printf "Checking prerequisies...\n"
printf "Checking LXD... "
if [ $? -eq 127 ]; then
	printf "LXD is not installed\n"
	exit 1
else
	printf "OK\n"
fi

printf "Creating new piper user"
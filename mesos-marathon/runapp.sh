#!/bin/bash
if [ "$#" -ne 1 ]
then
    echo "You have to input one json file"
    exit 1;
fi
curl -X POST -H 'Content-Type: application/json' -d@"$@" 192.168.0.33:8080/v2/apps

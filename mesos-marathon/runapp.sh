#!/bin/bash
curl -i -H 'Content-Type: application/json' -d@"$1" 192.168.0.33:8080/v2/apps

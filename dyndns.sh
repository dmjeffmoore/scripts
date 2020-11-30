#!/bin/bash

curl "https://dynamicdns.park-your-domain.com/update?host=@&domain=[your-domain]&password=[dynamic-dns-password]&ip=$(dig +short myip.opendns.com @resolver1.opendns.com)"

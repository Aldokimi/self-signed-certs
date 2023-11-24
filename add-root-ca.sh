#!/bin/bash

echo ">>>(add-root-ca)<<<"
echo ">>>(add-root-ca)-> Adding root CA to the Operating system ..."
cp /etc/ssl/rootCA.crt /usr/local/share/ca-certificates/
update-ca-certificates


echo ">>>(add-root-ca)-> Adding root CA to FireFox"
firefox-profile="~/.mozilla/firefox/myRootCA.default"
certutil -d ${firefox-profile} -A -n "My Root CA" -t "TCu,Cu,Tuw" -i /etc/ssl/rootCA.crt
pkill firefox

echo ">>>(add-root-ca)-> Done saving root CA!"

#!/bin/bash
echo ">>>(self-signed-ca)<<<"
if [ "$#" -ne 1 ]
then
  echo ">>>(self-signed-ca)-> Error: No domain name argument provided"
  echo ">>>(self-signed-ca)-> Usage: Provide a domain name as an argument"
  exit 1
fi

DOMAIN=$1

mkdir /tmp/self-signed-ca/

# Create root CA & Private key
echo ">>>(self-signed-ca)-> Create root CA & Private key for the self-signed service..."
openssl req -x509 \
            -sha256 -days 356 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=${DOMAIN}/C=HU/L=Budapest" \
            -keyout /tmp/self-signed-ca/rootCA.key \
            -out /tmp/self-signed-ca/rootCA.crt

# Generate Private key 
openssl genrsa -out /tmp/self-signed-ca/${DOMAIN}.key 2048

# Create csf conf
echo ">>>(self-signed-ca)-> Create a certificate signing request configuration..."
cat > /tmp/self-signed-ca/csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = HU
ST = Budapest
L = Budapest
CN = ${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
DNS.2 = www.${DOMAIN}
IP.1 = 192.168.1.5 
IP.2 = 192.168.1.6

EOF

# create CSR request using private key
echo ">>>(self-signed-ca)-> Create a CSR..."
openssl req -new -key /tmp/self-signed-ca/${DOMAIN}.key \
            -out /tmp/self-signed-ca/${DOMAIN}.csr -config /tmp/self-signed-ca/csr.conf

# Create a external config file for the certificate
echo ">>>(self-signed-ca)-> Create a external config file for the certificate..."
cat > /tmp/self-signed-ca/cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}

EOF

# Create SSl with self signed CA
echo ">>>(self-signed-ca)-> Generate SSl certificate with self signed CA..."
openssl x509 -req \
    -in /tmp/self-signed-ca/${DOMAIN}.csr \
    -CA /tmp/self-signed-ca/rootCA.crt \
    -CAkey /tmp/self-signed-ca/rootCA.key \
    -CAcreateserial \
    -out /tmp/self-signed-ca/${DOMAIN}.crt \
    -days 365 \
    -sha256 -extfile /tmp/self-signed-ca/cert.conf

# Copy server cert and key to /etc/ssl/
cp /tmp/self-signed-ca/${DOMAIN}.crt /etc/ssl/${DOMAIN}.crt
cp /tmp/self-signed-ca/${DOMAIN}.key /etc/ssl/${DOMAIN}.key

echo ">>>(self-signed-ca)-> Done creating self singed CA & generating a self signed certificate"

#!/bin/bash

# Generate a private key
openssl genpkey -algorithm RSA -out test_key.pem

# Generate a self-signed certificate
openssl req -x509 -new -key test_key.pem -out test_cert.pem -days 3650

# Make sure the certificate file is readable
chmod 644 test_cert.pem

echo "Certificate generation completed. Certificate and private key are in /etc/ssl/certs and /etc/ssl/private respectively."


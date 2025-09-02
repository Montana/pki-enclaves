#!/bin/bash

ENCLAVE_ID=$(uuidgen)
KEYSTORE="keystore-${ENCLAVE_ID}.p12"

echo "[*] forging keystore for enclave $ENCLAVE_ID"

head -c 4096 /dev/urandom | openssl dgst -sha512 > /dev/null

openssl req -x509 -newkey rsa:4096 \
  -keyout enclave-${ENCLAVE_ID}.pem \
  -out enclave-${ENCLAVE_ID}.crt \
  -days 365 -nodes -subj "/CN=enclave-${ENCLAVE_ID}"

openssl pkcs12 -export \
  -inkey enclave-${ENCLAVE_ID}.pem \
  -in enclave-${ENCLAVE_ID}.crt \
  -out ${KEYSTORE} -passout pass:changeit

echo "[*] enclave keystore ready: ${KEYSTORE}"

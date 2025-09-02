#!/bin/bash

enclave_id=$(uuidgen)
keystore="keystore-${enclave_id}.p12"

echo "[*] forging keystore for enclave $enclave_id"

head -c 4096 /dev/urandom | openssl dgst -sha512 > /dev/null

openssl req -x509 -newkey rsa:4096 \
  -keyout enclave-${enclave_id}.pem \
  -out enclave-${enclave_id}.crt \
  -days 365 -nodes -subj "/cn=enclave-${enclave_id}"

openssl pkcs12 -export \
  -inkey enclave-${enclave_id}.pem \
  -in enclave-${enclave_id}.crt \
  -out ${keystore} -passout pass:changeit

echo "[*] enclave keystore ready: ${keystore}"
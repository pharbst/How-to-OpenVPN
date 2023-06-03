#!/bin/bash

File1="root_CA"
File2="intermediate_CA"
File3="server"
File4="client"

echo -e "\033[0;32mCreating Private keys\033[0m"
openssl genpkey -algorithm RSA -out $File1.key -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out $File2.key -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out $File3.key -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out $File4.key -pkeyopt rsa_keygen_bits:4096

echo -e "\033[0;32mCreating Certificate Signing Requests and $File1.crt\033[0m"
echo -e "\033[1;33mPlease fill in the details for $File1.key\033[0m"
openssl req -x509 -new -nodes -key $File1.key -sha256 -days 365 -out $File1.crt
echo -e "\033[1;33mPlease fill in the details for $File2$csr\033[0m"
openssl req -new -nodes -key $File2.key -sha256 -days 365 -out $File2.csr
echo -e "\033[1;33mPlease fill in the details for $File3.csr\033[0m"
openssl req -new -nodes -key $File3.key -sha256 -days 365 -out $File3.csr
echo -e "\033[1;33mPlease fill in the details for $File4.csr\033[0m"
openssl req -new -nodes -key $File4.key -sha256 -days 365 -out $File4.csr

echo -e "\033[0;32mSigning Certificates\033[0m"
openssl x509 -req -in $File2.csr -CA $File1.crt -CAkey $File1.key -CAcreateserial -out $File2.crt -days 365 -sha256
openssl x509 -req -in $File3.csr -CA $File2.crt -CAkey $File2.key -CAcreateserial -out $File3.crt -days 365 -sha256
openssl x509 -req -in $File4.csr -CA $File2.crt -CAkey $File2.key -CAcreateserial -out $File4.crt -days 365 -sha256

echo -e "\033[0;32mCreating Diffie-Hellman parameters\033[0m"
openssl dhparam -out dhparam.pem 4096

echo -e "\033[0;32mCreating .pem file\033[0m"
cat $File2.crt $File1.crt > trustchain.pem

echo -e "\033[1;32mDone\033[0m"

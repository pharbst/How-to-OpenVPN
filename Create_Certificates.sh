#!/bin/bash
echo -e "\033[0;32m"
echo "Creating Private keys"
echo -e "\033[0m"
openssl genpkey -algorithm RSA -out root_private.key -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out intermediate_private.key -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out server_private.key -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out client_private.key -pkeyopt rsa_keygen_bits:4096

echo -e "\033[0;32m"
echo "Creating Certificate Signing Requests and root_CA.crt"
echo -e "\033[0m"
echo -e "\033[1;33m"
echo "Please fill in the details for root_CA.crt"
echo -e "\033[0m"
openssl req -x509 -new -nodes -key root_private.key -sha256 -days 365 -out root_CA.crt
echo -e "\033[1;33m"
echo "Please fill in the details for intermediate_CA.csr"
echo -e "\033[0m"
openssl req -x509 -new -nodes -key intermediate_private.key -sha256 -days 365 -out intermediate_CA.csr
echo -e "\033[1;33m"
echo "Please fill in the details for server.csr"
echo -e "\033[0m"
openssl req -x509 -new -nodes -key server_private.key -sha256 -days 365 -out server.csr
echo -e "\033[1;33m"
echo "Please fill in the details for client.csr"
echo -e "\033[0m"
openssl req -x509 -new -nodes -key client_private.key -sha256 -days 365 -out client.csr

echo -e "\033[0;32m"
echo "Signing Certificates"
echo -e "\033[0m"
openssl x509 -req -in intermediate_CA.csr -CA root_CA.crt -CAkey root_private.key -CAcreateserial -out intermediate_CA.crt -days 365 -sha256
openssl x509 -req -in server.csr -CA intermediate_CA.crt -CAkey intermediate_private.key -CAcreateserial -out server.crt -days 365 -sha256
openssl x509 -req -in client.csr -CA intermediate_CA.crt -CAkey intermediate_private.key -CAcreateserial -out client.crt -days 365 -sha256
echo -e "\033[1;32m"
echo "Done"
echo -e "\033[0m"

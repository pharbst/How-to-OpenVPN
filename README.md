# VPN
### ⚠️ pls dont use any certificates provided in this repo cause since the private keys comeing with it, it's absolutely not save  
this is my repo with all the nesessary files to set up a openvpn server but all the files are just for testing purpose and wont be used in real serverapplications  
    

##### 1.0 [SSL Certificates](#SSL-certificates)  
###### &emsp;&emsp;1.1 [Create SSL Certificates](#create-SSL-certificates)  
###### &emsp;&emsp;1.2 [Add CA's on Windows](#add-CAs-to-trusted-store-on-Windows)  
###### &emsp;&emsp;1.3 [Add Ca's on Linux](#add-CAs-to-trusted-store-on-Linux)  
##### 3.0 [OpvenVPN](#OpenVPN)  
###### &emsp;&emsp;3.1 [OpenVPN server.conf](#Openvpn-server.conf)  
###### &emsp;&emsp;3.2 [Create OpenVPN Service](#Openvpn-Service)  
###### &emsp;&emsp;3.3 [Clients](#Clients)  
##### 4.0 [Clear the Path](#clear-the-path)  
###### &emsp;&emsp;4.1 [Firewall](#Firewall)  
###### &emsp;&emsp;4.2 [Portforwarding](#Portforwarding)  
###### &emsp;&emsp;4.3 [Portmapping Server](#Portmapping-server)  


## SSL Certificates
SSL which stands for Secure Soket Layer is a method to create a secure communication between the server and the client with the so called handshake  
during the handshake the client sends its client certificate to the server and the server sends its server certificate to the client  
both will now check if the certificate they just recieved is signed by one of the trusted CA or certificate authoritys in their trusted CA store  
the certificates provide some information who they pretend to be and also a public key to encrypt data but only encrypt the decyption is done with the private key that the server has and the client has also its own private key  


## Create SSL Certificates
we need at least 4 private keys and certificates  
2 of them will be certificate authoritys and the other two are for the server and a client  
&emsp;&emsp;root_CA.crt  
&emsp;&emsp;intermediate_CA.crt  
&emsp;&emsp;server.crt  
&emsp;&emsp;client.crt  
these are the certificates we wanna create  
the root_ca is a certificate authority to create certificates and also certificate authoritys  
the intermediate could also create certificate authoritys but is mainly used to create client and server certificates  
every certificate needs a private key to work this privat key should be always kept save and never be shared  
to create our root_ca.crt we first need to create a privat key which is the root of our selfsigned trustchain so store is save maybe offline on a seperate harddrive or thumbstick  
&emsp;&emsp;but be aware that thumbdrives looses their data when left unplugged for several years even hard drives loose data after 10 years without power  
```bash
openssl genpkey -algorithm RSA -out private_key.key -pkeyopt rsa_keygen_bits:4096
```
this command will create a private key with the rsa algo and a keylength of 4096 bits
```bash
openssl genpkey -algorithm RSA -out private_key.key
```
this will create a private key with the normal keylength of 256bits
```bash
-algorithm RSA
```
this is for setting the algorithm with which the key should be generated  
so for me i wanna have it save and i will create all my keys with a length of 4096 bits  
  
you can create directly 4 keys than you have the keys you need one of them is the key for the root CA the second one is the key for the intermediate CA  
the 3rd for the server and the 4th for the client  

to create the root_CA.crt we can use this command  
```bash
openssl req -x509 -new -nodes -key private_key.key -sha256 -days 365 -out root_CA.crt
```
of course you need to adjust the private key variable and you can name the output certificate as you want and the ```-days``` can be set to the wanted value as well  

so now we have our root_CA.crt  

next step is to create the intermediate CA wihich has to be signed by our root_CA and root_private key

```bash
openssl req -new -key intermediate_private_key.key -out intermediate.csr
```
this will create a signing request file with the csr file extention  
```bash
openssl x509 -req -in intermediate.csr -CA root_CA.crt -CAkey root_private_key.key -CAcreateserial -out intermediate_ca.crt -days 365 -sha256
```
this will sign the request and creates the new intermediate certificate authority  

for the server certificate it will be the same procedure  
```bash
openssl req -new -key server_private.key -out server.csr
openssl x509 -req -in server.csr -CA intermediate_CA.crt -CAkey intermediate_private.key -CAcreateserial -out server.crt -days 365 -sha256
```
and for the client as well
```bash
openssl req -new -key client_private.key -out client.csr
openssl x509 -req -in client.csr -CA intermediate_CA.crt -CAkey intermediate_private.key -CAcreateserial -out client.crt -days 365 -sha256
```

all additional clients should get their own certificate and private key to ensure security  
  
  
## How to add a CA to the trusted CA store for Windows and Linux


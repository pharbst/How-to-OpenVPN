# How To OpenVPN
### ⚠️ pls dont use any certificates provided in this repo cause since the private keys are comming with it, it's absolutely not save  
This is an introduction for setting up an OpenVPN server step by step  
    

##### 1.0 [SSL Certificates](#SSL-certificates)  
###### &emsp;1.1 [Create SSL Certificates](#create-SSL-certificates)  
###### &emsp;1.2 [Add CA's on Windows](#add-CAs-to-trusted-store-on-Windows)  
###### &emsp;1.3 [Add Ca's on Linux](#add-CAs-to-trusted-store-on-Linux)  
###### &emsp;&emsp;1.3.1 [Arch and RedHat](#Arch-and-RedHat)
###### &emsp;&emsp;1.3.2 [Debian](#Debian)
##### 2.0 [OpvenVPN](#OpenVPN)  
###### &emsp;2.1 [OpenVPN server config](#OpenVPN-server-config)  
###### &emsp;2.2 [Create OpenVPN Service](#Openvpn-Service)  
###### &emsp;2.3 [Clients](#Clients)  
##### 3.0 [Clear the Path](#clear-the-path)  
###### &emsp;3.1 [Firewall](#Firewall)  
###### &emsp;3.2 [Portforwarding](#Portforwarding)  
###### &emsp;3.3 [Portmapping Server](#Portmapping-server)  




## SSL Certificates
SSL (Secure Socket Layer) is a widely used protocol for establishing a secure communication channel between a server and a client. It stands for Secure Socket Layer. SSL is primarily used to ensure the confidentiality, integrity, and authenticity of data transmitted over the internet.

In simple terms, SSL works as follows: when a client and a server initiate a connection, they exchange digital certificates. The client sends its certificate to the server, and the server sends its certificate to the client. Both the client and server verify these certificates against trusted Certificate Authorities (CAs) stored on their systems.

The certificates contain important information about the entity they represent and include a public key. This public key is used to encrypt data during transmission. Only the corresponding private key, held by the server or the client, can decrypt the encrypted data.

By confirming the certificates with trusted CAs and utilizing encryption with public keys, SSL ensures that the communication between the client and server is secure and protected from unauthorized access or tampering.

This encryption and decryption process allows sensitive information, such as login credentials or financial data, to be transmitted securely over the internet, providing users with peace of mind and protecting their data from potential threats.



### Create SSL Certificates
To establish a secure SSL connection, we need four private keys and certificates. Two of them will serve as Certificate Authorities (CAs), while the other two will be used for the server and client respectively. Here are the certificates we aim to create:

	`root_CA.crt`			: This is the root CA certificate, which acts as a trusted authority to create certificates and other CAs.
	`intermediate_CA.crt`	: The intermediate CA certificate can also create certificates and CAs. It is primarily used to generate client and server certificates.
	`server.crt`			: The server certificate is specific to the server and will be used to establish its identity during SSL communication.
	`client.crt`			: The client certificate is specific to the client and will be used to verify its identity during SSL communication.
It's important to note that every certificate requires a private key, which should be kept confidential and never shared. Now let's walk through the process of creating these certificates
```bash
openssl genpkey -algorithm RSA -out private_key.key -pkeyopt rsa_keygen_bits:4096
```
this command will create a private key with the rsa algo and a keylength of 4096 bits
```bash
openssl genpkey -algorithm RSA -out private_key.key
```
this will create a private key with the normal keylength of 2048bits
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




### Add CA's to trusted store on Windows
for Windows we just need the intermediate_CA.crt  
press "Windows key" and search for Manage user certificates  

In the ```Certificates - Current User``` window, navigate to the ```Trusted Root Certification Authorities``` folder in the left-hand pane  
Right-click on the ```Trusted Root Certification Authorities``` folder and select ```All Tasks``` -> ```Import```  
The Certificate Import Wizard will open. Click ```Next``` to proceed  
Click the ```Browse``` button and locate the ```intermediate_CA.crt``` that you want to add to the trust store. Select the file and click ```Open```  
Click ```Next``` to continue  
In the next window, choose the option ```Place all certificates in the following store``` and click the ```Browse``` button  
In the ```Select Certificate Store``` window, choose ```Trusted Root Certification Authorities``` and click ```OK```  
Click ```Next``` to proceed  
Review the summary information and click ```Finish``` to complete the import process  
You should see a confirmation message indicating that the certificate was imported successfully. Click ```OK``` to close the wizard  
the last massage is just to ensure that the user knows what hes doing and never just add any ```CAs``` to your trusted store all ```CAs``` you need are already in your system  
the only reason why we want to add our intermediate CA to the trusted store is that its a selfsigned trust chain  
that means we have created all the certificates by our own and no company or other authority is involved in that chain




### Add CA's to trusted store on Linux
for Linux we will create a ```.pem``` file which contains both CAs the intermediate and the root_CA  
this is done by  
```bash
cat intermediate_CA.crt > example.pem && cat root_CA.crt >> example.pem
```  
```example.pem``` should be changed to the name you want only the .pem ending has to stay  



#### Arch and RedHat
for Arch based and Red Hat based systems we can use the ```trust``` command to add a CA list file to the trusted store
```bash
sudo trust anchor --store /path/to/example.pem
```
and the ```openssl verify``` command can be used to verify that the CAs are added and verifyed 
```bash
openssl verify -CApath /etc/ssl/certs/ path/to/example.pem
```

#### Debian
since debian has no ```trust``` command we need to copy the CA certificate into the ```/usr/local/share/ca-certificates/``` folder  
```bash
sudo cp ca.crt /usr/local/share/ca-certificates/
```
and now we can update the trusted store with ```update-ca-certificates``` like so:
```bash
sudo update-ca-certificates
```
and the ```openssl verify``` command can be used to verify that the CAs are added and verifyed 
```bash
openssl verify -CApath /etc/ssl/certs/ ~/CA_trust_chain.pem
```





## OpenVPN
OpenVPN is a opensource programm to create vpn servers and there is also a openvpn client software for all operating systems  
OpenVPN provides a huge range of modification what makes it kinda difficult for normalos to set it up properly  
i struggled by my self a lot thats why im writing this documentation and also if i need it again in the future i'll have it ready  


### OpenVPN server config
the ```server.conf``` file is one of the most important parts here you will configure the whole vpn server its location is normally ```/etc/openvpn``` or ```/etc/openvpn/server```

first we will define a port to be used be the openvpn service ``` port 1194``` is the standart port for increased security you should change it    
```openvpn
port 1194
```
the config file needs the paths to the ```CA```, the ```server_private.key``` and the ```server.crt```


### OpenVPN Service


### Clients


## Clear the path
this chapter is about how to portforwarding open ports in the firewall and also what to do when you have no public ipv4 address only a ipv6 which is reachable from outside. for example if your ipv4 is tunneled via DSlite through your ipv6



### Firewall


### Portforwarding


### Portmapping Server


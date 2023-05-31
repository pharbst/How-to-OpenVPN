# How To OpenVPN
### ⚠️ pls dont use any certificates provided in this repo cause since the private keys are comming with it, it's absolutely not save  
This is an introduction for setting up an OpenVPN server step by step...

I'm doing it on an arch based system so if something does not work pls let me know to add information and provide help.


## Chapter overview
##### 1.0 [SSL Certificates](#SSL-certificates)
###### &emsp;1.1 [Create SSL Certificates](#create-SSL-certificates)
###### &emsp;1.2 [Add CA's on Windows](#add-CAs-to-trusted-store-on-Windows)
###### &emsp;1.3 [Add CA's on Linux](#add-CAs-to-trusted-store-on-Linux)
###### &emsp;&emsp;1.3.1 [Arch and RedHat](#Arch-and-Red-Hat)
###### &emsp;&emsp;1.3.2 [Debian](#Debian)
###### &emsp; 1.4 [Add CA's on Android](#add-CAs-to-trusted-store-on-Android)
##### 2.0 [OpvenVPN](#OpenVPN)
###### &emsp;2.1 [OpenVPN server config](#OpenVPN-server-config)
###### &emsp;2.2 [Create OpenVPN Service](#Openvpn-Service)
###### &emsp;2.3 [Clients](#Clients)
##### 3.0 [Clear the Path](#clear-the-path)
###### &emsp;3.1 [Routes](#Routes)
###### &emsp;3.2 [Firewall](#Firewall)
###### &emsp;3.3 [Portforwarding](#Portforwarding)
###### &emsp;3.4 [Portmapping Server](#Portmapping-server)




## SSL Certificates
SSL (Secure Socket Layer) is a widely used protocol for establishing a secure communication channel between a server and a client. It stands for Secure Socket Layer. SSL is primarily used to ensure the confidentiality, integrity, and authenticity of data transmitted over the internet.

In simple terms, SSL works as follows: when a client and a server initiate a connection, they exchange digital certificates. The client sends its certificate to the server, and the server sends its certificate to the client. Both the client and server verify these certificates against trusted Certificate Authorities (CAs) stored on their systems.

The certificates contain important information about the entity they represent and include a public key. This public key is used to encrypt data during transmission. Only the corresponding private key, held by the server or the client, can decrypt the encrypted data.

By confirming the certificates with trusted CAs and utilizing encryption with public keys, SSL ensures that the communication between the client and server is secure and protected from unauthorized access or tampering.

This encryption and decryption process allows sensitive information, such as login credentials or financial data, to be transmitted securely over the internet, providing users with peace of mind and protecting their data from potential threats.



### Create SSL Certificates
To establish a secure SSL connection, we need four private keys and certificates. Two of them will serve as Certificate Authorities (CAs), while the other two will be used for the server and client respectively. Here are the certificates we aim to create:

- `root_CA.crt`			: This is the root CA certificate, which acts as a trusted authority to create certificates and other CAs.
- `intermediate_CA.crt`	: The intermediate CA certificate can also create certificates and CAs. It is primarily used to generate client and server certificates.
- `server.crt`			: The server certificate is specific to the server and will be used to establish its identity during SSL communication.
- `client.crt`			: The client certificate is specific to the client and will be used to verify its identity during SSL communication.

It's important to note that every certificate requires a private key, which should be kept confidential and never shared. Now let's walk through the process of creating these certificates


To create our private keys we can use this command which generates us a private key with the `RSA` algorithm and a keylength of 4096bits

```bash
openssl genpkey -algorithm RSA -out private_key.key -pkeyopt rsa_keygen_bits:4096
```

if you want the standard keylength you can either use `-pkeyopt rsa_keygen_bits:2048` or since 2048 is the standard size just this command:

```bash
openssl genpkey -algorithm RSA -out private_key.key
```

with the first command i will now generate at least 4 keys:
- `root_private.key`
- `intermediate_private.key`
- `server_private.key`
- `<client name>_private.key` : for me it would be `peter_private.key`

After generating our private keys we need to create the root_CA.crt first to sign other certificates with it.
This is done by this command:
```bash
openssl req -x509 -new -nodes -key root_private.key -sha256 -days 365 -out root_CA.crt
```
- `root_private.key` : if the `.key` is in your current working directory otherwise it needs to be the path to the `.key`.
- `root_CA.crt` : you can name it as you want.
- `-days 365` : this can be set to any value it is for how long the CA is valid so after 1 year you have to generate new certificates.

so now we have our root_CA.crt  

Next step is to create the `intermediate_CA.crt`.
For that we first need to create a signing request `.csr`.
This is done with the following command:

```bash
openssl req -new -key intermediate_private.key -out intermediate_CA.csr
```
To actually sign this `.csr` file with our `root_CA.crt` and `root_private.key` we use this command:
```bash
openssl x509 -req -in intermediate_CA.csr -CA root_CA.crt -CAkey root_private.key -CAcreateserial -out intermediate_CA.crt -days 365 -sha256
```
- `-in`		: the signing request file `.csr`.
- `-CA`		: the `root_CA.crt` or other CA we wanna sign it with.
- `-CAkey`	: the private key of the CA.
- `-out`	: again you can name it as you want.
- `-days`	: again the duration how long the certificate is valid.

Now we have our CA's ready to go.
We now need to create the `server.crt` and `client.crt` in my case the `peter.crt`.
```bash
openssl req -new -key server_private.key -out server.csr
openssl x509 -req -in server.csr -CA intermediate_CA.crt -CAkey intermediate_private.key -CAcreateserial -out server.crt -days 365 -sha256

openssl req -new -key peter_private.key -out peter.csr
openssl x509 -req -in peter.csr -CA intermediate_CA.crt -CAkey intermediate_private.key -CAcreateserial -out peter.crt -days 365 -sha256
```

For all additional clients it's the same they need a privte key and a `.crt` signe by the `intermediate_CA.crt`.


### Add CA's to trusted store on Windows
To add the intermediate_CA.crt to the trusted store on Windows, follow these steps:

1. Press the "Windows key" and search for "Manage user certificates."

2. In the "Certificates - Current User" window, navigate to the "Trusted Root Certification Authorities" folder in the left-hand pane.

3. Right-click on the "Trusted Root Certification Authorities" folder and select "All Tasks" -> "Import."

4. The Certificate Import Wizard will open. Click "Next" to proceed.

5. Click the "Browse" button and locate the intermediate_CA.crt file that you want to add to the trust store. Select the file and click "Open."

6. Click "Next" to continue.

7. In the next window, choose the option "Place all certificates in the following store" and click the "Browse" button.

8. In the "Select Certificate Store" window, choose "Trusted Root Certification Authorities" and click "OK."

9. Click "Next" to proceed.

10. Review the summary information and click "Finish" to complete the import process.

11. You should see a confirmation message indicating that the certificate was imported successfully. Click "OK" to close the wizard.

It's important to note that you should be cautious when adding CAs to your trusted store. Only add CAs that you trust and are necessary for your specific use case. In this scenario, we are adding the intermediate CA to the trusted store because it is part of a self-signed trust chain. This means that we have created all the certificates ourselves, and no external company or authority is involved in that chain.

By following these steps, you can add the intermediate_CA.crt to the trusted store on your Windows system, ensuring that SSL connections using certificates signed by this intermediate CA are recognized as trusted.


### Add CA's to trusted store on Linux
For Linux we will create a ```.pem``` file which contains both CAs the `intermediate_CA.crt` and the `root_CA.crt`. This is done by:
```bash
cat intermediate_CA.crt > peters_selfsigned_trust_chain.pem && cat root_CA.crt >> peters_selfsigned_trust_chain.pem
```  
Name it as you like.


#### Arch and Red Hat
For Arch-based and Red Hat-based systems, you can use the `trust` command to add a CA list file to the trusted store. Follow these steps:
```bash
sudo trust anchor --store /path/to/peters_selfsigned_trust_chain.pem
```
Replace `/path/to/peters_selfsigned_trust_chain.pem` with the actual path to your CA list file.

After adding the CA list file, you can use the openssl verify command to verify that the CAs are added and validated correctly:
```bash
openssl verify -CApath /etc/ssl/certs/ /path/to/peters_selfsigned_trust_chain.pem
```
Ensure to replace `/path/to/peters_selfsigned_trust_chain.pem` with the actual path to your CA list file.

By running this command, OpenSSL will check the certificates in the specified CA path (`/etc/ssl/certs/` in this case) and verify the trust chain using the CA list file (`peters_selfsigned_trust_chain.pem` in this case). This verification process ensures that the CAs are added to the trusted store and can be used for certificate validation.


#### Debian
On Debian systems, you can manually add the CA certificate to the trusted store by following these steps:

1. Copy the CA certificate (`peters_selfsigned_trust_chain.pem` in this example) to the `/usr/local/share/ca-certificates/` folder:
```bash
sudo cp peters_selfsigned_trust_chain.pem /usr/local/share/ca-certificates/
```
2. Update the trusted store using the `update-ca-certificates` command:
```bash
sudo update-ca-certificates
```
This command updates the trusted store with the CA certificate you copied to the specified folder.

After updating the trusted store, you can use the `openssl verify` command to verify that the CAs are added and correctly validated:
```bash
openssl verify -CApath /etc/ssl/certs/ peters_selfsigned_trust_chain.pem
```

### Add CA's to trusted store on Android
On Android devices you can go into the settings and scroll down until you find security settings you have to dig through there a bit to find a setting called add certificate or simular. The CA has to be on your phone of course. 


## OpenVPN
OpenVPN is a powerful open-source program designed for creating VPN servers and establishing secure connections between networks or remote devices. It offers comprehensive features and is compatible with various operating systems, providing an OpenVPN client software for easy setup and usage.

With OpenVPN, you have complete control over the configuration and customization of your VPN setup. This flexibility allows you to tailor the VPN to your specific needs, whether it's for enhancing privacy and security, accessing restricted content, or connecting remote offices securely.

While OpenVPN's versatility is advantageous, it can be challenging for those unfamiliar with VPN technologies to set up and configure correctly. However, with proper documentation and guidance, you can overcome these difficulties and successfully deploy an OpenVPN solution.

This documentation aims to provide a step-by-step guide, sharing knowledge and best practices to simplify the OpenVPN setup process. By following the instructions and explanations provided, you can confidently create and manage your OpenVPN server, configure clients, and ensure a secure and reliable VPN connection.

Whether you are new to OpenVPN or seeking a comprehensive resource to refer to in the future, this documentation will serve as a valuable reference to help you navigate the complexities of OpenVPN configuration and deployment effectively.


### OpenVPN server config
For the OpenVPN `server.conf` there's much to know so here is a basic config file:

```config
port 1194
proto tcp
dev tun
topology subnet

ca /etc/ssl/certs/peters_selfsigned_trust_chain.pem
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server_private.key
dh /etc/openvpn/server/dh.pem

server 192.168.180.0 255.255.255.0
ifconfig-pool-persist ipp.txt

client-config-dir /etc/openvpn/server/ccd
client-to-client
duplicate-cn

push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp_option DNS 8.8.4.4"
push "route 192.168.178.0 255.255.255.0"

keepalive 10 120
user nobody
group nobody

persist-key
persist-tun

status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3
```
1. `port 1194`: This line specifies the port number on which the OpenVPN server will listen for incoming connections. In this case, it is set to `port 1194`.

1. `proto tcp`: This line specifies the transport protocol used by OpenVPN. In this case, it is set to `TCP`.

1. `dev tun`: This line specifies the network device used for the VPN tunnel. In this case, it is set to `tun`.
	- "tun" is a virtual network tunneling device that operates at the network layer (Layer 3) and is used for routing purposes.
	- "tap" is a virtual network interface that operates at the data link layer (Layer 2) and is used for creating Ethernet-like bridges and connecting multiple networks together.
1. `ca /etc/ssl/certs/peters_selfsigned_trust_chain.pem`: This line specifies the path to the CA (Certificate Authority) certificate file. The CA certificate is used to verify the authenticity of the server's certificate.

1. `cert /etc/openvpn/server/server.crt`: This line specifies the path to the server's certificate file. The server's certificate is used to authenticate the server to the clients.

1. `key /etc/openvpn/server/server_private.key`: This line specifies the path to the server's private key file. The private key is used for cryptographic operations and should be kept secure.

1. `server 192.168.180.0 255.255.255.0`: This line defines the IP address pool for the VPN clients. In this case, it specifies that the server will assign IP addresses from the range 192.168.180.0 to 192.168.180.255 with a netmask of 255.255.255.0.

1. `ifconfig-pool-persist ipp.txt`: This line specifies a file (ipp.txt) where persistent IP address assignments for clients will be stored.

1. `client-config-dir /etc/openvpn/server/ccd` : This line sets the directory to save client configurations.

1. `client-to-client`: This line allows communication between connected clients in the VPN. By default, OpenVPN does not allow clients to communicate with each other.

1. `duplicate-cn` : This line allows clients to log in with multiple devices at the same time.

1. `push "redirect-gateway def1"`: This line pushes a route to the client that redirects all of its traffic through the VPN server.

1. `push "dhcp-option DNS 8.8.8.8"` and `push "dhcp-option DNS 8.8.4.4"`: These lines push DNS (Domain Name System) configuration options to the clients. In this case, it sets the DNS servers to Google's public DNS servers (8.8.8.8 and 8.8.4.4).

1. `push "route 192.168.178.0 255.255.255.0"`: This line pushes a specific route to the VPN clients, allowing them to access resources in the 192.168.178.0/24 network by routing the traffic through the OpenVPN server. It enables visibility and connectivity between the VPN network (192.168.180.0/24) and the local network (192.168.178.0/24).


1. `keepalive 10 120`: This line sets the keepalive parameters for the VPN connection. It specifies that a keepalive packet should be sent every 10 seconds, and if no response is received within 120 seconds, the connection will be considered lost.

1. `user nobody`: This line specifies the user account under which the OpenVPN process will run. The user account "nobody" is a common convention used to run services with minimal privileges and reduce potential security risks. The "nobody" user typically has limited permissions and access rights, providing an additional layer of security for the OpenVPN process.

1. `persist-key` and `persist-tun`: These lines instruct OpenVPN to persist the encryption key and tunnel interface across restarts.
	- `persist-key`: This directive allows the OpenVPN server to persistently store the encryption key used for TLS authentication. By enabling persist-key, the server will remember and reuse the same key across client connections, eliminating the need to renegotiate the key for every new connection.

	- `persist-tun`: This directive instructs the OpenVPN server to persistently maintain the tunnel interface (tun or tap) even when the client connection is temporarily interrupted. When persist-tun is enabled, the server will keep the tunnel interface active and maintain its configuration, allowing for seamless reconnection and resumption of VPN communication once the client reconnects.

1. `status openvpn-status.log`: This line specifies the file where the OpenVPN server will write status information and logging output.

1. `verb 3`: This line sets the verbosity level of OpenVPN logging. A higher value (e.g., 3) provides more detailed log output for troubleshooting purposes.

These lines collectively configure the OpenVPN server with various parameters and settings to establish and manage the VPN connections.

### OpenVPN Service
To create a service for OpenVPN we need to create the `.service` file in this directory `/etc/systemd/system/` i will call my `.service` file `openvpn.service`.
```bash
sudo nano /etc/systemd/system/openvpn.service
```
Now we need to write or copy paste these information in the file.
```plaintext
[Unit]
Description=OpenVPN service
After=network.target

[Service]
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/server/server.conf --data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC:AES-128-CBC
Restart=always
WorkingDirectory=/etc/openvpn/server

[Install]
WantedBy=multi-user.target
```

- `[Unit]` : This section contains metadata and dependencies for the service unit.

- `Description=OpenVPN service` : Provides a description for the service, which will be displayed when managing the service.

- `After=network.target` : Specifies that the service should start after the network subsystem is up and running.

- `[Service]` : This section configures the behavior of the service.

- `ExecStart` : Specifies the command to start the OpenVPN service. It runs the openvpn executable with the `--config` option to provide the path to the server configuration file (`/etc/openvpn/server/server.conf`). Additionally, the `--data-ciphers` option is used to define the allowed encryption ciphers for data transmission.

	- `AES-128-CBC`, `AES-128-GCM`, `AES-256-CBC`, `AES-256-GCM` : These are AES (Advanced Encryption Standard) cipher methods with different key lengths and operating modes. AES-128 uses a 128-bit key, and AES-256 uses a 256-bit key. CBC (Cipher Block Chaining) is a block cipher mode, while GCM (Galois/Counter Mode) provides authenticated encryption.
	- `BF-CBC`: Blowfish encryption in CBC mode.
	- `DES-CBC` : DES (Data Encryption Standard) encryption in CBC mode.
	- `3DES-CBC` : Triple DES encryption in CBC mode.
	- `CAMELLIA-128-CBC`, `CAMELLIA-192-CBC`, `CAMELLIA-256-CBC`: Camellia cipher methods with different key lengths in CBC mode.
- `Restart=always` : Indicates that the service should be automatically restarted if it stops unexpectedly.

- `WorkingDirectory=/etc/openvpn/server` : Sets the working directory for the service to /etc/openvpn/server.

- `[Install]` : This section specifies the installation-related settings for the service.

- `WantedBy=multi-user.target` : Indicates that the service should be enabled and started when the system reaches the multi-user target, which is the normal operating mode for most systems.

Please note that the choice of cipher methods should align with the security requirements of your VPN deployment. It is important to consider the balance between security and performance, as stronger ciphers may require more processing power. The cipher methods listed in the example provide a range of options with varying key lengths and operating modes to accommodate different security needs.


### Clients


## Clear the path
In this chapter we will configure the local network


### Routes
For a simple explanation we fist need to be on the same level how the network looks like.
So here is a quick example how it looks like.  
I assume there are at least 3 devices in the local network:
- Router
- Your Workstation
- Server
For my explanation the `Router` has the ip address `192.168.178.1`,  
the `Workstation` has the ip address `192.168.178.3` and  
the `Server` has the ip address `192.168.178.2`.

Additionally the `Server` has a second network interface from the `openvpn.service` which is called `tun1` by default and this interface has the ip address.  

### Firewall


### Portforwarding


### Portmapping Server


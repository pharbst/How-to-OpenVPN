# VPN
this is my repo with all the nesessary files to set up a openvpn server but all the files are just for testing purpose and wont be used in real serverapplications

# Create ssl Certificates
we need at least 4 private keys and certificates
2 of them will be certificate authoritys and the other two are for the server and a client
  root_CA.crt
  intermediate_CA.crt
  server.crt
  client.crt
these are the certificates we wanna create
the root_ca is a certificate authority to create certificates and also certificate authoritys
the intermediate could also create certificate authoritys but is mainly used to create client and server certificates
every certificate needs a private key to work this privat key should be always kept save and never be shared
to create our root_ca.crt we first need to create a privat key which is the root of our selfsigned trustchain so store is save maybe offline on a seperate harddrive or thumbstick
  but be aware that thumbdrives looses their data when left unplugged for several years even hard drives loose data after 10 years without power
```bash
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:4096
```

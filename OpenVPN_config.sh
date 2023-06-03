#!/bin/bash

check_package_installed() {
    local package_manager
    local package_name

    package_manager=""
    package_name="$1"

    # Check if package is installed using appropriate package manager
    if command -v dpkg >/dev/null 2>&1; then
        package_manager="dpkg"
    elif command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif command -v yum >/dev/null 2>&1; then
        package_manager="yum"
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
    else
        echo "Unsupported package manager. Unable to check package installation."
        exit 1
    fi

    # Check if package is installed and install if not

    case "$package_manager" in
        "dpkg")
            if ! dpkg -s "$package_name" >/dev/null 2>&1; then
                echo "$package_name is not installed."
				dpkg -s "$package_name"
            fi
            ;;
        "dnf")
            if ! dnf list installed "$package_name" >/dev/null 2>&1; then
                echo "$package_name is not installed."
				dnf install "$package_name"
            fi
            ;;
        "yum")
            if ! yum list installed "$package_name" >/dev/null 2>&1; then
                echo "$package_name is not installed."
				yum install "$package_name"
            fi
            ;;
        "pacman")
            if ! pacman -Q "$package_name" >/dev/null 2>&1; then
                echo "$package_name is not installed."
				pacman -S --noconfirm "$package_name"
            fi
            ;;
        *)
            echo "Unsupported package manager. Unable to check package installation."
            exit 1
            ;;
    esac
}


if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo or root privileges."
    exit 1
fi

echo -e "\033[1;32mThis Script is for the complete setup from creating certificates until the service creation and start.\033[0m"
echo -e "\033[1;33mContinue? (y/N)\033[0m"
read -r answer
if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
	echo -e "\033[1;32mStarting...\033[0m"
else
	echo -e "\033[1;31mAborting...\033[0m"
	exit 1
fi

# Check if openssl, OpenVPN is installed
check_package_installed "openssl"
check_package_installed "openvpn"

while true; do
	# Create the certificates: ask for the name for the root_CA, the intermediate_CA, the server, and the client or clients
	echo -e "\033[1;33mPlease enter the name for the root_CA:\033[0m"
	read -r root_CA
	root_CA="${root_CA:-root_CA}"

	echo -e "\033[1;33mPlease enter the name for the intermediate_CA:\033[0m"
	read -r intermediate_CA
	intermediate_CA="${intermediate_CA:-intermediate_CA}"

	echo -e "\033[1;33mPlease enter the name for the server:\033[0m"
	read -r server
	server="${server:-server}"

	echo -e "\033[1;33mPlease enter the number of client certificates you need:\033[0m"
	read -r client_num
	client_num="${client_num:-1}"

	declare -a names
	for ((i = 1; i <= client_num; i++)); do
		echo -e "\033[1;33mPlease enter the name for client $i:\033[0m"
		read -r name
		names[i]="${name:-client$i}"
	done

	# Print all variables
	echo -e "\033[1;32mThe root_CA is: $root_CA\033[0m"
	echo -e "\033[1;32mThe intermediate_CA is: $intermediate_CA\033[0m"
	echo -e "\033[1;32mThe server is: $server\033[0m"
	echo -e "\033[1;32mThe client num is: $client_num\033[0m"
	for ((i = 1; i <= client_num; i++)); do
		echo -e "\033[1;32mThe client $i is: ${names[i]}\033[0m"
	done
	echo -e "\033[1;33mIs this correct? (Y/n)\033[0m"
	read -r answer
	answer="${answer:-y}"
	if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
		break
	fi
done

while true; do
	echo -e "\033[1;32mPls enter the subject information for the certificates if you wanna leave something empty use .:\033[0m"
	echo -e "\033[1;33mFor $root_CA:\033[0m"
	echo -e "\033[1;33mCountry Name (2 letter code) [AU]:\033[0m"
	read -r root_CA_country
	root_CA_country="${root_CA_country:-}"
	echo -e "\033[1;33mState or Province Name (full name) [Some-State]:\033[0m"
	read -r root_CA_state
	root_CA_state="${root_CA_state:-}"
	echo -e "\033[1;33mLocality Name (eg, city) []:\033[0m"
	read -r root_CA_locality
	root_CA_locality="${root_CA_locality:-}"
	echo -e "\033[1;33mOrganization Name (eg, company) [Internet Widgits Pty Ltd]:\033[0m"
	read -r root_CA_organization
	root_CA_organization="${root_CA_organization:-}"
	echo -e "\033[1;33mOrganizational Unit Name (eg, section) []:\033[0m"
	read -r root_CA_organizational_unit
	root_CA_organizational_unit="${root_CA_organizational_unit:-}"
	echo -e "\033[1;33mCommon Name (e.g. server FQDN or YOUR name) []:\033[0m"
	read -r root_CA_common_name
	root_CA_common_name="${root_CA_common_name:-}"
	echo -e "\033[1;33mEmail Address []:\033[0m"
	read -r root_CA_email
	root_CA_email="${root_CA_email:-}"

	if [[ -z $root_CA_country ]] || [[ -z $root_CA_state ]] || [[ -z $root_CA_locality ]] || [[ -z $root_CA_organization ]] || [[ -z $root_CA_organizational_unit ]] || [[ -z $root_CA_common_name ]] || [[ -z $root_CA_email ]]; then
		echo -e "\033[1;31mYou have to fill in all the information!\033[0m"
	else
		echo -e "\033[1;32mThe root_CA_country is: $root_CA_country\033[0m"
		echo -e "\033[1;32mThe root_CA_state is: $root_CA_state\033[0m"
		echo -e "\033[1;32mThe root_CA_locality is: $root_CA_locality\033[0m"
		echo -e "\033[1;32mThe root_CA_organization is: $root_CA_organization\033[0m"
		echo -e "\033[1;32mThe root_CA_organizational_unit is: $root_CA_organizational_unit\033[0m"
		echo -e "\033[1;32mThe root_CA_common_name is: $root_CA_common_name\033[0m"
		echo -e "\033[1;32mThe root_CA_email is: $root_CA_email\033[0m"
		echo -e "\033[1;33mIs this correct? (Y/n)\033[0m"
		read -r answer
		answer="${answer:-y}"
		if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
			break
		fi
	fi
done
while true; do
	echo -e "\033[1;33mWanna use the same information for $intermediate_CA? (Y/n)\033[0m"
	read -r answer
	answer="${answer:-y}"
	if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
		intermediate_CA_country="$root_CA_country"
		intermediate_CA_state="$root_CA_state"
		intermediate_CA_locality="$root_CA_locality"
		intermediate_CA_organization="$root_CA_organization"
		intermediate_CA_organizational_unit="$root_CA_organizational_unit"
		intermediate_CA_common_name="$root_CA_common_name"
		intermediate_CA_email="$root_CA_email"
		break
	else
		echo -e "\033[1;33mFor $intermediate_CA:\033[0m"
		echo -e "\033[1;33mCountry Name (2 letter code) [AU]:\033[0m"
		read -r intermediate_CA_country
		intermediate_CA_country="${intermediate_CA_country:-AU}"
		echo -e "\033[1;33mState or Province Name (full name) [Some-State]:\033[0m"
		read -r intermediate_CA_state
		intermediate_CA_state="${intermediate_CA_state:-Some-State}"
		echo -e "\033[1;33mLocality Name (eg, city) []:\033[0m"
		read -r intermediate_CA_locality
		intermediate_CA_locality="${intermediate_CA_locality:-}"
		echo -e "\033[1;33mOrganization Name (eg, company) [Internet Widgits Pty Ltd]:\033[0m"
		read -r intermediate_CA_organization
		intermediate_CA_organization="${intermediate_CA_organization:-Internet Widgits Pty Ltd}"
		echo -e "\033[1;33mOrganizational Unit Name (eg, section) []:\033[0m"
		read -r intermediate_CA_organizational_unit
		intermediate_CA_organizational_unit="${intermediate_CA_organizational_unit:-}"
		echo -e "\033[1;33mCommon Name (e.g. server FQDN or YOUR name) []:\033[0m"
		read -r intermediate_CA_common_name
		intermediate_CA_common_name="${intermediate_CA_common_name:-}"
		echo -e "\033[1;33mEmail Address []:\033[0m"
		read -r intermediate_CA_email
		intermediate_CA_email="${intermediate_CA_email:-}"
	fi
	if [[ -z $intermediate_CA_country ]] || [[ -z $intermediate_CA_state ]] || [[ -z $intermediate_CA_locality ]] || [[ -z $intermediate_CA_organization ]] || [[ -z $intermediate_CA_organizational_unit ]] || [[ -z $intermediate_CA_common_name ]] || [[ -z $intermediate_CA_email ]]; then
		echo -e "\033[1;31mYou have to fill in all the information!\033[0m"
	else
		echo -e "\033[1;32mThe intermediate_CA_country is: $intermediate_CA_country\033[0m"
		echo -e "\033[1;32mThe intermediate_CA_state is: $intermediate_CA_state\033[0m"
		echo -e "\033[1;32mThe intermediate_CA_locality is: $intermediate_CA_locality\033[0m"
		echo -e "\033[1;32mThe intermediate_CA_organization is: $intermediate_CA_organization\033[0m"
		echo -e "\033[1;32mThe intermediate_CA_organizational_unit is: $intermediate_CA_organizational_unit\033[0m"
		echo -e "\033[1;32mThe intermediate_CA_common_name is: $intermediate_CA_common_name\033[0m"
		echo -e "\033[1;32mThe intermediate_CA_email is: $intermediate_CA_email\033[0m"
		echo -e "\033[1;33mIs this correct? (Y/n)\033[0m"
		read -r answer
		answer="${answer:-y}"
		if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
			break
		fi
	fi
done
while true; do
	echo -e "\033[1;33mWanna use the info from the $root_CA or the $intermediate_CA for $server? (Y/n)\033[0m"
	read -r answer
	answer="${answer:-n}"
	if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo -e "\033[1;33mWanna use the info from the $root_CA or the $intermediate_CA for $server?\033[0m"
		echo -e "1 = $root_CA"
		echo -e "2 = $intermediate_CA"

		echo -e "\033[1;33mPlease enter the number[default=2]:\033[0m"
		read -r answer
		answer="${answer:-2}"
		if [[ $answer == 1 ]]; then
			server_country="$root_CA_country"
			server_state="$root_CA_state"
			server_locality="$root_CA_locality"
			server_organization="$root_CA_organization"
			server_organizational_unit="$root_CA_organizational_unit"
			server_common_name="$root_CA_common_name"
			server_email="$root_CA_email"
			break
		elif [[ $answer == 2 ]]; then
			server_country="$intermediate_CA_country"
			server_state="$intermediate_CA_state"
			server_locality="$intermediate_CA_locality"
			server_organization="$intermediate_CA_organization"
			server_organizational_unit="$intermediate_CA_organizational_unit"
			server_common_name="$intermediate_CA_common_name"
			server_email="$intermediate_CA_email"
			break
		fi
	fi
	echo -e "\033[1;33mFor $server:\033[0m"
	echo -e "\033[1;33mCountry Name (2 letter code) [AU]:\033[0m"
	read -r server_country
	server_country="${server_country:-}"
	echo -e "\033[1;33mState or Province Name (full name) [Some-State]:\033[0m"
	read -r server_state
	server_state="${server_state:-}"
	echo -e "\033[1;33mLocality Name (eg, city) []:\033[0m"
	read -r server_locality
	server_locality="${server_locality:-}"
	echo -e "\033[1;33mOrganization Name (eg, company) [Internet Widgits Pty Ltd]:\033[0m"
	read -r server_organization
	server_organization="${server_organization:-}"
	echo -e "\033[1;33mOrganizational Unit Name (eg, section) []:\033[0m"
	read -r server_organizational_unit
	server_organizational_unit="${server_organizational_unit:-}"
	echo -e "\033[1;33mCommon Name (e.g. server FQDN or YOUR name) []:\033[0m"
	read -r server_common_name
	server_common_name="${server_common_name:-}"
	echo -e "\033[1;33mEmail Address []:\033[0m"
	read -r server_email
	server_email="${server_email:-}"
	if [[ -z $server_country ]] || [[ -z $server_state ]] || [[ -z $server_locality ]] || [[ -z $server_organization ]] || [[ -z $server_organizational_unit ]] || [[ -z $server_common_name ]] || [[ -z $server_email ]]; then
		echo -e "\033[1;31mYou have to fill in all the information!\033[0m"
	else
		echo -e "\033[1;32mThe server_country is: $server_country\033[0m"
		echo -e "\033[1;32mThe server_state is: $server_state\033[0m"
		echo -e "\033[1;32mThe server_locality is: $server_locality\033[0m"
		echo -e "\033[1;32mThe server_organization is: $server_organization\033[0m"
		echo -e "\033[1;32mThe server_organizational_unit is: $server_organizational_unit\033[0m"
		echo -e "\033[1;32mThe server_common_name is: $server_common_name\033[0m"
		echo -e "\033[1;32mThe server_email is: $server_email\033[0m"
		echo -e "\033[1;33mIs this correct? (Y/n)\033[0m"
		read -r answer
		answer="${answer:-y}"
		if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
			break
		fi
	fi
done

for ((i = 1; i <= client_num; i++)); do
	while true; do
		echo -e "\033[1;33mWanna use the info from the $root_CA or the $intermediate_CA or the $server for the ${names[i]}? (y/N):\033[0m"
		read -r answer
		answer="${answer:-n}"
		if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
			echo -e "\033[1;33mPlease choose the info source for ${names[i]}:\033[0m"
			echo -e "1 = $root_CA"
			echo -e "2 = $intermediate_CA"
			echo -e "3 = $server"
			echo -e "\033[1;33mPlease enter the number [default=3]:\033[0m"
			read -r answer
			answer="${answer:-3}"
			if [[ $answer == 1 ]]; then
				names_country[i]="$root_CA_country"
				names_state[i]="$root_CA_state"
				names_locality[i]="$root_CA_locality"
				names_organization[i]="$root_CA_organization"
				names_organizational_unit[i]="$root_CA_organizational_unit"
				names_common_name[i]="$root_CA_common_name"
				names_email[i]="$root_CA_email"
				break
			elif [[ $answer == 2 ]]; then
				names_country[i]="$intermediate_CA_country"
				names_state[i]="$intermediate_CA_state"
				names_locality[i]="$intermediate_CA_locality"
				names_organization[i]="$intermediate_CA_organization"
				names_organizational_unit[i]="$intermediate_CA_organizational_unit"
				names_common_name[i]="$intermediate_CA_common_name"
				names_email[i]="$intermediate_CA_email"
				break
			elif [[ $answer == 3 ]]; then
				names_country[i]="$server_country"
				names_state[i]="$server_state"
				names_locality[i]="$server_locality"
				names_organization[i]="$server_organization"
				names_organizational_unit[i]="$server_organizational_unit"
				names_common_name[i]="$server_common_name"
				names_email[i]="$server_email"
				break
			fi
		fi

		echo -e "\033[1;33mFor ${names[i]}:\033[0m"
		echo -e "\033[1;33mCountry Name (2 letter code) [AU]:\033[0m"
		read -r names_country[i]
		names_country[i]="${names_country[i]:-}"

		echo -e "\033[1;33mState or Province Name (full name) [Some-State]:\033[0m"
		read -r names_state[i]
		names_state[i]="${names_state[i]:-}"

		echo -e "\033[1;33mLocality Name (eg, city) []:\033[0m"
		read -r names_locality[i]
		names_locality[i]="${names_locality[i]:-}"

		echo -e "\033[1;33mOrganization Name (eg, company) [Internet Widgits Pty Ltd]:\033[0m"
		read -r names_organization[i]
		names_organization[i]="${names_organization[i]:-}"

		echo -e "\033[1;33mOrganizational Unit Name (eg, section) []:\033[0m"
		read -r names_organizational_unit[i]
		names_organizational_unit[i]="${names_organizational_unit[i]:-}"

		echo -e "\033[1;33mCommon Name (e.g. server FQDN or YOUR name) []:\033[0m"
		read -r names_common_name[i]
		names_common_name[i]="${names_common_name[i]:-}"

		echo -e "\033[1;33mEmail Address []:\033[0m"
		read -r names_email[i]
		names_email[i]="${names_email[i]:-}"

		if [[ -z ${names_country[i]} ]] || [[ -z ${names_state[i]} ]] || [[ -z ${names_locality[i]} ]] || [[ -z ${names_organization[i]} ]] || [[ -z ${names_organizational_unit[i]} ]] || [[ -z ${names_common_name[i]} ]] || [[ -z ${names_email[i]} ]]; then
			echo -e "\033[1;31mYou have to fill in all the information!\033[0m"
		else
			echo -e "\033[1;32mThe names_country is: ${names_country[i]}\033[0m"
			echo -e "\033[1;32mThe names_state is: ${names_state[i]}\033[0m"
			echo -e "\033[1;32mThe names_locality is: ${names_locality[i]}\033[0m"
			echo -e "\033[1;32mThe names_organization is: ${names_organization[i]}\033[0m"
			echo -e "\033[1;32mThe names_organizational_unit is: ${names_organizational_unit[i]}\033[0m"
			echo -e "\033[1;32mThe names_common_name is: ${names_common_name[i]}\033[0m"
			echo -e "\033[1;32mThe names_email is: ${names_email[i]}\033[0m"
			echo -e "\033[1;33mIs this correct? (Y/n)\033[0m"
			read -r answer
			answer="${answer:-y}"
			if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
				break
			fi
		fi
	done
done

# Create Private keys
echo -e "\033[0;32mCreating Private keys\033[0m"
openssl genpkey -algorithm RSA -out "$root_CA.key" -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out "$intermediate_CA.key" -pkeyopt rsa_keygen_bits:4096
openssl genpkey -algorithm RSA -out "$server.key" -pkeyopt rsa_keygen_bits:4096
for ((i = 1; i <= client_num; i++)); do
	openssl genpkey -algorithm RSA -out "${names[i]}.key" -pkeyopt rsa_keygen_bits:4096
done

# Create Certificate Signing Requests and $root_CA.crt
echo -e "\033[0;32mCreating Certificate Signing Requests and $root_CA.crt\033[0m"
echo -e "\033[1;33mPlease fill in the details for $root_CA.key\033[0m"
openssl req -x509 -new -nodes -key "$root_CA.key" -sha256 -days 365 -out "$root_CA.crt" -subj "/C=$root_CA_country/ST=$root_CA_state/L=$root_CA_locality/O=$root_CA_organization/OU=$root_CA_organizational_unit/CN=$root_CA_common_name/emailAddress=$root_CA_email"
echo -e "\033[1;33mPlease fill in the details for $intermediate_CA.csr\033[0m"
openssl req -new -nodes -key "$intermediate_CA.key" -sha256 -days 365 -out "$intermediate_CA.csr" -subj "/C=$intermediate_CA_country/ST=$intermediate_CA_state/L=$intermediate_CA_locality/O=$intermediate_CA_organization/OU=$intermediate_CA_organizational_unit/CN=$intermediate_CA_common_name/emailAddress=$intermediate_CA_email"
echo -e "\033[1;33mPlease fill in the details for $server.csr\033[0m"
openssl req -new -nodes -key "$server.key" -sha256 -days 365 -out "$server.csr" -subj "/C=$server_country/ST=$server_state/L=$server_locality/O=$server_organization/OU=$server_organizational_unit/CN=$server_common_name/emailAddress=$server_email"
for ((i = 1; i <= client_num; i++)); do
	echo -e "\033[1;33mPlease fill in the details for ${names[i]}.csr\033[0m"
	openssl req -new -nodes -key "${names[i]}.key" -sha256 -days 365 -out "${names[i]}.csr" -subj "/C=${names_country[i]}/ST=${names_state[i]}/L=${names_locality[i]}/O=${names_organization[i]}/OU=${names_organizational_unit[i]}/CN=${names_common_name[i]}/emailAddress=${names_email[i]}"
done

# Signing Certificates
echo -e "\033[0;32mSigning Certificates\033[0m"
openssl x509 -req -in "$intermediate_CA.csr" -CA "$root_CA.crt" -CAkey "$root_CA.key" -CAcreateserial -out "$intermediate_CA.crt" -days 365 -sha256
openssl x509 -req -in "$server.csr" -CA "$intermediate_CA.crt" -CAkey "$intermediate_CA.key" -CAcreateserial -out "$server.crt" -days 365 -sha256
for ((i = 1; i <= client_num; i++)); do
	openssl x509 -req -in "${names[i]}.csr" -CA "$intermediate_CA.crt" -CAkey "$intermediate_CA.key" -CAcreateserial -out "${names[i]}.crt" -days 365 -sha256
done

# Creating Diffie-Hellman parameters
echo -e "\033[0;32mCreating Diffie-Hellman parameters\033[0m"
openssl dhparam -out dhparam.pem 2048

# Creating .pem file
echo -e "\033[0;32mCreating .pem file\033[0m"
cat "$intermediate_CA.crt" "$root_CA.crt" > trustchain.pem

# Moving the files to the right places
echo -e "\033[0;32mMoving the files to the right places\033[0m"
mkdir -p /etc/openvpn/server/ccd
mv "$server.crt" "$server.key" dhparam.pem /etc/openvpn/server/
mkdir -p /var/log/openvpn
touch /var/log/openvpn/openvpn.log
touch /var/log/openvpn/status.log
cp trustchain.pem /etc/ssl/certs/
mkdir -p /etc/openvpn/server/clients
for ((i = 1; i <= client_num; i++)); do
	mv "${names[i]}.crt" "${names[i]}.key" /etc/openvpn/server/clients
done

# adding the .pem file to the trusted store for debian archred hat enterprise linux and fedora
echo -e "\033[0;32mAdding the .pem file to the trusted store\033[0m"
if command -v update-ca-trust >/dev/null 2>&1; then
	update-ca-trust force-enable
	cp trustchain.pem /etc/pki/ca-trust/source/anchors/
	update-ca-trust extract
elif command -v update-ca-certificates >/dev/null 2>&1; then
	cp trustchain.pem /usr/local/share/ca-certificates/
	update-ca-certificates
elif command -v trust >/dev/null 2>&1; then
	cp trustchain.pem /etc/pki/ca-trust/source/anchors/
	trust anchor trustchain.pem
else
	echo "Unable to add trustchain.pem to the trusted store."
	exit 1
fi
openssl verify trustchain.pem

# Creating the server.conf
echo -e "\033[0;32mCreating the server.conf\033[0m"
echo -e "\033[1;33mPlease enter the port for the server [default=1194]:\033[0m"
read -r server_port
server_port="${server_port:-1194}"
echo -e "\033[1;33mPlease enter the protocol for the server [default=udp]:\033[0m"
read -r server_protocol
server_protocol="${server_protocol:-udp}"
echo -e "\033[1;33mPlease enter the network for the server [default=192.168.180.0/24]:\033[0m"
read -r server_network
server_network="${server_network:-"192.168.180.0 255.255.255.0"}"
echo -e "\033[1;33mDo you wanna redirect the default gateway? (Y/n)\033[0m"
read -r answer
answer="${answer:-y}"
if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
	conf_gateway="push \"redirect-gateway def1\""
else
	conf_gateway=""
fi
echo -e "\033[1;33mDo you wanna redirect the default gateway for ipv6? (Y/n)\033[0m"
read -r answer
answer="${answer:-y}"
if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
	conf_gateway_ipv6="push \"redirect-gateway ipv6\""
else
	conf_gateway_ipv6=""
fi

echo -e "\033[1;33mDo you wanna push route to normal local network? (Y/n)\033[0m"
read -r answer
answer="${answer:-y}"
if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
	conf_route="push \"route $server_network\""
else
	conf_route=""
fi

i = 0
while true; do
	echo -e "\033[1;33mEnter further push options for the server leave blank if you dont want to add any:\033[0m"
	read -r conf_push
	if [[ -z $conf_push ]]; then
		break
	fi
	conf_pushes[i]="$conf_push"
	i=$((i + 1))
done

# change the keepalive time
echo -e "\033[1;33mPlease enter the keepalive time for the server [default=10 120]:\033[0m"
read -r server_keepalive
server_keepalive="${server_keepalive:-"10 120"}"

# persist key and tun?
echo -e "\033[1;33mDo you wanna persist key? (Y/n)\033[0m"
read -r answer
answer="${answer:-y}"
if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
	conf_persist_key="persist-key"
else
	conf_persist_key=""
fi
echo -e "\033[1;33mDo you wanna persist tun? (Y/n)\033[0m"
read -r answer
answer="${answer:-y}"
if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]; then
	conf_persist_tun="persist-tun"
else
	conf_persist_tun=""
fi

# change the cipher
echo -e "\033[1;33mPlease enter the cipher for the server [default=AES-256-GCM]:\033[0m"
read -r server_cipher
server_cipher="${server_cipher:-AES-256-GCM}"

# generating the server.conf
echo -e "\033[0;32mGenerating the server.conf\033[0m"
echo "port $server_port
proto $server_protocol
dev tun

ca /etc/ssl/certs/trustchain.pem
cert /etc/openvpn/server/$server.crt
key /etc/openvpn/server/$server.key
dh /etc/openvpn/server/dhparam.pem

server $server_network
$conf_gateway
$conf_gateway_ipv6
$conf_route" >/etc/openvpn/server/server.conf

for ((i = 0; i < ${#conf_pushes[@]}; i++)); do
	echo "${conf_pushes[i]}" >>/etc/openvpn/server/server.conf
done

echo "
$conf_persist_key
$conf_persist_tun
keepalive $server_keepalive
cipher $server_cipher

user nobody
group nogroup

persist-key
persist-tun

status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3" >>/etc/openvpn/server/server.conf



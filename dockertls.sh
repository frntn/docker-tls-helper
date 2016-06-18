#!/bin/bash -u

: ${SRV_SUBJ}
: ${CLT_SUBJ}

CA_SUBJ="${CA_SUBJ:-"/C=${CA_C:-"FR"}/L=${CA_L:-"Paris"}/O=${CA_O:-"Ekino"}/OU=${CA_OU:-"DevOps"}/CN=${CA_CN:-"Docker TLS"}"}"
CERTS_PATH="${CERTS_PATH:-"dockertls"}"

# --------------------------------------- CA

create_ca() {
  umask 177
  env LC_CTYPE=C < /dev/urandom tr -dc "+=\-%*\!&#':;{}()[]|^~\$_2-9T-Z" | head -c65 > ca.pass

  # .key / .crt
  openssl req \
      -new -x509 -days ${CA_EXPIRE_DAYS:-"365"} \
      -newkey rsa:4096 -keyout ca.key -passout file:ca.pass \
      -out ca.crt -subj "${CA_SUBJ}"
}

# --------------------------------------- SERVER

create_server() {
  # .key / .csr
  openssl req -new \
      -newkey rsa:4096 -keyout server.key -nodes \
      -out server.csr -subj "${SRV_SUBJ}"

  # .crt
  EXTFILE="extendedKeyUsage = serverAuth"
  [ ! -z "${SRV_SAN:-""}" ] && EXTFILE="${EXTFILE}\nsubjectAltName = ${SRV_SAN}"
  openssl x509 -req \
      -days 365 -sha256 \
      -in server.csr -passin file:ca.pass \
      -CA ca.crt -CAkey ca.key -CAserial ca.srl -CAcreateserial \
      -out server.crt \
      -extfile <(echo -e "${EXTFILE}")
}

# --------------------------------------- CLIENT

create_client() {
  # .key / .csr
  openssl req -new \
      -newkey rsa:4096 -keyout client.key -nodes \
      -out client.csr -subj "$CLT_SUBJ"

  # .crt
  EXTFILE="extendedKeyUsage = clientAuth"
  openssl x509 -req \
      -days 365 -sha256 \
      -in client.csr -passin file:ca.pass \
      -CA ca.crt -CAkey ca.key -CAserial ca.srl -CAcreateserial \
      -out client.crt \
      -extfile <(echo -e "${EXTFILE}")
}

# --------------------------------------- PERMS

fix_perms() {
  chmod 600 ca.key server.key client.key
  chmod 644 ca.crt server.crt client.crt
  rm server.csr client.csr
}

# --------------------------------------- USAGE

display_usage() {
  b="$(tput bold)"
  r="$(tput sgr0)"

  RST="$(tput sgr0)"
  P="${RST}$(tput bold ; tput setaf 3)"
  CODE="${RST}$(tput setaf 6)"
  H1="${RST}$(tput bold ; tput setaf 3)"

  loc="$(readlink -f .)"

  echo "$P
 Files have been created in $CODE$b$loc${P}
 $H1
 === SERVER SETUP ===
 $P
 Prepare your remote server and stop docker service
 $CODE
   local> ${b}ssh remote${CODE}
   remote> ${b}sudo mkdir -pv /etc/docker/tls${CODE}
   remote> ${b}sudo chown root:root /etc/docker/tls${CODE}
   remote> ${b}sudo chmod 711 /etc/docker/tls${CODE}
   remote> ${b}sudo service docker stop${CODE}
 $P
 Send files and setup your remote server
 $CODE
   local> ${b}cd $loc${CODE}
   local> ${b}scp ca.crt server.crt server.key remote.example.com:~${CODE}

   local> ${b}ssh remote${CODE}
   remote> ${b}sudo mv ca.crt server.crt server.key /etc/docker/tls
   remote> ${b}echo 'DOCKER_OPTS=\"\${DOCKER_OPTS} --tlsverify --tlscacert=/etc/docker/tls/ca.crt --tlscert=/etc/docker/tls/server.crt --tlskey=/etc/docker/tls/server.key -H=0.0.0.0:2376 -H unix:///var/run/docker.sock \"' | sudo tee -a /etc/default/docker${CODE}
   remote> ${b}sudo service docker start${CODE}
 $H1
 === CLIENT SETUP ===
 $P
 Prepare your workstation
 $CODE
   local> ${b}mv -v ~/.docker{,.bak_\$(date +%s)}${CODE}
   local> ${b}mkdir -pv ~/.docker${CODE}
 $P
 Copy your files
 $CODE
   local> ${b}cp -v ca.crt ~/.docker/ca.pem${CODE}
   local> ${b}cp -v client.crt ~/.docker/cert.pem${CODE}
   local> ${b}cp -v client.key ~/.docker/key.pem${CODE}
 $P
 Try your new setup
 $CODE
   local> ${b}export DOCKER_HOST=tcp://remote.example.com:2376 DOCKER_TLS_VERIFY=1${CODE}
   local> ${b}docker ps${CODE}
 $RST"
}

# --------------------------------------- MAIN

main() {

  mkdir -p "${CERTS_PATH}"
  cd "${CERTS_PATH}"

  create_ca
  create_server
  create_client
  fix_perms
  display_usage
}

main


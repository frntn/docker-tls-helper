# frntn/docker-tls-helper

Generate certificates for docker client and server.

Automate the process described on *Docker* website to [Protect the Docker daemon socket](https://docs.docker.com/engine/security/https/) in one command.

## Usage

Setup `SRV_SUBJ` and `CLT_SUBJ` environment variable and execute the script :

```bash
curl -sSL https://raw.githubusercontent.com/frntn/docker-tls-helper/master/dockertls.sh | SRV_SUBJ="/CN=remote.example.com" CLT_SUBJ="/CN=Docker Admin CLI" bash
```

Setup `SRV_SAN` environment variable to access your docker server from multiple endpoints :

```bash
curl -sSL https://raw.githubusercontent.com/frntn/docker-tls-helper/master/dockertls.sh | SRV_SAN="DNS:docker.example.com,IP:1.1.1.1,IP:2.2.2.2" SRV_SUBJ="/CN=remote.example.com" CLT_SUBJ="/CN=Docker Admin CLI" bash
```

## Result

Here is a screenshot of the generated ouput :

![official-logo](img/result.png?raw=true)


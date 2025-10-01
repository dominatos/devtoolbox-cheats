Title: 🔐 OpenSSL — CSR with SAN
Group: Security & Crypto
Icon: 🔐
Order: 3

# openssl-san.cnf                               # CSR config with SANs / Конфиг CSR с SAN
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = IT
ST = Emilia-Romagna
L = Ferrara
O = Example
CN = example.com

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com

# Generate:
openssl req -new -newkey rsa:2048 -nodes \      # Create key + CSR / Создать ключ + CSR
  -keyout key.pem -out csr.pem -config openssl-san.cnf


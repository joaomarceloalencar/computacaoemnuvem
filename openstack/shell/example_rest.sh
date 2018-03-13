KEYSTONE_URL="http://200.19.191.241:5000/v3"
COMPUTE_URL="http://200.19.191.241:8774/v2.1/1a0c733c749243c88ad1011a8e4d2355"

# Pegar um token com escopo
curl \
  -H "Content-Type: application/json" \
  -X POST \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "alunoufc",
          "domain": { "id": "default" },
          "password": "1566alunoufc"
        }
      }
    },
    "scope": {
      "project": {
        "name": "computacaoemnuvem",
        "domain": { "id": "default" }
      }
    }
  }
}' $KEYSTONE_URL/auth/tokens | python -m json.tool

# Atualizar OS_TOKEN com o valor retornado em (X-Subject-Token)
OS_TOKEN=

# Listar servidores
curl \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $OS_TOKEN" \
   $COMPUTE_URL/servers | python -m json.tool

# Criar Servidor
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $OS_TOKEN" \
  -d '{
    "server": {
        "name": "testeAPI02",
        "imageRef": "bad71d40-69f2-4a72-a005-8d6a26d44719",
        "flavorRef": "24c8a95a-379e-45d3-a700-a574eda3de0b",
        "key_name" : "alunoufc" 
   }
}' $COMPUTE_URL/servers | python -m json.tool
# Atualizar OS_SERVER_ID com o valor retornado acima
OS_SERVER_ID

# Detalhes de um servidor 
curl \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $OS_TOKEN" \
   $COMPUTE_URL/servers/$OS_SERVER_ID | python -m json.tool



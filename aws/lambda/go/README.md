# Funções Lambda em GO
Exemplos retirados de [Documentação Oficial da AWS] (https://docs.aws.amazon.com/pt_br/lambda/latest/dg/welcome.html)
---
## Gerência das Funções
Para cada uma das 4 funções, os seguintes passos funcionam substituindo o N pelo número da função.

1. Criar a função N:
```bash
go build functionN.go
mv functionN main
zip functionN.zip main
aws lambda create-function \
--function-name functionN \
--runtime go1.x \
--handler main \
--zip-file fileb://functionN.zip \
--role arn:aws:iam::XXXXXXXXXXXX:role/lambda-role
```
O papel ou função designado por _arn:aws:iam::XXXXXXXXXXXX:role/lambda-role_ deve ter permissões para execução funções Lambda e acessar qualquer outro serviço que a função necessite. 

2. Atualizar código da função. Compile o novo objeto e carregue a nova versão:

```bash
aws lambda update-function-code \
--function-name functionN \
--zip-file fileb://functionN.zip
```

3. Remover função
```bash
aws lambda delete-function --function-name my-function
```

## Invocação das Funções

### Função 1
```bash
aws lambda invoke --function-name function1 out --log-type Tail \
--payload '{"name": "Jose da Silva"}' \
--query 'LogResult' --output text |  base64 -d
cat out
```

### Função 2
```bash
aws lambda invoke --function-name function2 out --log-type Tail \
--payload '{ "What is your name?": "Jose da Silva", "How old are you?": 33 }' \
--query 'LogResult' --output text |  base64 -d
cat out
```

### Função 3
```bash
aws lambda invoke --function-name function3 out --log-type Tail \
--query 'LogResult' --output text |  base64 -d
cat out
```

Para esta função executar com sucesso, é necessário trocar _bucketName_ na linha 17 por um _bucket_ válido no S3, na mesma região da função. 

### Função 4
```bash
aws lambda invoke --function-name function4 out --log-type Tail \
--query 'LogResult' --output text |  base64 -d
cat out
```

### Recuperar o último _log_ de qualquer função.

```bash
LASTSTREAM=$(aws logs describe-log-streams \
--log-group-name /aws/lambda/functionN \
--order-by LastEventTime \
--descending \
--max-items 1 | jq .logStreams[0].logStreamName | sed 's/\"//g')
aws logs get-log-events --log-group-name /aws/lambda/functionN --log-stream-name $LASTSTREAM
```
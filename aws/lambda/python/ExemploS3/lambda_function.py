import json
import boto3

# Função que enumera as linhas de um arquivo de texto colocado no bucket
def lambda_handler(event, context):
    # Recupera informações do arquivo
    object_name = event['Records'][0]['s3']['object']['key']
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    print("Arquivo % adicionado em %s" % (object_name, bucket_name))
    
    # baixa o conteúdo do arquivo em temp.txt
    s3 = boto3.client('s3')
    with open("/tmp/temp.txt", 'wb') as f:
       s3.download_fileobj(bucket_name, object_name, f)
    f.close()   
       
    # numera as linhas do arquivo
    i = 0
    temp = open("/tmp/temp.txt", "r")
    newtemp = open("/tmp/new_temp.txt","w")
    for l in temp.readlines():
        newtemp.write(str(i) + ":" + l)
        i = i + 1
    newtemp.close()
    
    # copia para o bucket a nova versão
    s3.upload_file("/tmp/new_temp.txt", bucket_name, object_name + ".enum")
       
    return {
        'statusCode': 200,
        'body': json.dumps(object_name)
    }
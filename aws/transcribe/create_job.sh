#!/bin/bash
# Recebe o arquivo de aúdio, coloca em um Bucket, faz a trancrição e retorna o json
# É necessário o comando jq instalado: sudo apt install jq
ARQUIVO=$1
BUCKET=$2

# Colocar o arquivo no Bucket
#aws s3 cp $ARQUIVO s3://$BUCKET/

# Criar JSON para o JOB
HORARIO=`date +%H%M%S`
cat > job$HORARIO.json <<EOF
{
    "TranscriptionJobName": "job$HORARIO", 
    "LanguageCode": "pt-BR", 
    "MediaFormat": "wav", 
    "Media": {
        "MediaFileUri": "s3://$BUCKET/$ARQUIVO"
    }
}
EOF

# Submeter para o serviço Transcribe
aws transcribe start-transcription-job --cli-input-json file://job$HORARIO.json 

# Esperar a conclusão
STATUS="IN_PROGRESS"
while [ "$STATUS" == "IN_PROGRESS" ]
do
   STATUS=`aws transcribe list-transcription-jobs --job-name-contains "$HORARIO" | jq '.TranscriptionJobSummaries[0].TranscriptionJobStatus' | sed 's/\"//g'`
   echo $STATUS
   sleep 2
done

# Recuperar a transcrição
URI=`aws transcribe get-transcription-job --transcription-job-name "job$HORARIO" |  jq ".TranscriptionJob.Transcript.TranscriptFileUri" | sed 's/\"//g'`
curl $URI | jq ".results.transcripts[0].transcript"

# Remover o JSON e o Job
rm job$HORARIO.json
aws transcribe delete-transcription-job --transcription-job-name job$HORARIO
import sys
import boto3
import time 
import requests

from botocore.exceptions import ClientError

s3 = boto3.client('s3')
transcribe = boto3.client('transcribe')

if __name__ == "__main__":
    # Coloca o arquivo de áudio no Bucket
    bucketName = sys.argv[1]
    audioFile = sys.argv[2]

    print("Sending audio file %s to Bucket %s" % (audioFile, bucketName))
    try:
       response = s3.upload_file(audioFile, bucketName, audioFile)
    except ClientError as e:
        print(e)
        exit(-1) 

    # Cria a tarefa de transcrição e a submete
    jobName = audioFile.split('.')[0] + str(time.time()).split('.')[0]
    jobUri = "s3://" + bucketName + "/" + audioFile


    print("Creating Transcription Job %s" % jobName)
    transcribe.start_transcription_job(
       TranscriptionJobName=jobName,
       Media={'MediaFileUri': jobUri},
       MediaFormat='wav',
       LanguageCode='pt-BR'
    )

    # Aguarda o termino
    while True:
       status = transcribe.get_transcription_job(TranscriptionJobName=jobName)
       if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED', 'FAILED']:
          break
       print("Processing...")
       time.sleep(5)
    
    print("Done.")
    # Recupera a transcrição e salva em um arquivo
    outputUri = status['TranscriptionJob']['Transcript']['TranscriptFileUri']
    outputResponse = requests.get(outputUri)
    outputFile = open(jobName + '.output', 'w')
    outputFile.write(outputResponse.json()['results']['transcripts'][0]['transcript'])
    outputFile.close()
    print("Output: %s" % (jobName + '.output'))

    # Deleta a tarefa de transcrição
    transcribe.delete_transcription_job(TranscriptionJobName=jobName)
    


    

    
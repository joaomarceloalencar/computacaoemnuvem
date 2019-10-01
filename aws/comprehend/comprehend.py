import boto3
import json
import time
import sys

comprehend = boto3.client('comprehend')

if __name__ == "__main__":
   textFile = sys.argv[1]
   f = open(textFile, 'r')
   text = f.read()
   f.close()

   outputFileName = "comprehend" + str(time.time()).split('.')[0] + ".output"
   outputFile = open(outputFileName, 'w')

   print('Calling DetectDominantLanguage')
   dominantLanguage = comprehend.detect_dominant_language(Text = text)['Languages'][0]['LanguageCode']
   outputFile.write("Dominant Language: %s\n" % dominantLanguage)
   
   print('Calling DetectEntities')
   entities = comprehend.detect_entities(Text=text, LanguageCode=dominantLanguage)['Entities']
   outputFile.write("\nEntities:\n")
   for e in entities:
      outputFile.write("   %s: %s\n" % (e['Type'], e['Text'] ))
   
   print('Calling DetectSentiment')
   sentiment = comprehend.detect_sentiment(Text=text, LanguageCode=dominantLanguage)['Sentiment']
   outputFile.write("\nSentiment: %s\n" % sentiment)
   
   outputFile.close()


import tweepy
import os
import csv
import re
import sys

# Remover os emoticons
# https://gist.github.com/slowkow/7a7f61f495e3dbb7e3d767f97bd7304b
def remove_emoji(string):
   emoji_pattern = re.compile("["
      u"\U0001F600-\U0001F64F"  # emoticons
      u"\U0001F300-\U0001F5FF"  # symbols & pictographs
      u"\U0001F680-\U0001F6FF"  # transport & map symbols
      u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
      u"\U00002702-\U000027B0"
      u"\U000024C2-\U0001F251"
    "]+", flags=re.UNICODE)
   return emoji_pattern.sub(r'', string)

# Recuperando os Tweets
chave_consumidor = os.environ['API_KEY']
segredo_consumidor =  os.environ['API_SECRET_KEY']
token_acesso =  os.environ['ACCESS_TOKEN']
token_acesso_segredo =  os.environ['ACCESS_TOKEN_SECRET']

autenticacao = tweepy.OAuthHandler(chave_consumidor, segredo_consumidor)
autenticacao.set_access_token(token_acesso, token_acesso_segredo)

api = tweepy.API(autenticacao)

tweets = {}

lists = api.lists_all("jmhal", reverse=True)
for l in lists:
    tweets[(l.id_str, l.name)] = []

for k in tweets.keys():
    print("List: %s" % k[1])
    ts = api.list_timeline(list_id=k[0], count=10000, tweet_mode="extended")
    for t in ts:
        tweets[(k[0],k[1])].append(t.full_text)

# Escrevendo no CSV
with open('tweets.csv', mode='w') as tweets_file:
    tweets_writer = csv.writer(tweets_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)

    for k in tweets.keys():
        for t in tweets[k]:
            tweets_writer.writerow([k[1], remove_emoji(t.replace('\n',''))])
     







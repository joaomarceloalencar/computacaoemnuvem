# Não funciona com APIs HTTP. 
# Necessário API REST configurada como Proxy
import awsgi
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return ''' 
    <html>
        <head>
            <title>API HTTP STACK</title>
        </head>
        <body>
            <h1> Olá Mundo. </h1>
        </body>
    </html>
    '''


def lambda_handler(event, context):
    return awsgi.response(app, event, context, base64_content_types={"image/png"})


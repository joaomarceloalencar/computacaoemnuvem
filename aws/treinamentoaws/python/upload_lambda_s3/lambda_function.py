# Não funciona com APIs HTTP. 
# Necessário API REST configurada como Proxy
import boto3
import awsgi
import os
from flask import Flask, render_template, flash, redirect, request
from flask_wtf import FlaskForm
from wtforms import FileField, SubmitField
from wtforms.validators import DataRequired
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config['SECRET_KEY'] = 'you-will-never-guess'
s3_client = boto3.client('s3')

class UploadForm(FlaskForm):
    file = FileField('Arquivo:', validators=[DataRequired()])
    submit = SubmitField('Enviar')

@app.route('/', methods=['GET', 'POST'])
@app.route('/index', methods=['GET', 'POST'])

def index():
    form = UploadForm()
    if request.method == 'POST':
        f = request.files['file']
        f.save('/tmp/' + secure_filename(f.filename))
        s3_client.upload_file('/tmp/' + f.filename, 'treinamentoawsufcqx', f.filename)
        os.remove('/tmp/' + f.filename)

    return ''' 
    <html>
        <head>
            <title>API HTTP STACK</title>
        </head>
        <body>
            <h1> Arquivo ''' + f.filename + ''' salvo no bucket. </h1>
        </body>
    </html>
    '''


def lambda_handler(event, context):
    return awsgi.response(app, event, context, base64_content_types={"image/png"})


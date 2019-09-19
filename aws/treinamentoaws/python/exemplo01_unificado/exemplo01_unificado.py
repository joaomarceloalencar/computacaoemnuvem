from flask import Flask, render_template, flash, redirect, request
from flask_wtf import FlaskForm
from wtforms import FileField, SubmitField
from wtforms.validators import DataRequired
from werkzeug import secure_filename

app = Flask(__name__)
app.config['SECRET_KEY'] = 'you-will-never-guess'

class UploadForm(FlaskForm):
    file = FileField('Arquivo:', validators=[DataRequired()])
    submit = SubmitField('Enviar')

@app.route('/', methods=['GET', 'POST'])
@app.route('/index', methods=['GET', 'POST'])
def index():
    form = UploadForm()
    if request.method == 'POST':
       f = request.files['file']
       f.save(secure_filename(f.filename))
       return redirect('/index')
    return render_template('index.html', title='AWS Upload de Arquivo', form=form)




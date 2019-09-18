#!/bin/bash

# Instalar as dependências
apt-get update
apt-get -y install python3-venv python3-pip
pip3 install flask flask-wtf

# Executar aplicação como usuário ubuntu
sudo -i -u ubuntu bash<<EOF
cd ~ubuntu
git clone https://github.com/jmhal/computacaoemnuvem
cd computacaoemnuvem/aws/treinamentoaws/python/hello_world
export FLASK_APP=hello_world.py
flask run --host=0.0.0.0 &
EOF

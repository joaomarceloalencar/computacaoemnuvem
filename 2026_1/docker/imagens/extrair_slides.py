#!/usr/bin/env python3
"""Extrai páginas específicas dos PDFs do módulo Docker e recorta cabeçalho/rodapé."""

import subprocess
import os
from PIL import Image

BASE_PDF = "/Users/jmhal/source/disciplinas/computacaoemnuvem"
BASE_IMG = "/Users/jmhal/source/disciplinas/computacaoemnuvem/2026_1/docker/imagens"


def extract_slide(pdf_path, page_num, output_path,
                  crop_top_pct=0.28, crop_bottom_pct=0.22, dpi=150):
    tmp_path = output_path + ".tmp.png"
    cmd = [
        "gs", "-dBATCH", "-dNOPAUSE", "-dSAFER",
        "-sDEVICE=png16m",
        f"-r{dpi}",
        f"-dFirstPage={page_num}",
        f"-dLastPage={page_num}",
        f"-sOutputFile={tmp_path}",
        pdf_path,
    ]
    subprocess.run(cmd, check=True, capture_output=True)
    img = Image.open(tmp_path)
    w, h = img.size
    top = int(h * crop_top_pct)
    bottom = int(h * (1 - crop_bottom_pct))
    cropped = img.crop((0, top, w, bottom))
    cropped.save(output_path, optimize=True)
    os.remove(tmp_path)
    print(f"  {os.path.basename(output_path)}  {cropped.size[0]}x{cropped.size[1]}px")


SLIDES = [
    # (pdf,  page,  nome_saida)
    ("01_Introducao_Docker.pdf",          2,  "01_conteineres_kernel.png"),
    ("01_Introducao_Docker.pdf",          4,  "01_arquitetura_docker_kernel.png"),
    ("01_Introducao_Docker.pdf",          6,  "01_arquitetura_vms.png"),
    ("01_Introducao_Docker.pdf",          7,  "01_arquitetura_vms_docker.png"),
    ("01_Introducao_Docker.pdf",          8,  "01_arquitetura_docker.png"),
    ("03_Composicao_de_Conteineres.pdf",  6,  "03_proxy_reverso_nginx.png"),
]

for pdf_name, page, out_name in SLIDES:
    pdf_path = os.path.join(BASE_PDF, pdf_name)
    out_path = os.path.join(BASE_IMG, out_name)
    print(f"Extraindo {pdf_name} p.{page}...")
    try:
        extract_slide(pdf_path, page, out_path)
    except Exception as e:
        print(f"  ERRO: {e}")

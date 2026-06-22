#!/usr/bin/env python3
"""Extrai diagramas dos PDFs do módulo GitHub Actions, recortando logo/rodapé."""

import subprocess
import os
from PIL import Image

BASE_PDF = "/Users/jmhal/source/disciplinas/computacaoemnuvem"
BASE_IMG = "/Users/jmhal/source/disciplinas/computacaoemnuvem/2026_1/github_actions/imagens"


def extract_slide(pdf_path, page_num, output_path, box, dpi=150):
    """box = (left, top, right, bottom) em frações da imagem."""
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
    l, t, r, b = box
    cropped = img.crop((int(w * l), int(h * t), int(w * r), int(h * b)))
    cropped.save(output_path, optimize=True)
    os.remove(tmp_path)
    print(f"  {os.path.basename(output_path)}  {cropped.size[0]}x{cropped.size[1]}px")


SLIDES = [
    # (pdf, page, nome_saida, (left, top, right, bottom))
    ("01_Entendendo_GitHub_Actions.pdf", 4,  "01_componentes_runner_job.png", (0.44, 0.37, 0.99, 0.62)),
    ("01_Entendendo_GitHub_Actions.pdf", 10, "01_hierarquia_workflow.png",    (0.09, 0.27, 0.97, 0.73)),
    ("02_Fluxos_de_Trabalho.pdf",        5,  "02_usando_modelos.png",         (0.15, 0.365, 0.80, 0.82)),
]

for pdf_name, page, out_name, box in SLIDES:
    pdf_path = os.path.join(BASE_PDF, pdf_name)
    out_path = os.path.join(BASE_IMG, out_name)
    print(f"Extraindo {pdf_name} p.{page}...")
    try:
        extract_slide(pdf_path, page, out_path, box)
    except Exception as e:
        print(f"  ERRO: {e}")

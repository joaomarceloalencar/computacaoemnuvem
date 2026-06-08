#!/usr/bin/env python3
"""Extrai páginas específicas dos PDFs e recorta o cabeçalho/rodapé FGV."""

import subprocess
import os
from PIL import Image

BASE_PDF = "/Users/jmhal/source/disciplinas/computacaoemnuvem/02_Git"
BASE_IMG = "/Users/jmhal/source/disciplinas/computacaoemnuvem/2026_1/git/imagens"


def extract_slide(pdf_path, page_num, output_path,
                  crop_top_pct=0.18, crop_bottom_pct=0.10, dpi=150):
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
    ("01_Controle_de_Versao.pdf",  4,  "01_repositorio_servidor.png"),
    ("01_Controle_de_Versao.pdf",  8,  "01_branches_tags.png"),
    ("02_Github.pdf",              5,  "02_criar_repositorio_ui.png"),
    ("02_Github.pdf",              6,  "02_criar_repositorio_form.png"),
    ("03_Ferramenta_Git.pdf",      5,  "03_working_stage_local.png"),
    ("03_Ferramenta_Git.pdf",      8,  "03_git_diff.png"),
    ("03_Ferramenta_Git.pdf",      9,  "03_git_status.png"),
    ("03_Ferramenta_Git.pdf",      11, "03_push_pull.png"),
    ("04_Branches.pdf",            6,  "04_commit_graph.png"),
    ("04_Branches.pdf",            7,  "04_commit_graph_head.png"),
    ("04_Branches.pdf",            8,  "04_commit_graph_main.png"),
    ("04_Branches.pdf",            9,  "04_commit_graph_calculator.png"),
    ("05_Integração_Git.pdf",      5,  "05_gitflow_diagrama.png"),
]

for pdf_name, page, out_name in SLIDES:
    pdf_path = os.path.join(BASE_PDF, pdf_name)
    out_path = os.path.join(BASE_IMG, out_name)
    print(f"Extraindo {pdf_name} p.{page}...")
    try:
        extract_slide(pdf_path, page, out_path)
    except Exception as e:
        print(f"  ERRO: {e}")

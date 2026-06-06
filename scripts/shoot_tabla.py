import os, glob
from playwright.sync_api import sync_playwright

ROOT = "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
URL = f"file://{ROOT}/ligas_tabla.html"
OUT = f"{ROOT}/cards/06_ligas_tabla.png"

cands = sorted(glob.glob(os.path.expanduser(
    "~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome")))
EXE = cands[-1] if cands else None

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=EXE)
    page = browser.new_page(viewport={"width": 900, "height": 1200},
                            device_scale_factor=2)
    page.goto(URL, wait_until="networkidle")
    page.wait_for_timeout(800)
    tbl = page.query_selector("table")
    (tbl or page).screenshot(path=OUT)
    print("OK", OUT)
    browser.close()

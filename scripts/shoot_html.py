import os
from playwright.sync_api import sync_playwright

URL = "file:///home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina/index.html"
OUT = "/tmp"

shots = [
    ("plantel_arq", 'h2:has-text("línea por línea")', 0),
    ("plantel_def", "#galeria-defensores", -80),
    ("campeones",   "#cr-camp", -100),
    ("mapa",        "#cr-mapa", -100),
    ("edad",        "#cr-edad", -100),
    ("caps",        "#cr-caps", -100),
    ("goles",       'h2:has-text("Los goles")', 240),
]

# El browser bundled de playwright apunta a una build que no está instalada;
# usamos el chromium ya descargado en ~/.cache/ms-playwright (full chrome).
import glob
cands = sorted(glob.glob(os.path.expanduser(
    "~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome")))
EXE = cands[-1] if cands else None

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=EXE)
    page = browser.new_page(viewport={"width": 1366, "height": 920})
    page.goto(URL, wait_until="networkidle")
    page.wait_for_timeout(1500)
    for name, sel, extra in shots:
        el = page.query_selector(sel)
        if not el:
            print("MISS", sel); continue
        el.scroll_into_view_if_needed()
        if extra:
            page.evaluate(f"window.scrollBy(0,{extra})")
        page.wait_for_timeout(950)
        page.screenshot(path=f"{OUT}/sec_{name}.png")
        print("OK", name)
    browser.close()

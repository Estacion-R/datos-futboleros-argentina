import os, glob
from playwright.sync_api import sync_playwright

URL = "file:///home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina/index.html"
OUT = "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina/previews/revision"
os.makedirs(OUT, exist_ok=True)

cands = sorted(glob.glob(os.path.expanduser(
    "~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome")))
EXE = cands[-1] if cands else None

def shoot_el(page, el, path):
    el.scroll_into_view_if_needed()
    page.wait_for_timeout(700)
    el.screenshot(path=path)

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=EXE)
    page = browser.new_page(viewport={"width": 1280, "height": 1000},
                            device_scale_factor=2)
    page.goto(URL, wait_until="networkidle")
    page.wait_for_timeout(2500)

    cells = page.query_selector_all(".cell")            # 0-3 galerías, 5 scatter, 6 valor, 7 ligas
    print("n cells:", len(cells))

    # Galerías (las 4 tablas gt por línea)
    for i, name in [(0, "01_galeria_arq"), (1, "02_galeria_def"),
                    (2, "03_galeria_med"), (3, "04_galeria_del")]:
        if i < len(cells):
            shoot_el(page, cells[i], f"{OUT}/{name}.png"); print("OK", name)
        else:
            print("MISS", name)

    # Closeread (imágenes sticky)
    for sel, name in [("#cr-camp", "05_campeones"), ("#cr-mapa", "06_mapa"),
                      ("#cr-edad", "07_edad"), ("#cr-ext", "09_exterior")]:
        el = page.query_selector(sel)
        if el: shoot_el(page, el, f"{OUT}/{name}.png"); print("OK", name)
        else: print("MISS", name, sel)

    # Scatter (cell 5) y valor packing (cell 6) y ligas (cell 7)
    for i, name in [(5, "08_scatter"), (6, "10_valor"), (7, "11_ligas")]:
        if i < len(cells):
            shoot_el(page, cells[i], f"{OUT}/{name}.png"); print("OK", name)
        else:
            print("MISS", name)

    # Goles
    g = page.query_selector(".galeria-todos")
    if g: shoot_el(page, g, f"{OUT}/12_goles.png"); print("OK 12_goles")
    else: print("MISS 12_goles")

    browser.close()

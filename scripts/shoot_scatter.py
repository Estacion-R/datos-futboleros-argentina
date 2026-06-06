import os, glob
from playwright.sync_api import sync_playwright

URL = "file:///home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina/index.html"
OUT = "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina/previews"
os.makedirs(OUT, exist_ok=True)

cands = sorted(glob.glob(os.path.expanduser(
    "~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome")))
EXE = cands[-1] if cands else None

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=EXE)
    page = browser.new_page(viewport={"width": 1280, "height": 980})
    page.goto(URL, wait_until="networkidle")
    page.wait_for_timeout(1500)
    h2 = page.query_selector('h2:has-text("Experiencia mundialista")')
    if not h2:
        print("MISS h2"); browser.close(); raise SystemExit
    h2.scroll_into_view_if_needed()
    page.wait_for_timeout(700)
    # vista del copy + arranque del scatter
    page.screenshot(path=f"{OUT}/scatter_html_top.png")
    print("OK top")
    # bajar para centrar el widget del scatter
    page.evaluate("window.scrollBy(0,360)")
    page.wait_for_timeout(900)
    page.screenshot(path=f"{OUT}/scatter_html.png")
    print("OK scatter")
    # simular hover sobre un punto para evidenciar el tooltip interactivo
    pt = page.query_selector('[data-id="Lionel Messi"]')
    if pt:
        pt.hover()
        page.wait_for_timeout(700)
        page.screenshot(path=f"{OUT}/scatter_html_hover.png")
        print("OK hover")
    else:
        print("MISS messi point")
    browser.close()

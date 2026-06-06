# Captura un HTML de widget ggiraph; hover opcional sobre un data-id.
# Uso: python3 R/_shoot_widget.py <html> <out.png> [data_id]
import sys, glob, os
from playwright.sync_api import sync_playwright

inp = "file://" + os.path.abspath(sys.argv[1])
out = sys.argv[2]
did = sys.argv[3] if len(sys.argv) > 3 else None
cands = sorted(glob.glob(os.path.expanduser(
    "~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome")))
EXE = cands[-1] if cands else None

with sync_playwright() as p:
    b = p.chromium.launch(executable_path=EXE)
    pg = b.new_page(viewport={"width": 900, "height": 940}, device_scale_factor=2)
    pg.goto(inp, wait_until="networkidle")
    pg.wait_for_timeout(900)
    if did:
        el = pg.query_selector(f'[data-id="{did}"]')
        if el:
            box = el.bounding_box()
            pg.mouse.move(box["x"] + box["width"]/2, box["y"] + box["height"]/2)
            pg.wait_for_timeout(800)
            print("hover OK", did)
        else:
            print("data-id NO encontrado", did)
    pg.screenshot(path=out, full_page=True)
    print("OK", out)
    b.close()

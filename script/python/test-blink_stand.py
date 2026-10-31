import os
import time
from playwright.sync_api import sync_playwright

def test_blink():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(os.path.dirname(current_dir))
    file_path = f"file:///{os.path.join(repo_root, 'public', 'page-apps.html').replace(os.sep, '/')}"

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1280, "height": 800})
        page.goto(file_path, wait_until='networkidle')

        prompt = page.locator('#cliPromptLine')
        frame1 = os.path.join(repo_root, 'frame_visible.png')
        prompt.screenshot(path=frame1)

        # Wait 500ms for blink half-cycle
        page.wait_for_timeout(500)
        frame2 = os.path.join(repo_root, 'frame_blinked.png')
        prompt.screenshot(path=frame2)

        browser.close()
        print("FRAMES_CAPTURED")

if __name__ == "__main__":
    test_blink()

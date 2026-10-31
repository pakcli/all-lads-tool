import os
from playwright.sync_api import sync_playwright

def take_screenshot():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = f"file:///{os.path.join(current_dir, 'index.html').replace(os.sep, '/')}"

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        
        page.set_viewport_size({"width": 1920, "height": 1080})
        
        print(f"Navigating to {file_path}")
        page.goto(file_path, wait_until='networkidle')
        
        screenshot_path = os.path.join(current_dir, 'screenshot.png')
        page.screenshot(path=screenshot_path, full_page=True)
        
        print(f"Screenshot successfully saved to: {screenshot_path}")
        browser.close()

if __name__ == "__main__":
    take_screenshot()

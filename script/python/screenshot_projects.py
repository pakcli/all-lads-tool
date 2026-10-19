import os
import re
from playwright.sync_api import sync_playwright
from PIL import Image

def get_dynamic_projects():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, '..', '..', '..'))
    apps_dir = os.path.join(repo_root, 'apps')
    projects = {}
    if os.path.exists(apps_dir):
        for item in sorted(os.listdir(apps_dir)):
            if item.startswith('_') or item.startswith('.'):
                continue
            item_path = os.path.join(apps_dir, item)
            if os.path.isdir(item_path):
                index_path = os.path.join(item_path, 'index.html')
                if os.path.exists(index_path):
                    projects[item] = item_path
    return projects, repo_root

def capture_real_project_screenshots():
    projects, repo_root = get_dynamic_projects()
    current_dir = os.path.dirname(os.path.abspath(__file__))
    img_dir = os.path.join(current_dir, 'img')
    css_path = os.path.join(repo_root, 'public', 'style.css')
    os.makedirs(img_dir, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        page.set_viewport_size({"width": 1440, "height": 900})

        for pid, folder_path in projects.items():
            index_path = os.path.join(folder_path, 'index.html')
            file_url = f"file:///{index_path.replace(os.sep, '/')}"

            print(f"Navigating to real project [{pid}]: {file_url}")
            try:
                page.goto(file_url, wait_until='networkidle', timeout=10000)
            except Exception as e:
                print(f"Notice during load: {e}")
                page.wait_for_timeout(1000)

            page.wait_for_timeout(800)

            raw_path = os.path.join(img_dir, f"raw-{pid}.png")
            page.screenshot(path=raw_path, full_page=False)

            thumb_filename = f"thumb-{pid}.webp"
            thumb_path = os.path.join(img_dir, thumb_filename)
            with Image.open(raw_path) as img:
                img.thumbnail((600, 400))
                img.save(thumb_path, 'WEBP', quality=70)
                print(f"Successfully generated thumbnail for [{pid}]: {thumb_path}")

            if os.path.exists(raw_path):
                os.remove(raw_path)

        browser.close()

    # Update CSS with generated WebP background rules if css_path exists
    if os.path.exists(css_path):
        print("Updating CSS with individual real project card backgrounds...")
        with open(css_path, 'r', encoding='utf-8') as f:
            css_content = f.read()

        css_content = re.sub(r'/\* BEGIN GENERATED THUMBNAILS \*/.*?/\* END GENERATED THUMBNAILS \*/', '', css_content, flags=re.DOTALL)

        new_rules = ["\n/* BEGIN GENERATED THUMBNAILS */"]
        for pid in projects.keys():
            thumb_filename = f"thumb-{pid}.webp"
            new_rules.append(f"""
.proj-tab-card[data-project-id="{pid}"] {{
  background-image: linear-gradient(rgba(250, 248, 245, 0.90), rgba(250, 248, 245, 0.90)), url('../img/{thumb_filename}') !important;
}}
.proj-tab-card[data-project-id="{pid}"].active {{
  background-image: linear-gradient(rgba(255, 255, 255, 0.85), rgba(255, 255, 255, 0.85)), url('../img/{thumb_filename}') !important;
}}
.case-card[data-project-id="{pid}"] {{
  background-image: linear-gradient(rgba(255, 255, 255, 0.92), rgba(255, 255, 255, 0.92)), url('../img/{thumb_filename}');
  background-size: cover;
  background-position: center;
}}
""")
        new_rules.append("/* END GENERATED THUMBNAILS */\n")

        css_content += "\n".join(new_rules)

        with open(css_path, 'w', encoding='utf-8') as f:
            f.write(css_content)

        print("CSS successfully updated with real project website thumbnails!")

if __name__ == "__main__":
    capture_real_project_screenshots()

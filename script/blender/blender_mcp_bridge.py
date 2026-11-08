"""
Blender Live MCP / AI Bridge
Runs inside Blender's Scripting workspace or as an Addon.
Listens on http://127.0.0.1:9871 for commands from AI agents.
Executes bpy commands safely on Blender's main thread using bpy.app.timers.
"""

import bpy
import json
import queue
import sys
import io
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 9871
COMMAND_QUEUE = queue.Queue()
SERVER_INSTANCE = None

class BlenderCommandHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/status":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            status = {
                "status": "online",
                "blender_version": bpy.app.version_string,
                "scene": bpy.context.scene.name if bpy.context.scene else None
            }
            self.wfile.write(json.dumps(status).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == "/execute":
            content_length = int(self.headers.get("Content-Length", 0))
            post_data = self.rfile.read(content_length).decode("utf-8")
            try:
                data = json.loads(post_data)
                code = data.get("code", "")
            except Exception as e:
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": f"Invalid JSON: {str(e)}"}).encode("utf-8"))
                return

            response_event = threading.Event()
            result_holder = {}

            # Push to main thread queue
            COMMAND_QUEUE.put((code, response_event, result_holder))

            # Wait for execution on main thread
            response_event.wait(timeout=30.0)

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(result_holder).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # Silence default terminal request logging
        pass

import os

# Use explicit absolute workspace path so it works in Blender Text Editor where __file__ is undefined
WORKSPACE_DIR = r"E:\proj\all-lads-tool\script\blender"
COMMAND_FILE = os.path.join(WORKSPACE_DIR, "command.py")
OUTPUT_FILE = os.path.join(WORKSPACE_DIR, "output.json")

def check_file_commands():
    """Polls command.py file for sandbox-friendly communication"""
    if os.path.exists(COMMAND_FILE) and os.path.getsize(COMMAND_FILE) > 0:
        try:
            with open(COMMAND_FILE, "r", encoding="utf-8") as f:
                code = f.read().strip()
            
            if not code:
                return

            # Clear command file immediately to prevent re-runs
            with open(COMMAND_FILE, "w", encoding="utf-8") as f:
                f.write("")

            old_stdout = sys.stdout
            old_stderr = sys.stderr
            redirected_output = io.StringIO()
            sys.stdout = redirected_output
            sys.stderr = redirected_output

            result = {}
            try:
                exec_globals = {
                    "bpy": bpy,
                    "context": bpy.context,
                    "data": bpy.data,
                    "scene": bpy.context.scene
                }
                exec(code, exec_globals)
                result["status"] = "success"
                result["output"] = redirected_output.getvalue()
            except Exception as e:
                result["status"] = "error"
                result["error"] = str(e)
                result["output"] = redirected_output.getvalue()
            finally:
                sys.stdout = old_stdout
                sys.stderr = old_stderr

            with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
                json.dump(result, f, indent=2)

        except Exception as err:
            pass

def process_command_queue():
    """Executed by bpy.app.timers on Blender's main thread"""
    check_file_commands()
    
    while not COMMAND_QUEUE.empty():
        try:
            code, response_event, result_holder = COMMAND_QUEUE.get_nowait()
        except queue.Empty:
            break

        old_stdout = sys.stdout
        old_stderr = sys.stderr
        redirected_output = io.StringIO()
        sys.stdout = redirected_output
        sys.stderr = redirected_output

        try:
            # Expose useful globals directly
            exec_globals = {
                "bpy": bpy,
                "context": bpy.context,
                "data": bpy.data,
                "scene": bpy.context.scene
            }
            exec(code, exec_globals)
            result_holder["status"] = "success"
            result_holder["output"] = redirected_output.getvalue()
        except Exception as e:
            result_holder["status"] = "error"
            result_holder["error"] = str(e)
            result_holder["output"] = redirected_output.getvalue()
        finally:
            sys.stdout = old_stdout
            sys.stderr = old_stderr
            response_event.set()

    return 0.05  # Run again in 50ms

def start_server():
    global SERVER_INSTANCE
    
    # Always register timer if not active
    if not bpy.app.timers.is_registered(process_command_queue):
        bpy.app.timers.register(process_command_queue, persistent=True)
    
    # Execute any pending command immediately on startup
    check_file_commands()

    print(f"\n==========================================")
    print(f" [OK] Blender AI File Bridge Active!")
    print(f" Watching: {COMMAND_FILE}")
    print(f"==========================================\n")

if __name__ == "__main__":
    start_server()

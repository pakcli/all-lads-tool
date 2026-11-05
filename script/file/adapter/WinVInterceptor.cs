using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace PolyClipHooks {
    public class WinVInterceptor {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private const int WM_KEYUP = 0x0101;
        private const int WM_SYSKEYDOWN = 0x0104;
        private const int WM_SYSKEYUP = 0x0105;
        private const int VK_V = 0x56;
        private const int VK_LWIN = 0x5B;
        private const int VK_RWIN = 0x5C;
        private const byte VK_MASK = 0xE8;

        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
        private static LowLevelKeyboardProc _proc = HookCallback;
        private static IntPtr _hookID = IntPtr.Zero;

        public static Action OnWinVPressed;
        public static Action OnClipboardChanged;

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        private static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll")]
        private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool AddClipboardFormatListener(IntPtr hwnd);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool RemoveClipboardFormatListener(IntPtr hwnd);

        private class ListenerForm : Form {
            private const int WM_CLIPBOARDUPDATE = 0x031D;
            public ListenerForm() {
                AddClipboardFormatListener(this.Handle);
            }
            protected override void WndProc(ref Message m) {
                if (m.Msg == WM_CLIPBOARDUPDATE) {
                    if (OnClipboardChanged != null) {
                        OnClipboardChanged();
                    }
                }
                base.WndProc(ref m);
            }
            protected override void Dispose(bool disposing) {
                RemoveClipboardFormatListener(this.Handle);
                base.Dispose(disposing);
            }
        }

        private static ListenerForm _listenerWindow;

        public static void Start() {
            if (_hookID == IntPtr.Zero) {
                using (Process curProcess = Process.GetCurrentProcess())
                using (ProcessModule curModule = curProcess.MainModule) {
                    _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);
                }
            }
            if (_listenerWindow == null) {
                _listenerWindow = new ListenerForm();
            }
        }

        public static void Stop() {
            if (_hookID != IntPtr.Zero) {
                UnhookWindowsHookEx(_hookID);
                _hookID = IntPtr.Zero;
            }
            if (_listenerWindow != null) {
                _listenerWindow.Dispose();
                _listenerWindow = null;
            }
        }

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
            if (nCode >= 0) {
                int msg = (int)wParam;
                int vkCode = Marshal.ReadInt32(lParam);

                if (vkCode == VK_V) {
                    bool isLWin = (GetAsyncKeyState(VK_LWIN) & 0x8000) != 0;
                    bool isRWin = (GetAsyncKeyState(VK_RWIN) & 0x8000) != 0;

                    if (isLWin || isRWin) {
                        if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
                            keybd_event(VK_MASK, 0, 0, 0);
                            keybd_event(VK_MASK, 0, 2, 0);

                            if (OnWinVPressed != null) {
                                OnWinVPressed();
                            }
                        }
                        return (IntPtr)1; // Consume Win+V: Native Windows Clipboard popup is completely blocked!
                    }
                }
            }
            return CallNextHookEx(_hookID, nCode, wParam, lParam);
        }
    }
}

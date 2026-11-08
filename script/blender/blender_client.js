/**
 * Client to communicate with Blender Live AI Bridge
 */

export async function checkBlenderStatus() {
    try {
        const res = await fetch("http://127.0.0.1:9871/status");
        if (res.ok) {
            return await res.json();
        }
        return { status: "offline" };
    } catch (e) {
        return { status: "offline", error: e.message };
    }
}

export async function executeBlenderCode(code) {
    const res = await fetch("http://127.0.0.1:9871/execute", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code })
    });
    return await res.json();
}

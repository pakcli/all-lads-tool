---
name: client-side-rendering
aliases: [client-side-rendering, csr-architecture, client-side-render-engine, reactive-client-mount]
category: FRONTEND_ARCHITECTURE
tags: [all-lads-tool, ui, frontend, client-side-rendering, csr, dom, lifecycle, airgap]
trigger: on_demand
description: Standardized architecture and lifecycle protocol for client-side rendering (CSR) across Obsidian views, web components, and standalone tools with zero external dependencies.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Client-Side Rendering Architecture Protocol (`client-side-rendering`)

> [!INFO]
> Domain: Obsidian Plugin Views, Web Toolkits, Vanilla JS Components, Cartridges  
> Core Invariant: Pure client-side execution, zero external runtime CDN dependencies, deterministic lifecycle (mount/render/update/destroy), safe DOM construction.

---

## 1. Architectural Invariants

1. **Airgap-Ready & Zero Network Dependency**:
   All rendering logic, templates, and styles must execute entirely within the local client runtime (Browser or Obsidian Electron process). Never import external scripts or fonts via CDN.

2. **Deterministic Component Lifecycle**:
   Every client-rendered surface must implement four explicit lifecycle phases:
   - `mount(containerEl)`: Binds component to parent DOM container.
   - `render(state)`: Computes and renders DOM nodes from the provided state.
   - `update(newState)`: Replaces or patches DOM nodes when reactive state changes.
   - `destroy()`: Unbinds event listeners, cancels animation frames/timers, and cleans up DOM to prevent memory leaks.

3. **Pure State Projection**:
   The rendered DOM must strictly be a pure function of state:
   $$\text{DOM} = f(\text{State})$$
   Avoid mutating DOM nodes outside of state update pipelines.

4. **Safe DOM Construction**:
   Never inject unsanitized user strings into `innerHTML`. Use `document.createElement`, `textContent`, or Obsidian's native `createDiv()` / `createEl()` helpers.

---

## 2. Standard Implementation Patterns

### Pattern A: Vanilla Reactive Client Component (Zero Framework)

```javascript
export class ClientViewComponent {
    constructor(containerEl, initialState = {}) {
        this.containerEl = containerEl;
        this.state = new Proxy({ ...initialState }, {
            set: (target, prop, value) => {
                target[prop] = value;
                this.render();
                return true;
            }
        });
        this.eventListeners = [];
    }

    mount() {
        this.render();
    }

    render() {
        // Clean existing children
        while (this.containerEl.firstChild) {
            this.containerEl.removeChild(this.containerEl.firstChild);
        }

        const fragment = document.createDocumentFragment();

        const wrapper = document.createElement("div");
        wrapper.className = "client-view-root";

        const title = document.createElement("h2");
        title.textContent = this.state.title || "Default View";
        wrapper.appendChild(title);

        const button = document.createElement("button");
        button.type = "button";
        button.textContent = `Count: ${this.state.count || 0}`;

        const clickHandler = () => {
            this.state.count = (this.state.count || 0) + 1;
        };
        button.addEventListener("click", clickHandler);
        this.eventListeners.push({ target: button, type: "click", handler: clickHandler });

        wrapper.appendChild(button);
        fragment.appendChild(wrapper);
        this.containerEl.appendChild(fragment);
    }

    destroy() {
        // Teardown event listeners to prevent memory leaks
        for (const { target, type, handler } of this.eventListeners) {
            target.removeEventListener(type, handler);
        }
        this.eventListeners = [];
        while (this.containerEl.firstChild) {
            this.containerEl.removeChild(this.containerEl.firstChild);
        }
    }
}
```

---

### Pattern B: Native Obsidian ItemView Client Rendering

```typescript
import { ItemView, WorkspaceLeaf } from "obsidian";

export const CLIENT_VIEW_TYPE = "pakcli-client-view";

export class ClientSideView extends ItemView {
    private state: { items: string[]; loading: boolean };

    constructor(leaf: WorkspaceLeaf) {
        super(leaf);
        this.state = { items: [], loading: false };
    }

    getViewType(): string {
        return CLIENT_VIEW_TYPE;
    }

    getDisplayText(): string {
        return "Client Dashboard";
    }

    async onOpen(): Promise<void> {
        this.render();
    }

    async onClose(): Promise<void> {
        this.contentEl.empty();
    }

    public updateState(partialState: Partial<{ items: string[]; loading: boolean }>): void {
        this.state = { ...this.state, ...partialState };
        this.render();
    }

    private render(): void {
        const root = this.contentEl;
        root.empty();

        const shell = root.createDiv({ cls: "client-shell" });
        shell.createEl("h3", { text: "Active Client View" });

        if (this.state.loading) {
            shell.createDiv({ cls: "client-loading", text: "Loading data..." });
            return;
        }

        const list = shell.createEl("ul", { cls: "client-item-list" });
        for (const item of this.state.items) {
            list.createEl("li", { text: item });
        }
    }
}
```

---

## 3. Memory Leak Prevention & Teardown Checklist

- [ ] All `addEventListener` calls registered on external objects (`window`, `document`) must be removed in `destroy()` / `onClose()`.
- [ ] Active `setInterval`, `setTimeout`, or `requestAnimationFrame` IDs must be cancelled during unmount.
- [ ] MutationObservers and ResizeObservers must invoke `.disconnect()`.
- [ ] References to detached DOM elements must be set to `null` to allow garbage collection.
- [ ] No unhandled Promise rejections during asynchronous DOM hydration.

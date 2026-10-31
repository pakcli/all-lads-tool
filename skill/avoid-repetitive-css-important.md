---
name: avoid-repetitive-css-important
aliases: [no-repetitive-important, css-specificity-rules, avoid-css-important-spam, clean-scss-specificity]
category: CODE_STANDARDS
tags: [all-lads-tool, css, scss, specificity, styles, clean-code, convention]
description: Standard operating protocol prohibiting repetitive !important declarations in SCSS and CSS, enforcing specificity hierarchy, CSS variables, and cascade layers.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Avoid Repetitive !important in SCSS/CSS Protocol (`avoid-repetitive-css-important`)

> [!INFO]
> Domain: SCSS, SASS, CSS Stylesheets, Theme Overrides  
> Core Invariant: Zero repetitive !important usage. Leverage specificity, CSS variables, and cascade layers.

---

## 1. Core Principles

1. **Prohibition of Repetitive !important**:
   Never use `!important` across multiple sibling rules or chained declarations to force styling overrides. Chaining `!important` breaks the natural CSS cascade and creates maintainability dead-ends.

2. **Root Cause Resolution**:
   If a style does not apply, resolve the specificity hierarchy at the selector level rather than brute-forcing with `!important`.

---

## 2. Recommended Alternatives to !important

### A. Increase Selector Specificity Naturally
Instead of forcing overrides with `!important`, prepend parent container classes or use `:is()`:
```scss
// Anti-pattern
.button {
    background: #ff0000 !important;
    color: #ffffff !important;
    padding: 10px !important;
}

// Recommended
.theme-dark .button,
.app-container .button {
    background: #ff0000;
    color: #ffffff;
    padding: 10px;
}
```

### B. Use CSS Custom Properties (Variables)
Declare customizable properties on root or parent components, allowing downstream themes to update variables cleanly:
```scss
// Component definition
.card {
    background: var(--card-bg, #ffffff);
    color: var(--card-text, #111111);
}

// Override context
.custom-theme {
    --card-bg: #1e1e1e;
    --card-text: #f0f0f0;
}
```

### C. Use Cascade Layers (@layer)
Organize styles using `@layer` so base styles yield naturally to component and theme overrides without specificity inflation:
```css
@layer base, components, overrides;

@layer base {
    button { background: gray; }
}

@layer overrides {
    button { background: blue; } // Takes precedence naturally without !important
}
```

---

## 3. Strict Exceptions

`!important` is permitted **only** in the following restricted scenarios:
1. **Atomic Utility Classes**: Standalone helper utilities intended to guarantee an invariant behavior (e.g. `.u-hidden { display: none !important; }`).
2. **Third-Party Injected DOM**: Overriding fixed inline styles injected by unconfigurable third-party vendor scripts that cannot be targeted by specificity alone.

---

## 4. Verification and Audit

Run this inspection command to detect files with excessive `!important` declarations:
```powershell
Get-ChildItem -Path . -Recurse -Include *.scss,*.css -Exclude node_modules,dist,trash-bin | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    $count = ([regex]::Matches($content, '!important')).Count
    if ($count -ge 3) {
        [PSCustomObject]@{
            File           = $_.FullName.Replace((Get-Location).Path + "\", "")
            ImportantCount = $count
            Status         = "Exceeds Threshold (Review Specificity)"
        }
    }
} | Format-Table -AutoSize
```

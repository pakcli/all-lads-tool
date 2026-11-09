---
name: privacy-default-masking-2-letter-exposure
aliases: [privacy-default-masking, two-letter-exposure-masking, zero-hardcode-privacy-regex, default-censored-frontend-standard]
category: PRIVACY_PROTOCOL
tags: [all-lads-tool, privacy, masking, security, frontend, zero-hardcode, regex, 2-letter, protocol]
description: Strict privacy standard mandating that all frontends, UI panels, dashboards, and CLI tools display sensitive data masked by default using a pure algorithmic 2-letter exposure rule (2 first letters before and after @), with hold/toggle reveals strictly quarantined to ephemeral memory and never saved to JSON.
dependencies:
  - "[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]"
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[donot-ngada-ngada-exact-lapangan-variables]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[codebase-compliance-audit]]"
pros:
  - "Guarantees zero accidental credential or personal account exposure during screenshots, streams, or demos"
  - "Runs purely via generic pattern matching without requiring hardcoded lists or user configuration"
  - "Protects privacy by default while providing intuitive, non-persistent hold and toggle reveal mechanisms"
cons:
  - "Requires UI components to maintain an ephemeral unmask state and pass strings through a masking formatter"
---

# Privacy Default Masking Protocol: 2-Letter Exposure Standard (`privacy-default-masking-2-letter-exposure`)

> [!CAUTION]
> **ABSOLUTE PRIVACY INVARIANT**:
> **ON DEFAULT STATE, EVERY SENSITIVE DATA POINT ACROSS ALL FRONTENDS MUST BE CENSORED**.
> 
> 1. **Default State Censored**: Every UI panel, CLI dashboard, visual card, and table column must render sensitive identifiers (emails, account usernames, personal tokens, user profile directories) masked on initial load.
> 2. **The 2-Letter Exposure Rule**:
>    - **Emails**: Exactly 2 first letters before `@` and 2 first letters after `@` remain visible, followed by `***` (e.g. `us***@do***.com`).
>    - **Usernames & Handles**: Exactly 2 first characters visible + `***` (e.g. `pa***`).
>    - **User Profile Paths**: Exactly 2 characters of the OS user folder visible (e.g. `C:\Users\us***\...`).
> 3. **Zero Hardcoded Data**: Masking must be 100% algorithmic via generic regex. NEVER hardcode specific email addresses, usernames, or domains into filters or scripts.
> 4. **Zero JSON Persistence**: Unmasking is strictly ephemeral. The reveal state MUST NEVER be saved, serialized, or persisted to JSON files or disk configuration.

---

## 1. Core Principles: Why Default Masking Matters

In modern developer tooling, screen captures, live video pairing, screen sharing, and terminal logs frequently leak personal account identifiers:
- Cloud drive mount titles containing personal email addresses (e.g., `user.name@gmail.com - Google Drive`).
- CLI status badges displaying authenticated Git or Cloud accounts.
- Local filesystem paths containing personal host usernames (`C:\Users\username\...`).

Under this protocol, **visibility is an explicit, temporary user action**, never an automatic default.

---

## 2. The Pure Algorithmic Masking Specification

```text
+-------------------------------------------------------------------------------+
|                    ALGORITHMIC 2-LETTER MASKING PIPELINE                      |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ Raw String Input Received (Drive Label, Path, Account Badge) ]             |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 1: PARSE FOR EMAIL PATTERN (ZERO HARDCODE REGEX) ]                    |
|  Pattern: \b([a-zA-Z0-9_.+-]{1,2})([a-zA-Z0-9_.+-]*)@                         |
|           ([a-zA-Z0-9-]{1,2})([a-zA-Z0-9-]*\.[a-zA-Z0-9-.]+)\b               |
|                    |                                                          |
|      +-------------+-------------+                                            |
|      | Matches Email             | No Email Match                             |
|      v                           v                                            |
|  [ FORMAT: us***@do***.com ]  [ STEP 2: PARSE FOR USER PROFILE PATH ]         |
|                               Pattern: (Users[\\/])([a-zA-Z0-9_-]{1,2})       |
|                                        ([a-zA-Z0-9_-]+)                       |
|                                          |                                    |
|                               +----------+----------+                         |
|                               | Matches User Path   | No Match                |
|                               v                     v                         |
|                       [ FORMAT: fs*** ]     [ PASS THROUGH UNCHANGED ]        |
|                               |                     |                         |
|                               +----------+----------+                         |
|                                          v                                    |
|                       [ RENDER CENSORED VALUE BY DEFAULT ]                    |
+-------------------------------------------------------------------------------+
```

---

## 3. Mandatory Behavioral Matrix: Violations vs. Standard

| Context | VIOLATION: Exposed / Hardcoded | COMPLIANCE: 2-Letter Protocol |
| :--- | :--- | :--- |
| **Initial Load** | Rendering `dcalibri@gmail.com - Google Drive` in plain text | Rendering `dc***@gm***.com - Google Drive` by default |
| **User Profile Paths** | Displaying `C:\Users\username\AppData\...` | Displaying `C:\Users\us***\AppData\...` by default |
| **Regex Implementation** | Hardcoding `if ($str -match 'gmail.com')` | Using generic email token regex matching any valid domain |
| **Unmasking Trigger** | Clicking unmask and saving `isMasked: false` to `config.json` | Holding unmask in memory; resetting on next window launch |
| **CLI Status Output** | Outputting raw user email in headless stdout logs | Masking to 2-letter tokens unless explicit `-Unmask` flag passed |

---

## 4. Dual Reveal Interactions

UI components complying with this standard must provide two distinct reveal mechanisms:

### 1. Hold to Reveal (`PreviewMouseDown` / `PreviewMouseUp`)
- **Behavior**: While the user holds down the mouse button on the `[Hold to Reveal]` button, the UI dynamically renders the unmasked raw string.
- **Release Action**: As soon as the mouse button is released, the UI instantly re-masks all values.

### 2. Session-Only Click Toggle (`BtnToggleMask`)
- **Behavior**: An explicit click toggles the active window's memory flag between `Mask: ON (2-Letter)` (default) and `Mask: OFF (Revealed)`.
- **Ephemeral Rule**: Closing and reopening the tool or restarting the CLI session immediately resets the state to **Mask: ON**.

---

## 5. Canonical Implementation Reference (PowerShell)

Implemented in `[[lock-panel-window.psm1]]` and reusable across all tooling adapters:

```powershell
function Format-PrivacyMaskString {
    param(
        [string]$InputString,
        [bool]$Unmask = $false
    )
    if ([string]::IsNullOrWhiteSpace($InputString)) { return "" }
    if ($Unmask) { return $InputString }

    # Pure algorithmic email masking (2 letters before and after @)
    if ($InputString -match '(?i)\b([a-zA-Z0-9_.+-]{1,2})([a-zA-Z0-9_.+-]*)@([a-zA-Z0-9-]{1,2})([a-zA-Z0-9-]*\.[a-zA-Z0-9-.]+)\b') {
        return [regex]::Replace($InputString, '(?i)\b([a-zA-Z0-9_.+-]{1,2})([a-zA-Z0-9_.+-]*)@([a-zA-Z0-9-]{1,2})([a-zA-Z0-9-]*\.[a-zA-Z0-9-.]+)\b', {
            param($m)
            $userPrefix = $m.Groups[1].Value
            $domainPrefix = $m.Groups[3].Value
            $domainSuffix = $m.Groups[4].Value
            $ext = if ($domainSuffix -match '(\.[a-zA-Z0-9]+)$') { $matches[1] } else { "" }
            return "$($userPrefix)***@$($domainPrefix)***$($ext)"
        })
    }

    # Pure algorithmic user profile path masking
    if ($InputString -match '(?i)(users[\\/])([a-zA-Z0-9_-]{1,2})([a-zA-Z0-9_-]+)') {
        return [regex]::Replace($InputString, '(?i)(users[\\/])([a-zA-Z0-9_-]{1,2})([a-zA-Z0-9_-]+)', {
            param($m)
            return "$($m.Groups[1].Value)$($m.Groups[2].Value)***"
        })
    }

    return $InputString
}
```

---

## 6. Compliance Checklist

Before releasing any frontend card, window, or CLI reporter:
- [ ] Is the default initial state set to masked (`$isMasked = $true`)?
- [ ] Are emails masked to exactly 2 letters before and after `@` (`us***@do***.com`)?
- [ ] Are user profile directories masked to 2 letters (`C:\Users\us***\...`)?
- [ ] Is masking performed via generic regex with zero hardcoded values?
- [ ] Does the UI provide an unmask mechanism (Hold to Reveal and/or session toggle)?
- [ ] Is the unmasked state strictly volatile in memory and NEVER written to JSON or disk?
- [ ] Does the interface adhere to serious mode with zero emojis?

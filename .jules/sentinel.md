## 2024-11-20 - Unsanitized User Input in UI Rendering (XSS)
**Vulnerability:** Several innerHTML assignments in UI rendering logic (`bibliotecario.html` and `admin.html`) were not properly escaping user-provided fields (like `nombre`, `apellido`, `dni`, `email`), creating a Cross-Site Scripting (XSS) vulnerability.
**Learning:** Even internal-facing panels and lists can be vulnerable if user-controlled fields aren't escaped before DOM insertion. The codebase relies heavily on template literals and `innerHTML` for dynamic UI updates, making it easy to overlook variable escaping.
**Prevention:** Always use the provided `escapeHtml()` function for *all* string variables interpolated into HTML strings, particularly those originating from user-modifiable objects in the database.

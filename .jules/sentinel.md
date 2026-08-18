## 2026-08-16 - Unsanitized User Input in UI Rendering (XSS)
**Vulnerability:** Several innerHTML assignments in UI rendering logic (`bibliotecario.html` and `admin.html`) were not properly escaping user-provided fields (like `nombre`, `apellido`, `dni`, `email`), creating a Cross-Site Scripting (XSS) vulnerability.
**Learning:** Even internal-facing panels and lists can be vulnerable if user-controlled fields aren't escaped before DOM insertion. The codebase relies heavily on template literals and `innerHTML` for dynamic UI updates, making it easy to overlook variable escaping.
**Prevention:** Always use the provided `escapeHtml()` function for *all* string variables interpolated into HTML strings, particularly those originating from user-modifiable objects in the database.

## 2026-08-18 - Interpolación sin escapar en el filtro de géneros
**Vulnerability:** `renderGenerosFiltro()` en `lector.html` construía las
`<option>` del filtro concatenando el género crudo, tanto en el atributo
`value` como en el contenido del elemento. El valor sale de
`DB.libros.getGeneros()`, es decir del catálogo persistido. Quedó fuera del
barrido del PR #8.
**Learning:** El barrido anterior cubrió los campos del lector pero no los
derivados del catálogo. Un `innerHTML +=` es tan sink como un `innerHTML =`, y
el atributo `value=` es tan inyectable como el contenido del elemento.
**Prevention:** Toda la persistencia vive en `localStorage`, editable desde
DevTools: ningún valor leído de `DB` es de confianza aunque hoy entre por un
`<select>` cerrado. Escapar en el punto de render, no en el de entrada.

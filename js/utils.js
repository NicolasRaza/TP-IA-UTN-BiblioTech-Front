// =============================================
// BiblioTech — Utilidades compartidas
// =============================================

/* ── Formateo de fechas ── */
function formatFecha(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric' });
}
function formatFechaHora(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}
function formatFechaRelativa(iso) {
  if (!iso) return '—';
  const diff = Math.floor((Date.now() - new Date(iso)) / 1000);
  if (diff < 60) return 'hace un momento';
  if (diff < 3600) return `hace ${Math.floor(diff/60)} min`;
  if (diff < 86400) return `hace ${Math.floor(diff/3600)} hs`;
  if (diff < 172800) return 'ayer';
  return formatFecha(iso);
}
function diasRestantes(iso) {
  const diff = Math.ceil((new Date(iso) - Date.now()) / 86400000);
  return diff;
}

/* ── Toast notifications ── */
// BUG FIX: usar id fijo para evitar contenedores duplicados
const TOAST_CONTAINER_ID = 'bt-toast-container';
function getToastContainer() {
  let el = document.getElementById(TOAST_CONTAINER_ID);
  if (!el) {
    el = document.createElement('div');
    el.className = 'toast-container';
    el.id = TOAST_CONTAINER_ID;
    document.body.appendChild(el);
  }
  return el;
}
function toast(mensaje, tipo = 'info', duracion = 3500) {
  const iconos = { success: '✅', warning: '⚠️', error: '❌', info: 'ℹ️' };
  const el = document.createElement('div');
  el.className = `toast ${tipo}`;
  // BUG FIX: textContent para el mensaje evita inyección HTML
  const iconSpan = document.createElement('span');
  iconSpan.className = 'toast-icon';
  iconSpan.textContent = iconos[tipo] || 'ℹ️';
  const msgSpan = document.createElement('span');
  msgSpan.textContent = mensaje;
  el.appendChild(iconSpan);
  el.appendChild(msgSpan);
  getToastContainer().appendChild(el);
  setTimeout(() => {
    el.style.opacity = '0';
    el.style.transform = 'translateX(20px)';
    el.style.transition = 'opacity 0.3s, transform 0.3s';
    setTimeout(() => el.remove(), 300);
  }, duracion);
}

/* ── Modal helpers ── */
function openModal(id) {
  const m = document.getElementById(id);
  if (m) m.classList.add('open');
}
function closeModal(id) {
  const m = document.getElementById(id);
  if (m) m.classList.remove('open');
}
// Cerrar al hacer click afuera
document.addEventListener('click', (e) => {
  if (e.target.classList.contains('modal-overlay')) {
    e.target.classList.remove('open');
  }
});

/* ── Navegación SPA ── */
function navigateTo(sectionId, parentEl) {
  const parent = parentEl || document;
  parent.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  parent.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const section = parent.querySelector(`#${sectionId}`);
  if (section) { section.classList.add('active'); section.classList.add('animate-fadeIn'); }
  const navItem = parent.querySelector(`[data-section="${sectionId}"]`);
  if (navItem) navItem.classList.add('active');
  // Actualizar hash
  history.pushState(null, '', `#${sectionId}`);
}

/* ── Badge de estado de libro ── */
function estadoLibroBadge(estado) {
  const map = {
    disponible: '<span class="badge badge-success">● Disponible</span>',
    prestado:   '<span class="badge badge-danger">● Prestado</span>',
    reservado:  '<span class="badge badge-warning">● Reservado</span>',
  };
  return map[estado] || '<span class="badge badge-muted">—</span>';
}
function estadoEjemplarBadge(estado) {
  return estadoLibroBadge(estado);
}

/* ── Badge condición ── */
function condicionBadge(condicion) {
  const map = {
    bueno:   '<span class="badge badge-success">Bueno</span>',
    regular: '<span class="badge badge-warning">Regular</span>',
    malo:    '<span class="badge badge-danger">Malo</span>',
  };
  return map[condicion] || '<span class="badge badge-muted">—</span>';
}

/* ── Badge categoría lector ── */
function categoriaBadge(cat) {
  const map = {
    adulto:  '<span class="badge badge-purple">Adulto</span>',
    menor:   '<span class="badge badge-teal">Menor</span>',
    docente: '<span class="badge badge-info">Docente</span>',
    senior:  '<span class="badge badge-muted">Senior</span>',
  };
  return map[cat] || `<span class="badge badge-muted">${escapeHtml(cat || '')}</span>`;
}

/* ── Estado préstamo badge ── */
function estadoPrestamoBadge(estado) {
  const map = {
    activo:   '<span class="badge badge-success">Activo</span>',
    vencido:  '<span class="badge badge-danger">Vencido</span>',
    devuelto: '<span class="badge badge-muted">Devuelto</span>',
  };
  return map[estado] || '<span class="badge badge-muted">—</span>';
}

/* ── Portada URL con fallback ── */
function getPortadaUrl(libro) {
  if (libro.portada) return libro.portada;
  if (libro.isbn)    return `https://covers.openlibrary.org/b/isbn/${libro.isbn}-L.jpg`;
  return null;
}
function getPlaceholderHTML(titulo = '') {
  return `<div class="book-cover-placeholder"><span>📖</span><span>${escapeHtml(titulo)}</span></div>`;
}

// Genera una imagen segura con fallback de elemento hermano que nunca se rompe si falla la URL de la portada
function portadaImgSegura(libro, extraStyle = '') {
  const url = getPortadaUrl(libro);
  const safeTitle = escapeHtml(libro?.titulo || 'Libro');
  if (!url) {
    return `<div class="book-cover-placeholder"><span>📖</span><span>${safeTitle}</span></div>`;
  }
  return `<img src="${url}" alt="${safeTitle}" style="width:100%;height:100%;object-fit:cover;${extraStyle}" loading="lazy" onerror="this.style.display='none';if(this.nextElementSibling)this.nextElementSibling.style.display='flex';"><div class="book-cover-placeholder" style="display:none;width:100%;height:100%;"><span>📖</span><span>${safeTitle}</span></div>`;
}

/* ── Escape HTML ── */
function escapeHtml(s) {
  if (!s) return '';
  return String(s)
    .replace(/&/g,'&amp;')
    .replace(/</g,'&lt;')
    .replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;')
    .replace(/'/g,'&#39;');
}

/* ── QR Generator ── */
async function generarQR(texto, canvasEl, size = 180) {
  if (typeof QRCode === 'undefined') {
    console.warn('QRCode.js no cargado');
    return;
  }
  canvasEl.innerHTML = '';
  new QRCode(canvasEl, {
    text: texto,
    width: size,
    height: size,
    colorDark: '#000000',
    colorLight: '#ffffff',
    correctLevel: QRCode.CorrectLevel.M,
  });
}

/* ── Impresión QR — BUG FIX: manejo de popup blocker ── */
function imprimirQR(qrTexto, labelTexto) {
  const win = window.open('', '_blank');
  if (!win) {
    toast('El navegador bloqueó la ventana de impresión. Permitir popups para este sitio.', 'warning', 5000);
    return;
  }
  const safeLabel = escapeHtml(labelTexto);
  const safeQR    = escapeHtml(qrTexto);
  win.document.write(`<!DOCTYPE html><html><head><title>QR BiblioTech</title>
    <script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"><\/script>
    <style>
      body{display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;font-family:sans-serif;gap:12px;background:#fff;}
      .label{font-size:11px;font-weight:700;text-align:center;max-width:200px;color:#333;}
      .brand{font-size:9px;color:#999;margin-top:4px;}
      @media print{body{margin:0;}button{display:none;}}
    </style>
    </head><body>
    <div id="qr"></div>
    <div class="label">${safeLabel}</div>
    <div class="brand">BiblioTech</div>
    <script>
      new QRCode(document.getElementById('qr'),{text:"${safeQR}",width:200,height:200,colorDark:"#000",colorLight:"#fff"});
      setTimeout(function(){ window.print(); }, 600);
    <\/script>
    </body></html>`);
  win.document.close();
}

/* ── Open Library API — BUG FIX: timeout de 8s para evitar colgar la UI ── */
async function buscarPorISBN(isbn) {
  const clean = isbn.replace(/[^0-9X]/g, '');
  if (!clean || (clean.length !== 10 && clean.length !== 13)) return null;
  
  const controller = new AbortController();
  const timeoutId  = setTimeout(() => controller.abort(), 8000);
  
  try {
    const resp = await fetch(
      `https://openlibrary.org/api/books?bibkeys=ISBN:${clean}&format=json&jscmd=data`,
      { signal: controller.signal }
    );
    clearTimeout(timeoutId);
    if (!resp.ok) return null;
    const data = await resp.json();
    const key  = `ISBN:${clean}`;
    if (!data[key]) return null;
    const book = data[key];
    return {
      titulo:    book.title || '',
      autor:     book.authors?.[0]?.name || '',
      editorial: book.publishers?.[0]?.name || '',
      anio:      book.publish_date ? parseInt(book.publish_date) : null,
      paginas:   book.number_of_pages || null,
      sinopsis:  book.notes?.value || book.excerpts?.[0]?.text || '',
      genero:    book.subjects?.[0]?.name || '',
      portada:   book.cover?.large || book.cover?.medium || `https://covers.openlibrary.org/b/isbn/${clean}-L.jpg`,
      isbn:      clean,
    };
  } catch (e) {
    clearTimeout(timeoutId);
    if (e.name === 'AbortError') console.warn('Open Library API: timeout');
    else console.warn('Open Library API error:', e.message);
    return null;
  }
}

/* ── Sidebar mobile ── */
function initSidebarMobile() {
  const hamburger = document.querySelector('.hamburger');
  const sidebar   = document.querySelector('.sidebar');
  if (!hamburger || !sidebar) return;
  hamburger.addEventListener('click', () => sidebar.classList.toggle('open'));
  document.addEventListener('click', (e) => {
    if (!sidebar.contains(e.target) && !hamburger.contains(e.target)) {
      sidebar.classList.remove('open');
    }
  });
}

/* ── Avatar inicial ── */
function getInicial(nombre, apellido) {
  return ((nombre?.[0] || '') + (apellido?.[0] || '')).toUpperCase();
}

/* ── Confirm dialog ── */
function confirmar(mensaje) {
  return window.confirm(mensaje);
}

/* ── Capitalizar ── */
function capitalizar(s) {
  if (!s) return '';
  return s.charAt(0).toUpperCase() + s.slice(1);
}

/* ── Días desde fecha ── */
function diasDesde(iso) {
  return Math.floor((Date.now() - new Date(iso)) / 86400000);
}

/* ── Store global para callbacks onclick seguros ──
   Evita serializar JSON/objetos en atributos HTML (bug con caracteres especiales). */
const _clickStore = {};
let _clickStoreIdx = 0;
function storeClick(fn) {
  const id = 'cs_' + (_clickStoreIdx++);
  _clickStore[id] = fn;
  return `_clickStore['${id}']()`;
}

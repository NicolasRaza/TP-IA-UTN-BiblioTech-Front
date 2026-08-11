// =============================================
// BiblioTech — Agente Analizador y Evaluador
// + Agente Planificador + Aprendizaje
// =============================================

/* ────────────────────────────────────────────
   AGENTE 2: ANALIZADOR Y ENRIQUECIMIENTO
   ──────────────────────────────────────────── */
const AgenteAnalizador = {
  /**
   * Analiza texto OCR crudo y estructura los campos editoriales.
   * Simula NLP con heurísticas de detección de patrones.
   */
  procesarTextoOCR(textoOCR) {
    const lineas = textoOCR.split('\n').map(l => l.trim()).filter(Boolean);
    const resultado = {
      isbn: { valor: '', confianza: 0 },
      titulo: { valor: '', confianza: 0 },
      autor: { valor: '', confianza: 0 },
      editorial: { valor: '', confianza: 0 },
      anio: { valor: '', confianza: 0 },
      paginas: { valor: '', confianza: 0 },
    };

    // ISBN: busca patrón ISBN-13 o ISBN-10
    const isbnMatch = textoOCR.match(/\b(?:ISBN[-:]?\s*)?(97[89][\d\s-]{10,}|\d{9}[\dX])\b/i);
    if (isbnMatch) {
      resultado.isbn = { valor: isbnMatch[1].replace(/[\s-]/g, ''), confianza: 95 };
    }

    // Año de publicación
    const anioMatch = textoOCR.match(/\b(19[4-9]\d|20[0-2]\d)\b/);
    if (anioMatch) {
      resultado.anio = { valor: anioMatch[1], confianza: 88 };
    }

    // Páginas
    const paginasMatch = textoOCR.match(/(\d{2,4})\s*(?:páginas?|pags?|pp\.?)/i);
    if (paginasMatch) {
      resultado.paginas = { valor: paginasMatch[1], confianza: 85 };
    }

    // Editorial (patrones comunes)
    const editorialesConocidas = ['sudamericana','emecé','planeta','alfaguara','anagrama','seix barral','tusquets','debolsillo','salamandra','fondo de cultura','debate','crítica','lumen','alba','suma','random'];
    for (const linea of lineas) {
      const ll = linea.toLowerCase();
      for (const ed of editorialesConocidas) {
        if (ll.includes(ed)) {
          resultado.editorial = { valor: capitalizar(ed), confianza: 82 };
          break;
        }
      }
      if (resultado.editorial.valor) break;
      // Editorial después de "©" o "Publicado por"
      const edMatch = linea.match(/©\s+\d{4}\s+(.+)/i) || linea.match(/(?:Publicado|Published)\s+(?:por|by)\s+(.+)/i);
      if (edMatch && !resultado.editorial.valor) {
        resultado.editorial = { valor: edMatch[1].trim().substring(0, 50), confianza: 72 };
      }
    }

    // Autor: líneas que tienen estructura "Apellido, Nombre" o "Nombre Apellido"
    const autorPattern = /^([A-ZÁÉÍÓÚÜÑ][a-záéíóúüñ]+(?:\s+[A-ZÁÉÍÓÚÜÑ][a-záéíóúüñ]+){1,3})$/;
    for (const linea of lineas.slice(0, 8)) {
      if (autorPattern.test(linea) && !linea.match(/\d/) && linea.length < 60) {
        if (!resultado.autor.valor || linea.split(' ').length >= 2) {
          resultado.autor = { valor: linea, confianza: 75 };
        }
      }
    }

    // Título: líneas más largas, generalmente al inicio
    const posiblesTitulos = lineas.slice(0, 5).filter(l => l.length > 3 && l.length < 120 && !l.match(/^\d/) && l !== resultado.autor.valor);
    if (posiblesTitulos.length > 0) {
      resultado.titulo = { valor: posiblesTitulos[0], confianza: 65 };
    }

    return resultado;
  },

  /**
   * Enriquece datos con la API de Open Library.
   */
  async enriquecer(isbn, datosOCR) {
    if (!isbn) return datosOCR;
    const apiData = await buscarPorISBN(isbn);
    if (!apiData) return datosOCR;
    // Fusionar: API tiene prioridad sobre OCR
    const enriquecido = { ...datosOCR };
    if (apiData.titulo)    enriquecido.titulo    = { valor: apiData.titulo,    confianza: 98, fuente: 'API' };
    if (apiData.autor)     enriquecido.autor     = { valor: apiData.autor,     confianza: 98, fuente: 'API' };
    if (apiData.editorial) enriquecido.editorial = { valor: apiData.editorial, confianza: 95, fuente: 'API' };
    if (apiData.anio)      enriquecido.anio      = { valor: String(apiData.anio), confianza: 95, fuente: 'API' };
    if (apiData.paginas)   enriquecido.paginas   = { valor: String(apiData.paginas), confianza: 90, fuente: 'API' };
    if (apiData.sinopsis)  enriquecido.sinopsis  = { valor: apiData.sinopsis,  confianza: 90, fuente: 'API' };
    if (apiData.genero)    enriquecido.genero    = { valor: apiData.genero,    confianza: 80, fuente: 'API' };
    if (apiData.portada)   enriquecido.portada   = { valor: apiData.portada,   confianza: 95, fuente: 'API' };
    return enriquecido;
  },

  /**
   * Clasifica nivel de confianza para UI.
   */
  nivelConfianza(pct) {
    if (pct >= 85) return 'high';
    if (pct >= 65) return 'mid';
    return 'low';
  },
};


/* ────────────────────────────────────────────
   AGENTE 3: PLANIFICADOR Y GESTIÓN (ALERTAS)
   ──────────────────────────────────────────── */
const AgentePlanificador = {
  /**
   * Corre al iniciar la app. Detecta vencimientos próximos y vencidos,
   * genera notificaciones y retorna alertas para el dashboard del bibliotecario.
   */
  correr() {
    const alertas = [];
    const config  = DB.config.get();
    const hoy     = new Date();

    // ── Préstamos vencidos / próximos a vencer ──
    const prestamosActivos = DB.prestamos.getAll().filter(p => p.estado === 'activo' || p.estado === 'vencido');
    prestamosActivos.forEach(p => {
      const venc = new Date(p.fechaVencimiento);
      const diasDiff = Math.ceil((venc - hoy) / 86400000);
      const libro  = DB.libros.get(p.libroId);
      const lector = DB.lectores.get(p.lectorId);
      if (!libro || !lector) return;

      if (diasDiff < 0) {
        // Vencido
        alertas.push({ tipo: 'vencido', libro, lector, prestamo: p, dias: Math.abs(diasDiff) });
        // Notificación al lector (evitar duplicados)
        const yaNotif = DB.notificaciones.getByLector(p.lectorId).find(n => n.tipo === 'prestamo_vencido' && n.descripcion.includes(libro.titulo));
        if (!yaNotif) {
          DB.notificaciones.add({
            lectorId: p.lectorId, tipo: 'prestamo_vencido',
            titulo: '⚠️ Préstamo vencido',
            descripcion: `Tu préstamo de "${libro.titulo}" venció hace ${Math.abs(diasDiff)} días. Por favor devolvelo a la brevedad.`,
            icono: '🚨',
          });
        }
      } else if (diasDiff <= config.recordatorioAntesDias) {
        // Próximo a vencer
        alertas.push({ tipo: 'proximo', libro, lector, prestamo: p, dias: diasDiff });
        const yaNotif = DB.notificaciones.getByLector(p.lectorId).find(n => n.tipo === 'vencimiento_proximo' && n.descripcion.includes(libro.titulo));
        if (!yaNotif) {
          DB.notificaciones.add({
            lectorId: p.lectorId, tipo: 'vencimiento_proximo',
            titulo: '⏰ Préstamo próximo a vencer',
            descripcion: `Tu préstamo de "${libro.titulo}" vence en ${diasDiff} ${diasDiff === 1 ? 'día' : 'días'}.`,
            icono: '⏰',
          });
        }
      }
    });

    // ── Reservas vencidas (no retiradas a tiempo) ──
    const reservasListas = DB.reservas.getAll().filter(r => r.estado === 'lista');
    reservasListas.forEach(r => {
      if (!r.fechaVencimientoRetiro) return;
      if (new Date(r.fechaVencimientoRetiro) < hoy) {
        const lista = JSON.parse(localStorage.getItem('bt_reservas') || '[]');
        const idx = lista.findIndex(x => x.id === r.id);
        if (idx >= 0) {
          lista[idx].estado = 'vencida';
          localStorage.setItem('bt_reservas', JSON.stringify(lista));
        }
        alertas.push({ tipo: 'reserva_vencida', reserva: r });
      }
    });

    return alertas;
  },

  /**
   * Genera un resumen estadístico de alertas para el dashboard.
   */
  resumenAlertas() {
    const alertas = this.correr();
    return {
      vencidos:     alertas.filter(a => a.tipo === 'vencido').length,
      proximos:     alertas.filter(a => a.tipo === 'proximo').length,
      reservasVenc: alertas.filter(a => a.tipo === 'reserva_vencida').length,
      detalle: alertas,
    };
  },
};


/* ────────────────────────────────────────────
   AGENTE 4: EVALUADOR Y RECOMENDACIÓN
   ──────────────────────────────────────────── */
const AgenteEvaluador = {
  /**
   * Genera recomendaciones personalizadas para un lector.
   * Algoritmo: géneros de interés + libros populares + historial negativo.
   */
  recomendarParaLector(lectorId) {
    const lector = DB.lectores.get(lectorId);
    if (!lector) return [];

    const prestamos = DB.prestamos.getByLector(lectorId);
    const reservas  = DB.reservas.getByLector(lectorId);

    const idsPrestados = prestamos.map(p => p.libroId);
    const idsReservados = reservas.map(r => r.libroId);
    const excluir = new Set([...idsPrestados, ...idsReservados]);

    // Recopilar libros previamente leídos o reservados por el lector
    const librosLeidos = idsPrestados.map(id => DB.libros.get(id)).filter(Boolean);
    const autoresLeidos = new Set(librosLeidos.map(l => l.autor?.toLowerCase()).filter(Boolean));
    const generosLeidos = new Set(librosLeidos.map(l => l.genero).filter(Boolean));

    // Identificar palabras clave de sagas o series en los títulos leídos (ej: "Harry Potter", etc.)
    const sagaKeywords = [];
    librosLeidos.forEach(l => {
      const t = l.titulo.toLowerCase();
      const matchSaga = t.match(/harry potter|señor de los anillos|narnia|percy jackson|juego de tronos/i);
      if (matchSaga) {
        sagaKeywords.push(matchSaga[0].toLowerCase());
      } else {
        t.split(/\s+/).forEach(word => {
          if (word.length > 4 && !['sobre','donde','desde','hasta','entre'].includes(word)) {
            sagaKeywords.push(word);
          }
        });
      }
    });

    const todos = DB.libros.getAll().filter(l => l.validado && !excluir.has(l.id));
    const generosInteres = lector.generosInteres || [];

    // Puntuar cada libro de acuerdo a coincidencia de saga, autor, género y popularidad
    const scored = todos.map(libro => {
      let score = 0;
      const tLow = libro.titulo.toLowerCase();
      const aLow = (libro.autor || '').toLowerCase();

      // +70 si coincide con la saga de un libro que leyó (ej: otro libro de "Harry Potter")
      const coincideSaga = sagaKeywords.some(kw => tLow.includes(kw));
      if (coincideSaga) score += 70;

      // +50 si coincide con el autor de un libro que leyó (ej: "J.K. Rowling")
      if (aLow && autoresLeidos.has(aLow)) score += 50;

      // +35 si es del mismo género que libros que leyó
      if (libro.genero && generosLeidos.has(libro.genero)) score += 35;

      // +30 si el género está en sus intereses
      if (generosInteres.includes(libro.genero)) score += 30;

      // +20 si hay disponibilidad inmediata
      const disponible = libro.ejemplares?.some(e => e.estado === 'disponible');
      if (disponible) score += 20;

      // +popularidad basada en préstamos totales
      const totalPrestamos = DB.prestamos.getAll().filter(p => p.libroId === libro.id).length;
      score += Math.min(totalPrestamos * 5, 25);

      // +aleatoriedad ligera
      score += Math.random() * 5;
      return { libro, score };
    });

    return scored
      .sort((a, b) => b.score - a.score)
      .slice(0, 8)
      .map(x => x.libro);
  },

  /**
   * Indicadores de negocio para el dashboard del administrador.
   */
  calcularIndicadores() {
    const prestamos = DB.prestamos.getAll();
    const libros    = DB.libros.getAll();
    const lectores  = DB.lectores.getAll();

    // Top 5 libros más prestados
    const porLibro = {};
    prestamos.forEach(p => { porLibro[p.libroId] = (porLibro[p.libroId] || 0) + 1; });
    const topLibros = Object.entries(porLibro)
      .sort((a,b) => b[1] - a[1]).slice(0, 5)
      .map(([id, n]) => ({ libro: DB.libros.get(id), prestamos: n }))
      .filter(x => x.libro);

    // Lectores más activos
    const porLector = {};
    prestamos.forEach(p => { porLector[p.lectorId] = (porLector[p.lectorId] || 0) + 1; });
    const topLectores = Object.entries(porLector)
      .sort((a,b) => b[1] - a[1]).slice(0, 5)
      .map(([id, n]) => ({ lector: DB.lectores.get(id), prestamos: n }))
      .filter(x => x.lector);

    // Géneros más leídos
    const porGenero = {};
    prestamos.forEach(p => {
      const lib = DB.libros.get(p.libroId);
      if (lib?.genero) porGenero[lib.genero] = (porGenero[lib.genero] || 0) + 1;
    });
    const topGeneros = Object.entries(porGenero)
      .sort((a,b) => b[1] - a[1]).slice(0, 6);

    // Tasa de devoluciones tardías por mes (últimos 6 meses)
    const meses = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date();
      d.setMonth(d.getMonth() - i);
      const mes = d.toLocaleString('es-AR', { month: 'short' });
      const mesNum = d.getMonth();
      const anio   = d.getFullYear();
      const deMes  = prestamos.filter(p => {
        const fd = new Date(p.fechaPrestamo);
        return fd.getMonth() === mesNum && fd.getFullYear() === anio;
      });
      const tardios = deMes.filter(p => p.tardio).length;
      meses.push({ mes, total: deMes.length, tardios });
    }

    return { topLibros, topLectores, topGeneros, meses };
  },

  /**
   * Sugerencias estratégicas para la biblioteca.
   */
  generarSugerencias() {
    const ind = this.calcularIndicadores();
    const sugerencias = [];

    // Libros con muchos préstamos y pocos ejemplares
    ind.topLibros.forEach(({ libro, prestamos }) => {
      const disponibles = libro?.ejemplares?.filter(e => e.estado === 'disponible').length || 0;
      if (prestamos >= 3 && disponibles === 0) {
        sugerencias.push({ tipo: 'compra', texto: `"${libro.titulo}" tiene alta demanda (${prestamos} préstamos) y ningún ejemplar disponible. Considerar comprar más ejemplares.` });
      }
    });

    // Libros nunca prestados (posible baja o promoción)
    const librosNunca = DB.libros.getAll().filter(l => !DB.prestamos.getAll().some(p => p.libroId === l.id));
    if (librosNunca.length > 0) {
      sugerencias.push({ tipo: 'promocion', texto: `${librosNunca.length} libros nunca fueron prestados. Podrían promoverse o evaluarse para baja.` });
    }

    // Alta tasa de tardanza
    const stats = DB.prestamos.getStats();
    if (parseFloat(stats.tasaTardia) > 20) {
      sugerencias.push({ tipo: 'politica', texto: `La tasa de devoluciones tardías es del ${stats.tasaTardia}%. Considerar reducir los plazos o aumentar los recordatorios.` });
    }

    return sugerencias;
  },
};


/* ────────────────────────────────────────────
   AGENTE 5: APRENDIZAJE CONTINUO
   ──────────────────────────────────────────── */
const AgenteAprendizaje = {
  /**
   * Analiza el historial de correcciones OCR y retorna patrones.
   */
  analizarCorreccionesOCR() {
    const data = DB.aprendizaje.get();
    const correcciones = data.correcciones || [];
    if (correcciones.length === 0) return { patronesDetectados: [], mejora: 0 };

    const porCampo = {};
    correcciones.forEach(c => {
      porCampo[c.campo] = (porCampo[c.campo] || 0) + 1;
    });

    const patronesDetectados = Object.entries(porCampo)
      .sort((a,b) => b[1] - a[1])
      .map(([campo, n]) => ({ campo, correcciones: n, sugerencia: `El campo "${campo}" se corrige frecuentemente. El OCR en ese campo tiene margen de mejora.` }));

    const mejora = Math.min(correcciones.length * 2, 40); // Simula mejora del modelo
    return { patronesDetectados, mejora, totalCorrecciones: correcciones.length };
  },

  /**
   * Analiza qué recomendaciones tuvieron mejor aceptación.
   */
  analizarRecomendaciones() {
    const data = DB.aprendizaje.get();
    const clics = data.clics || [];
    const porLibro = {};
    clics.filter(c => c.tipo === 'reserva').forEach(c => {
      porLibro[c.libroId] = (porLibro[c.libroId] || 0) + 1;
    });
    const masEfectivos = Object.entries(porLibro)
      .sort((a,b) => b[1] - a[1]).slice(0, 3)
      .map(([id, n]) => ({ libro: DB.libros.get(id), conversiones: n }))
      .filter(x => x.libro);
    return { masEfectivos, totalClics: clics.length };
  },

  /**
   * Reporte consolidado para el panel de administración.
   */
  generarReporte() {
    const ocr  = this.analizarCorreccionesOCR();
    const reco = this.analizarRecomendaciones();
    return {
      ocr, reco,
      resumen: `Sistema con ${ocr.totalCorrecciones || 0} correcciones OCR registradas. Mejora de modelo estimada: ${ocr.mejora}%.`,
    };
  },
};

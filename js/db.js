// =============================================
// BiblioTech — Capa de Datos (db.js)
// Persistencia en localStorage + seed data
// =============================================

const DB = (() => {
  const KEYS = {
    libros:       'bt_libros',
    lectores:     'bt_lectores',
    prestamos:    'bt_prestamos',
    reservas:     'bt_reservas',
    notificaciones:'bt_notificaciones',
    config:       'bt_config',
    auditoria:    'bt_auditoria',
    aprendizaje:  'bt_aprendizaje',
    sesion:       'bt_sesion',
    initialized:  'bt_initialized',
  };

  /* ── Helpers ── */
  const get  = k => JSON.parse(localStorage.getItem(k) || 'null');
  const set  = (k, v) => localStorage.setItem(k, JSON.stringify(v));
  const uuid = () => crypto.randomUUID?.() || Math.random().toString(36).slice(2) + Date.now().toString(36);
  const now  = () => new Date().toISOString();
  const fechaEnDias = (dias) => { const d = new Date(); d.setDate(d.getDate() + dias); return d.toISOString(); };
  const fechaHaceNDias = (dias) => { const d = new Date(); d.setDate(d.getDate() - dias); return d.toISOString(); };

  /* ── Seed Data ── */
  const seedLibros = [
    {
      id: 'lib-001', titulo: 'El Aleph', autor: 'Jorge Luis Borges', editorial: 'Emecé',
      anio: 1949, isbn: '9780142437889', sinopsis: 'El Aleph es el punto del espacio que contiene todos los puntos. En el sótano de la casa de Carlos Argentino Daneri, Borges descubre ese prodigio: un lugar donde están todos los lugares del mundo a la vez, sin superponerse ni confundirse.',
      genero: 'Literatura Argentina', paginas: 224,
      portada: 'https://covers.openlibrary.org/b/isbn/9780142437889-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(120),
      ejemplares: [
        { id: 'ej-001a', qr: '', condicion: 'bueno',   estado: 'disponible' },
        { id: 'ej-001b', qr: '', condicion: 'regular', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-002', titulo: 'Cien años de soledad', autor: 'Gabriel García Márquez', editorial: 'Sudamericana',
      anio: 1967, isbn: '9780307474728', sinopsis: 'La novela narra la historia de la familia Buendía a lo largo de siete generaciones en el pueblo ficticio de Macondo. Obra cumbre del realismo mágico y de la literatura latinoamericana.',
      genero: 'Realismo Mágico', paginas: 471,
      portada: 'https://covers.openlibrary.org/b/isbn/9780307474728-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(200),
      ejemplares: [
        { id: 'ej-002a', qr: '', condicion: 'bueno', estado: 'prestado' },
        { id: 'ej-002b', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-002c', qr: '', condicion: 'malo',  estado: 'disponible' },
      ]
    },
    {
      id: 'lib-003', titulo: 'Ficciones', autor: 'Jorge Luis Borges', editorial: 'Sur',
      anio: 1944, isbn: '9780802130204', sinopsis: 'Colección de cuentos considerada una de las obras más influyentes de la literatura del siglo XX. Incluye La biblioteca de Babel, El jardín de senderos que se bifurcan y otros relatos laberínticos.',
      genero: 'Literatura Argentina', paginas: 174,
      portada: 'https://covers.openlibrary.org/b/isbn/9780802130204-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(90),
      ejemplares: [
        { id: 'ej-003a', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-004', titulo: '1984', autor: 'George Orwell', editorial: 'Debolsillo',
      anio: 1949, isbn: '9780451524935', sinopsis: 'En una sociedad totalitaria donde el Gran Hermano lo ve todo, Winston Smith trabaja para el Ministerio de la Verdad reescribiendo la historia. Una distopía que se volvió profecía.',
      genero: 'Ciencia Ficción', paginas: 328,
      portada: 'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(150),
      ejemplares: [
        { id: 'ej-004a', qr: '', condicion: 'bueno',   estado: 'reservado' },
        { id: 'ej-004b', qr: '', condicion: 'regular', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-005', titulo: 'El Principito', autor: 'Antoine de Saint-Exupéry', editorial: 'Salamandra',
      anio: 1943, isbn: '9780156012195', sinopsis: 'El aviador que cae en el desierto conoce a un pequeño príncipe venido de un asteroide. Un libro para adultos que parecen niños, y para niños que desean seguir siéndolo.',
      genero: 'Literatura Infantil', paginas: 96,
      portada: 'https://covers.openlibrary.org/b/isbn/9780156012195-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(300),
      ejemplares: [
        { id: 'ej-005a', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-005b', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-005c', qr: '', condicion: 'regular', estado: 'prestado' },
      ]
    },
    {
      id: 'lib-006', titulo: 'Rayuela', autor: 'Julio Cortázar', editorial: 'Sudamericana',
      anio: 1963, isbn: '9788437601922', sinopsis: 'Novela experimental que puede leerse de múltiples formas. La historia de Horacio Oliveira en París y Buenos Aires, y su búsqueda metafísica. Una de las obras más revolucionarias de la literatura latinoamericana.',
      genero: 'Literatura Argentina', paginas: 600,
      portada: 'https://covers.openlibrary.org/b/isbn/9788437601922-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(60),
      ejemplares: [
        { id: 'ej-006a', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-006b', qr: '', condicion: 'malo',  estado: 'disponible' },
      ]
    },
    {
      id: 'lib-007', titulo: 'Don Quijote de la Mancha', autor: 'Miguel de Cervantes', editorial: 'RAE',
      anio: 1605, isbn: '9788499281704', sinopsis: 'Considerada la primera novela moderna y una de las obras más importantes de la literatura universal. Las aventuras del ingenioso hidalgo y su escudero Sancho Panza.',
      genero: 'Clásicos', paginas: 863,
      portada: 'https://covers.openlibrary.org/b/isbn/9788499281704-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(400),
      ejemplares: [
        { id: 'ej-007a', qr: '', condicion: 'regular', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-008', titulo: 'Sapiens: De animales a dioses', autor: 'Yuval Noah Harari', editorial: 'Debate',
      anio: 2011, isbn: '9780062316097', sinopsis: 'Una breve historia de la humanidad que examina cómo Homo sapiens llegó a dominar la Tierra. Desde la prehistoria hasta la revolución científica y la posible ingeniería de vida eterna.',
      genero: 'Historia / Ensayo', paginas: 474,
      portada: 'https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(45),
      ejemplares: [
        { id: 'ej-008a', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-008b', qr: '', condicion: 'bueno', estado: 'prestado' },
      ]
    },
    {
      id: 'lib-009', titulo: 'El nombre de la rosa', autor: 'Umberto Eco', editorial: 'Lumen',
      anio: 1980, isbn: '9788408006268', sinopsis: 'Una novela detectivesca ambientada en una abadía medieval italiana en 1327. El monje Guillermo de Baskerville investiga una serie de misteriosas muertes en la biblioteca más grande del mundo cristiano.',
      genero: 'Novela Histórica', paginas: 560,
      portada: 'https://covers.openlibrary.org/b/isbn/9788408006268-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(80),
      ejemplares: [
        { id: 'ej-009a', qr: '', condicion: 'bueno',   estado: 'disponible' },
        { id: 'ej-009b', qr: '', condicion: 'regular', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-010', titulo: 'Matar a un ruiseñor', autor: 'Harper Lee', editorial: 'HarperCollins',
      anio: 1960, isbn: '9780061935466', sinopsis: 'A través de los ojos de Scout Finch, niña de 6 años, se narra el juicio de un hombre negro acusado injustamente en el sur de Estados Unidos durante la Gran Depresión.',
      genero: 'Clásicos', paginas: 336,
      portada: 'https://covers.openlibrary.org/b/isbn/9780061935466-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(110),
      ejemplares: [
        { id: 'ej-010a', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-011', titulo: 'Crónica de una muerte anunciada', autor: 'Gabriel García Márquez', editorial: 'Debolsillo',
      anio: 1981, isbn: '9788497930239', sinopsis: 'Un hombre regresa a su pueblo después de veintisiete años y reconstruye los hechos del asesinato de Santiago Nasar. Todos sabían que iba a suceder y nadie lo evitó.',
      genero: 'Realismo Mágico', paginas: 152,
      portada: 'https://covers.openlibrary.org/b/isbn/9788497930239-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(55),
      ejemplares: [
        { id: 'ej-011a', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-011b', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-012', titulo: 'La invención de Morel', autor: 'Adolfo Bioy Casares', editorial: 'Emecé',
      anio: 1940, isbn: '9789877375060', sinopsis: 'Un fugitivo llega a una isla desierta habitada por extrañas apariciones. La máquina de Morel puede capturar la realidad y reproducirla eternamente. Una joya del fantástico argentino.',
      genero: 'Literatura Argentina', paginas: 128,
      portada: 'https://covers.openlibrary.org/b/isbn/9789877375060-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(70),
      ejemplares: [
        { id: 'ej-012a', qr: '', condicion: 'regular', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-013', titulo: 'Harry Potter y la piedra filosofal', autor: 'J.K. Rowling', editorial: 'Salamandra',
      anio: 1997, isbn: '9788478884452', sinopsis: 'Harry Potter descubre que es un mago y es admitido en el Colegio Hogwarts de Magia y Hechicería. El comienzo de una de las sagas más exitosas de la historia de la literatura.',
      genero: 'Fantasía', paginas: 255,
      portada: 'https://covers.openlibrary.org/b/isbn/9788478884452-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(180),
      ejemplares: [
        { id: 'ej-013a', qr: '', condicion: 'bueno', estado: 'prestado' },
        { id: 'ej-013b', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-013c', qr: '', condicion: 'malo',  estado: 'disponible' },
      ]
    },
    {
      id: 'lib-014', titulo: 'El gran Gatsby', autor: 'F. Scott Fitzgerald', editorial: 'Alfaguara',
      anio: 1925, isbn: '9780743273565', sinopsis: 'La historia del misterioso millonario Jay Gatsby y su obsesión con Daisy Buchanan. Un retrato devastador del Sueño Americano y la desilusión de los felices años 20.',
      genero: 'Clásicos', paginas: 180,
      portada: 'https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(95),
      ejemplares: [
        { id: 'ej-014a', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-015', titulo: 'Frankenstein', autor: 'Mary Shelley', editorial: 'Anagrama',
      anio: 1818, isbn: '9780141439471', sinopsis: 'El joven científico Víctor Frankenstein crea vida a partir de piezas de cadáveres. La criatura, solitaria y rechazada, se convierte en una pesadilla para su creador.',
      genero: 'Ciencia Ficción', paginas: 256,
      portada: 'https://covers.openlibrary.org/b/isbn/9780141439471-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(130),
      ejemplares: [
        { id: 'ej-015a', qr: '', condicion: 'regular', estado: 'disponible' },
        { id: 'ej-015b', qr: '', condicion: 'bueno',   estado: 'disponible' },
      ]
    },
    {
      id: 'lib-016', titulo: 'Inteligencia artificial: Una guía para humanos pensantes', autor: 'Melanie Mitchell', editorial: 'Planeta',
      anio: 2019, isbn: '9781250294999', sinopsis: 'Una exploración accesible y rigurosa de la inteligencia artificial: qué puede hacer, qué no puede hacer, y por qué tanto los optimistas como los pesimistas están equivocados.',
      genero: 'Tecnología / Ensayo', paginas: 336,
      portada: 'https://covers.openlibrary.org/b/isbn/9781250294999-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(20),
      ejemplares: [
        { id: 'ej-016a', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-017', titulo: 'El túnel', autor: 'Ernesto Sábato', editorial: 'Sudamericana',
      anio: 1948, isbn: '9788423353804', sinopsis: 'El pintor Juan Pablo Castel asesina a María Iribarne y, desde la cárcel, relata cómo llegó a cometer ese crimen. Una novela existencialista sobre la incomunicación humana.',
      genero: 'Literatura Argentina', paginas: 140,
      portada: 'https://covers.openlibrary.org/b/isbn/9788423353804-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(40),
      ejemplares: [
        { id: 'ej-017a', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-017b', qr: '', condicion: 'regular', estado: 'prestado' },
      ]
    },
    {
      id: 'lib-018', titulo: 'Orgullo y prejuicio', autor: 'Jane Austen', editorial: 'Alba',
      anio: 1813, isbn: '9780141439518', sinopsis: 'La inteligente Elizabeth Bennet y el orgulloso Mr. Darcy se enfrentan a sus propios prejuicios en la Inglaterra rural del siglo XIX. Una de las novelas románticas más amadas de todos los tiempos.',
      genero: 'Clásicos', paginas: 432,
      portada: 'https://covers.openlibrary.org/b/isbn/9780141439518-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(160),
      ejemplares: [
        { id: 'ej-018a', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-019', titulo: 'El perfume', autor: 'Patrick Süskind', editorial: 'Seix Barral',
      anio: 1985, isbn: '9780141182438', sinopsis: 'Jean-Baptiste Grenouille nació sin olor corporal pero con un extraordinario olfato. Su obsesión: crear el perfume más sublime del mundo, aunque para ello deba asesinar.',
      genero: 'Novela Histórica', paginas: 255,
      portada: 'https://covers.openlibrary.org/b/isbn/9780141182438-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(75),
      ejemplares: [
        { id: 'ej-019a', qr: '', condicion: 'bueno',   estado: 'disponible' },
        { id: 'ej-019b', qr: '', condicion: 'regular', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-020', titulo: 'Brevísima historia del tiempo', autor: 'Stephen Hawking', editorial: 'Crítica',
      anio: 1988, isbn: '9780553380163', sinopsis: 'Un viaje por los grandes temas de la física moderna: el Big Bang, los agujeros negros, el tiempo y el destino del universo, explicados con extraordinaria claridad y sentido del humor.',
      genero: 'Ciencia', paginas: 212,
      portada: 'https://covers.openlibrary.org/b/isbn/9780553380163-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(50),
      ejemplares: [
        { id: 'ej-020a', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
    {
      id: 'lib-021', titulo: 'Harry Potter y la cámara secreta', autor: 'J.K. Rowling', editorial: 'Salamandra',
      anio: 1998, isbn: '9788478884957', sinopsis: 'Tras un verano insoportable con los Dursley, Harry regresa a Hogwarts donde unos misteriosos ataques convierten a los alumnos en piedra. La cámara secreta ha sido abierta.',
      genero: 'Fantasía', paginas: 286,
      portada: 'https://covers.openlibrary.org/b/isbn/9788478884957-L.jpg',
      estado: 'disponible', validado: true, fechaAlta: fechaHaceNDias(2),
      ejemplares: [
        { id: 'ej-021a', qr: '', condicion: 'bueno', estado: 'disponible' },
        { id: 'ej-021b', qr: '', condicion: 'bueno', estado: 'disponible' },
      ]
    },
  ];

  const seedLectores = [
    {
      id: 'lec-001', nombre: 'Laura', apellido: 'Méndez', email: 'laura@demo.com',
      dni: '33456789', telefono: '1145678901', categoria: 'adulto', tutor: null,
      fechaAlta: fechaHaceNDias(365), activo: true, pin: '1234', qr: '',
      generosInteres: ['Literatura Argentina', 'Realismo Mágico', 'Clásicos'],
      multasPendientes: 0,
    },
    {
      id: 'lec-002', nombre: 'Martín', apellido: 'Gómez', email: 'martin@demo.com',
      dni: '40123456', telefono: '1156789012', categoria: 'adulto', tutor: null,
      fechaAlta: fechaHaceNDias(200), activo: true, pin: '5678', qr: '',
      generosInteres: ['Ciencia Ficción', 'Tecnología / Ensayo', 'Historia / Ensayo'],
      multasPendientes: 1500,
    },
    {
      id: 'lec-003', nombre: 'Sofía', apellido: 'Torres', email: 'sofia@demo.com',
      dni: '45678901', telefono: '1167890123', categoria: 'menor', tutor: 'Ana Torres',
      fechaAlta: fechaHaceNDias(100), activo: true, pin: '9012', qr: '',
      generosInteres: ['Literatura Infantil', 'Fantasía'],
      multasPendientes: 0,
    },
    {
      id: 'lec-004', nombre: 'Roberto', apellido: 'Sánchez', email: 'roberto@demo.com',
      dni: '20345678', telefono: '1178901234', categoria: 'docente', tutor: null,
      fechaAlta: fechaHaceNDias(500), activo: true, pin: '3456', qr: '',
      generosInteres: ['Historia / Ensayo', 'Clásicos', 'Novela Histórica'],
      multasPendientes: 0,
    },
    {
      id: 'lec-005', nombre: 'Elena', apellido: 'Rodríguez', email: 'elena@demo.com',
      dni: '15678902', telefono: '1189012345', categoria: 'senior', tutor: null,
      fechaAlta: fechaHaceNDias(730), activo: true, pin: '7890', qr: '',
      generosInteres: ['Clásicos', 'Novela Histórica', 'Literatura Argentina'],
      multasPendientes: 0,
    },
    {
      id: 'bib-001', nombre: 'Carlos', apellido: 'Fernández', email: 'bibliotecario@demo.com',
      dni: '28901234', telefono: '1190123456', categoria: 'personal', tutor: null,
      fechaAlta: fechaHaceNDias(1000), activo: true, pin: '0000', qr: '',
      generosInteres: [], multasPendientes: 0, rol: 'bibliotecario',
    },
    {
      id: 'adm-001', nombre: 'Ana', apellido: 'López', email: 'admin@demo.com',
      dni: '25678901', telefono: '1101234567', categoria: 'personal', tutor: null,
      fechaAlta: fechaHaceNDias(1000), activo: true, pin: '9999', qr: '',
      generosInteres: [], multasPendientes: 0, rol: 'administrador',
    },
  ];

  const seedPrestamos = [
    {
      id: 'pres-001', lectorId: 'lec-001', ejemplarId: 'ej-002a', libroId: 'lib-002',
      fechaPrestamo: fechaHaceNDias(5), fechaVencimiento: fechaEnDias(9),
      fechaDevolucion: null, estado: 'activo', tardio: false,
    },
    {
      id: 'pres-002', lectorId: 'lec-002', ejemplarId: 'ej-008b', libroId: 'lib-008',
      fechaPrestamo: fechaHaceNDias(20), fechaVencimiento: fechaHaceNDias(6),
      fechaDevolucion: null, estado: 'vencido', tardio: true,
    },
    {
      id: 'pres-003', lectorId: 'lec-003', ejemplarId: 'ej-005c', libroId: 'lib-005',
      fechaPrestamo: fechaHaceNDias(3), fechaVencimiento: fechaEnDias(4),
      fechaDevolucion: null, estado: 'activo', tardio: false,
    },
    {
      id: 'pres-004', lectorId: 'lec-001', ejemplarId: 'ej-013a', libroId: 'lib-013',
      fechaPrestamo: fechaHaceNDias(30), fechaVencimiento: fechaHaceNDias(16),
      fechaDevolucion: fechaHaceNDias(14), estado: 'devuelto', tardio: true,
    },
    {
      id: 'pres-005', lectorId: 'lec-004', ejemplarId: 'ej-017b', libroId: 'lib-017',
      fechaPrestamo: fechaHaceNDias(10), fechaVencimiento: fechaEnDias(11),
      fechaDevolucion: null, estado: 'activo', tardio: false,
    },
    {
      id: 'pres-006', lectorId: 'lec-005', ejemplarId: 'ej-002a', libroId: 'lib-002',
      fechaPrestamo: fechaHaceNDias(60), fechaVencimiento: fechaHaceNDias(46),
      fechaDevolucion: fechaHaceNDias(45), estado: 'devuelto', tardio: false,
    },
    {
      id: 'pres-007', lectorId: 'lec-002', ejemplarId: 'ej-004a', libroId: 'lib-004',
      fechaPrestamo: fechaHaceNDias(45), fechaVencimiento: fechaHaceNDias(31),
      fechaDevolucion: fechaHaceNDias(28), estado: 'devuelto', tardio: false,
    },
  ];

  const seedReservas = [
    {
      id: 'res-001', lectorId: 'lec-003', libroId: 'lib-004',
      fechaReserva: fechaHaceNDias(2), fechaVencimientoRetiro: null,
      estado: 'pendiente',
    },
    {
      id: 'res-002', lectorId: 'lec-001', libroId: 'lib-008',
      fechaReserva: fechaHaceNDias(1), fechaVencimientoRetiro: null,
      estado: 'pendiente',
    },
  ];

  const seedNotificaciones = [
    {
      id: 'not-001', lectorId: 'lec-001', tipo: 'vencimiento_proximo',
      titulo: 'Préstamo próximo a vencer',
      descripcion: 'Tu préstamo de "Cien años de soledad" vence en 9 días.',
      fecha: now(), leida: false, icono: '⏰',
    },
    {
      id: 'not-002', lectorId: 'lec-002', tipo: 'prestamo_vencido',
      titulo: '⚠️ Préstamo vencido',
      descripcion: 'Tu préstamo de "Sapiens" venció hace 6 días. Por favor devolvelo a la brevedad.',
      fecha: fechaHaceNDias(1), leida: false, icono: '🚨',
    },
    {
      id: 'not-003', lectorId: 'lec-001', tipo: 'recomendacion',
      titulo: 'Nuevo libro recomendado',
      descripcion: 'Basado en tu historial, creemos que te encantará "Rayuela" de Cortázar.',
      fecha: fechaHaceNDias(3), leida: true, icono: '✨',
    },
    {
      id: 'not-004', lectorId: 'lec-003', tipo: 'reserva_disponible',
      titulo: '📚 ¡Tu reserva está lista!',
      descripcion: '"1984" ya está disponible para retirar. Tenés 48 horas para buscarlo.',
      fecha: now(), leida: false, icono: '🔔',
    },
  ];

  const seedConfig = {
    plazoPrestamoDias:      { adulto: 14, menor: 7, docente: 21, senior: 14 },
    limiteEjemplares:       { adulto: 3,  menor: 2, docente: 5,  senior: 3  },
    limiteReservas:         { adulto: 3,  menor: 2, docente: 5,  senior: 3  },
    plazoRetiroReservaDias: 2,
    multaPorDiaDemora:      100, // pesos
    recordatorioAntesDias:  3,
  };

  const seedAuditoria = [
    { id: uuid(), tipo: 'alta_libro', descripcion: 'Alta del libro "El Aleph"', usuario: 'bib-001', fecha: fechaHaceNDias(120) },
    { id: uuid(), tipo: 'alta_lector', descripcion: 'Alta del lector Laura Méndez', usuario: 'bib-001', fecha: fechaHaceNDias(365) },
    { id: uuid(), tipo: 'prestamo', descripcion: 'Préstamo: "Cien años de soledad" → Laura Méndez', usuario: 'bib-001', fecha: fechaHaceNDias(5) },
    { id: uuid(), tipo: 'devolucion', descripcion: 'Devolución: "Harry Potter I" → Laura Méndez (tardía)', usuario: 'bib-001', fecha: fechaHaceNDias(14) },
    { id: uuid(), tipo: 'correccion_ocr', descripcion: 'Corrección OCR: campo "editorial" en "El Aleph"', usuario: 'bib-001', fecha: fechaHaceNDias(119) },
  ];

  /* ── Init ── */
  function init() {
    if (get(KEYS.initialized)) {
      // Actualizar estados vencidos
      checkVencimientos();
      return;
    }
    // Generar QRs para ejemplares y lectores
    seedLibros.forEach(l => l.ejemplares.forEach(e => { e.qr = `BT-${l.id}-${e.id}`; }));
    seedLectores.forEach(l => { l.qr = `BTL-${l.id}`; });

    set(KEYS.libros,        seedLibros);
    set(KEYS.lectores,      seedLectores);
    set(KEYS.prestamos,     seedPrestamos);
    set(KEYS.reservas,      seedReservas);
    set(KEYS.notificaciones,seedNotificaciones);
    set(KEYS.config,        seedConfig);
    set(KEYS.auditoria,     seedAuditoria);
    set(KEYS.aprendizaje,   { correcciones: [], clics: [], recomendaciones: [] });
    set(KEYS.initialized,   true);

    checkVencimientos();
  }

  function checkVencimientos() {
    const prestamos = get(KEYS.prestamos) || [];
    const lectoresList = get(KEYS.lectores) || [];
    let prestamosChanged = false;
    let lectoresChanged  = false;
    const config = get(KEYS.config) || seedConfig;

    prestamos.forEach(p => {
      if (p.estado === 'activo' && new Date(p.fechaVencimiento) < new Date()) {
        p.estado = 'vencido';
        p.tardio = true;
        prestamosChanged = true;
        // BUG FIX: acumular multa al detectar vencimiento (solo si aún no se aplicó)
        if (!p._multaAplicada) {
          p._multaAplicada = true;
          const diasTarde = Math.ceil((new Date() - new Date(p.fechaVencimiento)) / 86400000);
          const multa = diasTarde * (config.multaPorDiaDemora || 100);
          const lIdx = lectoresList.findIndex(l => l.id === p.lectorId);
          if (lIdx >= 0) {
            lectoresList[lIdx].multasPendientes = (lectoresList[lIdx].multasPendientes || 0) + multa;
            lectoresChanged = true;
          }
        }
      }
    });
    if (prestamosChanged) set(KEYS.prestamos, prestamos);
    if (lectoresChanged)  set(KEYS.lectores, lectoresList);
  }

  /* ── CRUD Libros ── */
  const libros = {
    getAll: () => get(KEYS.libros) || [],
    get: (id) => (get(KEYS.libros) || []).find(l => l.id === id),
    add: (libro) => {
      const libros = get(KEYS.libros) || [];
      libro.id = libro.id || `lib-${Date.now()}`;
      libro.fechaAlta = now();
      libro.ejemplares = libro.ejemplares || [];
      libros.push(libro);
      set(KEYS.libros, libros);
      auditoria.log('alta_libro', `Alta del libro "${libro.titulo}"`, sesion.get()?.id);
      return libro;
    },
    update: (id, changes) => {
      const lista = get(KEYS.libros) || [];
      const idx = lista.findIndex(l => l.id === id);
      if (idx < 0) return null;
      lista[idx] = { ...lista[idx], ...changes };
      set(KEYS.libros, lista);
      auditoria.log('edicion_libro', `Edición del libro "${lista[idx].titulo}" (ID: ${id})`, sesion.get()?.id);
      return lista[idx];
    },
    delete: (id) => {
      const lista = (get(KEYS.libros) || []).filter(l => l.id !== id);
      set(KEYS.libros, lista);
      auditoria.log('baja_libro', `Baja del libro id:${id}`, sesion.get()?.id);
    },
    addEjemplar: (libroId, ejemplar) => {
      const lista = get(KEYS.libros) || [];
      const idx = lista.findIndex(l => l.id === libroId);
      if (idx < 0) return null;
      ejemplar.id = `ej-${Date.now()}`;
      ejemplar.qr = `BT-${libroId}-${ejemplar.id}`;
      ejemplar.estado = 'disponible';
      lista[idx].ejemplares.push(ejemplar);
      set(KEYS.libros, lista);
      return ejemplar;
    },
    getDisponible: (libroId) => {
      const libro = (get(KEYS.libros) || []).find(l => l.id === libroId);
      return libro?.ejemplares.find(e => e.estado === 'disponible') || null;
    },
    updateEjemplar: (libroId, ejemplarId, changes) => {
      const lista = get(KEYS.libros) || [];
      const li = lista.find(l => l.id === libroId);
      if (!li) return;
      const ei = li.ejemplares.findIndex(e => e.id === ejemplarId);
      if (ei < 0) return;
      li.ejemplares[ei] = { ...li.ejemplares[ei], ...changes };
      set(KEYS.libros, lista);
    },
    getByQR: (qr) => {
      const all = get(KEYS.libros) || [];
      for (const libro of all) {
        const ej = libro.ejemplares.find(e => e.qr === qr);
        if (ej) return { libro, ejemplar: ej };
      }
      return null;
    },
    search: (q, genero) => {
      let lista = get(KEYS.libros) || [];
      lista = lista.filter(l => l.validado);
      if (q) {
        const lq = q.toLowerCase();
        lista = lista.filter(l =>
          l.titulo.toLowerCase().includes(lq) ||
          l.autor.toLowerCase().includes(lq) ||
          l.isbn?.includes(lq) ||
          l.genero?.toLowerCase().includes(lq)
        );
      }
      if (genero && genero !== 'Todos') {
        lista = lista.filter(l => l.genero === genero);
      }
      return lista;
    },
    getGeneros: () => {
      const lista = get(KEYS.libros) || [];
      return [...new Set(lista.map(l => l.genero).filter(Boolean))];
    },
  };

  /* ── CRUD Lectores ── */
  const lectores = {
    getAll: () => (get(KEYS.lectores) || []).filter(l => !l.rol),
    get: (id) => (get(KEYS.lectores) || []).find(l => l.id === id),
    getByEmail: (email) => (get(KEYS.lectores) || []).find(l => l.email === email),
    getByQR: (qr) => (get(KEYS.lectores) || []).find(l => l.qr === qr),
    add: (lector) => {
      const lista = get(KEYS.lectores) || [];
      lector.id = lector.id || `lec-${Date.now()}`;
      lector.fechaAlta = now();
      lector.qr = `BTL-${lector.id}`;
      lector.multasPendientes = 0;
      lector.activo = true;
      lista.push(lector);
      set(KEYS.lectores, lista);
      auditoria.log('alta_lector', `Alta del lector ${lector.nombre} ${lector.apellido}`, sesion.get()?.id);
      return lector;
    },
    update: (id, changes) => {
      const lista = get(KEYS.lectores) || [];
      const idx = lista.findIndex(l => l.id === id);
      if (idx < 0) return null;
      lista[idx] = { ...lista[idx], ...changes };
      set(KEYS.lectores, lista);
      return lista[idx];
    },
    canBorrow: (lectorId) => {
      const lector = (get(KEYS.lectores) || []).find(l => l.id === lectorId);
      if (!lector || !lector.activo) return { ok: false, razon: 'Lector inactivo o no encontrado' };
      if (lector.multasPendientes > 0) return { ok: false, razon: `Multa pendiente: $${lector.multasPendientes}. Saldala en el mostrador.` };
      const config = get(KEYS.config);
      const limite = config.limiteEjemplares[lector.categoria] || 3;
      const activos = (get(KEYS.prestamos) || []).filter(p => p.lectorId === lectorId && p.estado === 'activo').length;
      if (activos >= limite) return { ok: false, razon: `Alcanzaste el límite de ${limite} préstamos simultáneos para tu categoría` };
      const vencidos = (get(KEYS.prestamos) || []).filter(p => p.lectorId === lectorId && p.estado === 'vencido').length;
      if (vencidos > 0) return { ok: false, razon: 'Tenés préstamos vencidos sin devolver. Devolvelos antes de pedir nuevos.' };
      return { ok: true };
    },
    // BUG FIX: versión separada para reservas (permite reservar aunque haya vencidos, para no bloquear al lector completamente)
    canReserve: (lectorId) => {
      const lector = (get(KEYS.lectores) || []).find(l => l.id === lectorId);
      if (!lector || !lector.activo) return { ok: false, razon: 'Lector inactivo o no encontrado' };
      if (lector.multasPendientes > 0) return { ok: false, razon: `Multa pendiente: $${lector.multasPendientes}. Saldala en el mostrador.` };
      const config = get(KEYS.config);
      const limiteRes = config.limiteReservas?.[lector.categoria] || 3;
      const resActivas = (get(KEYS.reservas) || []).filter(r => r.lectorId === lectorId && ['pendiente','lista'].includes(r.estado)).length;
      if (resActivas >= limiteRes) return { ok: false, razon: `Alcanzaste el límite de ${limiteRes} reservas simultáneas` };
      return { ok: true };
    },
  };

  /* ── CRUD Préstamos ── */
  const prestamos = {
    getAll: () => get(KEYS.prestamos) || [],
    get: (id) => (get(KEYS.prestamos) || []).find(p => p.id === id),
    getByLector: (lectorId) => (get(KEYS.prestamos) || []).filter(p => p.lectorId === lectorId),
    crear: (lectorId, ejemplarId, libroId) => {
      const config = get(KEYS.config);
      const lector = (get(KEYS.lectores) || []).find(l => l.id === lectorId);
      const plazo = config.plazoPrestamoDias[lector?.categoria] || 14;
      const prestamo = {
        id: `pres-${Date.now()}`,
        lectorId, ejemplarId, libroId,
        fechaPrestamo: now(),
        fechaVencimiento: fechaEnDias(plazo),
        fechaDevolucion: null,
        estado: 'activo',
        tardio: false,
      };
      const lista = get(KEYS.prestamos) || [];
      lista.push(prestamo);
      set(KEYS.prestamos, lista);
      libros.updateEjemplar(libroId, ejemplarId, { estado: 'prestado' });

      // Marcar la reserva como completada para que deje de figurar en reservas pendientes y pase únicamente a préstamos activos
      const listaReservas = get(KEYS.reservas) || [];
      const resIdx = listaReservas.findIndex(r => r.lectorId === lectorId && r.libroId === libroId && ['pendiente', 'lista'].includes(r.estado));
      if (resIdx >= 0) {
        listaReservas[resIdx].estado = 'completada';
        listaReservas[resIdx].fechaCompletada = now();
        set(KEYS.reservas, listaReservas);
      }

      // Notificación al lector
      const libroObj = (get(KEYS.libros) || []).find(l => l.id === libroId);
      notificaciones.add({
        id: `not-${Date.now()}`,
        lectorId,
        tipo: 'reserva_confirmada',
        titulo: '✅ Préstamo autorizado',
        descripcion: `Tu reserva de "${libroObj?.titulo || 'Libro'}" fue confirmada y tu préstamo ya se encuentra activo.`,
        fecha: now(),
        leida: false,
        icono: '📚',
      });

      const lectorNombre = lector ? `${lector.nombre} ${lector.apellido} (DNI: ${lector.dni})` : lectorId;
      auditoria.log('prestamo', `Préstamo otorgado: "${libroObj?.titulo || libroId}" a ${lectorNombre}`, sesion.get()?.id);
      return prestamo;
    },
    devolver: (prestamoId) => {
      const lista = get(KEYS.prestamos) || [];
      const idx = lista.findIndex(p => p.id === prestamoId);
      if (idx < 0) return null;
      const p = lista[idx];
      const tardio = new Date() > new Date(p.fechaVencimiento);
      lista[idx] = { ...p, fechaDevolucion: now(), estado: 'devuelto', tardio };
      set(KEYS.prestamos, lista);
      libros.updateEjemplar(p.libroId, p.ejemplarId, { estado: 'disponible' });
      if (tardio) {
        const diasTarde = Math.ceil((new Date() - new Date(p.fechaVencimiento)) / 86400000);
        const config = get(KEYS.config);
        const multa = diasTarde * config.multaPorDiaDemora;
        lectores.update(p.lectorId, { multasPendientes: ((lectores.get(p.lectorId)?.multasPendientes || 0) + multa) });
      }
      const lectorObj = (get(KEYS.lectores) || []).find(l => l.id === p.lectorId);
      const libroObj  = (get(KEYS.libros) || []).find(l => l.id === p.libroId);
      const lectorNombre = lectorObj ? `${lectorObj.nombre} ${lectorObj.apellido} (DNI: ${lectorObj.dni})` : p.lectorId;
      const libroTitulo  = libroObj ? `"${libroObj.titulo}"` : p.libroId;
      auditoria.log('devolucion', `Devolución registrada: ${libroTitulo} de ${lectorNombre}${tardio ? ' (tardía)' : ''}`, sesion.get()?.id);
      return lista[idx];
    },
    getStats: () => {
      const all = get(KEYS.prestamos) || [];
      return {
        total: all.length,
        activos: all.filter(p => p.estado === 'activo').length,
        vencidos: all.filter(p => p.estado === 'vencido').length,
        devueltos: all.filter(p => p.estado === 'devuelto').length,
        tasaTardia: all.length ? (all.filter(p => p.tardio).length / all.length * 100).toFixed(1) : 0,
      };
    },
    topLibros: (n = 5) => {
      const all = get(KEYS.prestamos) || [];
      const count = {};
      all.forEach(p => { count[p.libroId] = (count[p.libroId] || 0) + 1; });
      return Object.entries(count)
        .sort((a, b) => b[1] - a[1])
        .slice(0, n)
        .map(([id, c]) => ({ libro: libros.get(id), count: c }))
        .filter(x => x.libro);
    },
  };

  /* ── CRUD Reservas ── */
  const reservas = {
    getAll: () => get(KEYS.reservas) || [],
    getByLector: (lectorId) => (get(KEYS.reservas) || []).filter(r => r.lectorId === lectorId),
    crear: (lectorId, libroId) => {
      const lista = get(KEYS.reservas) || [];
      const yaExiste = lista.find(r => r.lectorId === lectorId && r.libroId === libroId && ['pendiente','lista'].includes(r.estado));
      if (yaExiste) return { error: 'Ya tenés una reserva activa para este libro' };
      // BUG FIX: verificar límite de reservas simultáneas
      const config = get(KEYS.config) || seedConfig;
      const lector = (get(KEYS.lectores) || []).find(l => l.id === lectorId);
      const limiteRes = config.limiteReservas?.[lector?.categoria] || 3;
      const resActivas = lista.filter(r => r.lectorId === lectorId && ['pendiente','lista'].includes(r.estado)).length;
      if (resActivas >= limiteRes) return { error: `Límite de ${limiteRes} reservas simultáneas alcanzado` };
      // Verificar que el libro existe y no fue dado de baja
      const libro = (get(KEYS.libros) || []).find(l => l.id === libroId);
      if (!libro || !libro.validado) return { error: 'El libro no está disponible en el catálogo' };
      const reserva = {
        id: `res-${Date.now()}`,
        lectorId, libroId,
        fechaReserva: now(),
        fechaVencimientoRetiro: null,
        estado: 'pendiente',
      };
      lista.push(reserva);
      set(KEYS.reservas, lista);
      return reserva;
    },
    cancelar: (reservaId) => {
      const lista = get(KEYS.reservas) || [];
      const idx = lista.findIndex(r => r.id === reservaId);
      if (idx < 0) return;
      lista[idx].estado = 'cancelada';
      set(KEYS.reservas, lista);
    },
    marcarLista: (reservaId) => {
      const lista = get(KEYS.reservas) || [];
      const idx = lista.findIndex(r => r.id === reservaId);
      if (idx < 0) return;
      const config = get(KEYS.config);
      lista[idx].estado = 'lista';
      lista[idx].fechaVencimientoRetiro = fechaEnDias(config.plazoRetiroReservaDias);
      set(KEYS.reservas, lista);
    },
    getColaPorLibro: (libroId) => {
      return (get(KEYS.reservas) || [])
        .filter(r => r.libroId === libroId && ['pendiente','lista'].includes(r.estado))
        .sort((a, b) => new Date(a.fechaReserva) - new Date(b.fechaReserva));
    },
  };

  /* ── Notificaciones ── */
  const notificaciones = {
    getByLector: (lectorId) => (get(KEYS.notificaciones) || []).filter(n => n.lectorId === lectorId).sort((a,b) => new Date(b.fecha) - new Date(a.fecha)),
    countUnread: (lectorId) => (get(KEYS.notificaciones) || []).filter(n => n.lectorId === lectorId && !n.leida).length,
    add: (notif) => {
      const lista = get(KEYS.notificaciones) || [];
      notif.id = `not-${Date.now()}`;
      notif.fecha = now();
      notif.leida = false;
      lista.push(notif);
      set(KEYS.notificaciones, lista);
    },
    marcarLeida: (id) => {
      const lista = get(KEYS.notificaciones) || [];
      const idx = lista.findIndex(n => n.id === id);
      if (idx >= 0) { lista[idx].leida = true; set(KEYS.notificaciones, lista); }
    },
    marcarTodasLeidas: (lectorId) => {
      const lista = get(KEYS.notificaciones) || [];
      lista.forEach(n => { if (n.lectorId === lectorId) n.leida = true; });
      set(KEYS.notificaciones, lista);
    },
  };

  /* ── Config ── */
  const config = {
    get: () => get(KEYS.config) || seedConfig,
    update: (changes) => {
      const c = get(KEYS.config) || seedConfig;
      const nuevo = { ...c, ...changes };
      set(KEYS.config, nuevo);
      return nuevo;
    },
  };

  /* ── Auditoría ── */
  const auditoria = {
    getAll: () => (get(KEYS.auditoria) || []).sort((a,b) => new Date(b.fecha) - new Date(a.fecha)),
    log: (tipo, descripcion, usuarioId) => {
      const lista = get(KEYS.auditoria) || [];
      lista.unshift({ id: uuid(), tipo, descripcion, usuario: usuarioId || 'sistema', fecha: now() });
      set(KEYS.auditoria, lista.slice(0, 200)); // máximo 200 registros
    },
  };

  /* ── Aprendizaje ── */
  const aprendizaje = {
    get: () => get(KEYS.aprendizaje) || { correcciones: [], clics: [], recomendaciones: [] },
    registrarCorreccion: (campo, valorOCR, valorCorregido) => {
      const data = get(KEYS.aprendizaje) || { correcciones: [], clics: [], recomendaciones: [] };
      data.correcciones.push({ campo, valorOCR, valorCorregido, fecha: now() });
      set(KEYS.aprendizaje, data);
    },
    registrarClic: (lectorId, libroId, tipo) => {
      const data = get(KEYS.aprendizaje) || { correcciones: [], clics: [], recomendaciones: [] };
      data.clics.push({ lectorId, libroId, tipo, fecha: now() });
      set(KEYS.aprendizaje, data);
    },
  };

  /* ── Sesión ── */
  const sesion = {
    get: () => get(KEYS.sesion),
    set: (user) => set(KEYS.sesion, user),
    clear: () => localStorage.removeItem(KEYS.sesion),
    login: (email, pin) => {
      const todos = get(KEYS.lectores) || [];
      const user = todos.find(l => l.email === email && String(l.pin) === String(pin));
      if (!user) return null;
      // BUG FIX: no permitir login de lectores inactivos (excepto personal con rol)
      if (user.activo === false && !user.rol) return null;
      set(KEYS.sesion, user);
      return user;
    },
  };

  return { init, libros, lectores, prestamos, reservas, notificaciones, config, auditoria, aprendizaje, sesion, uuid, now };
})();

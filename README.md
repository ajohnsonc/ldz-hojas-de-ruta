# LDZ Constructora — Hojas de Ruta
## Guía de instalación paso a paso

---

## ARCHIVOS DEL PROYECTO

```
ldz-app/
├── index.html          → Pantalla de login
├── app.html            → App principal
├── supabase_setup.sql  → Script para crear la base de datos
└── README.md           → Esta guía
```

---

## PASO 1 — Crear cuenta en GitHub (5 min)

1. Ve a **https://github.com**
2. Clic en **Sign up**
3. Ingresa tu email, contraseña y elige un nombre de usuario
4. Elige el plan **Free**
5. Verifica tu email

---

## PASO 2 — Subir el proyecto a GitHub (5 min)

1. Una vez dentro de GitHub, clic en el botón verde **New**
2. Nombre del repositorio: `ldz-hojas-de-ruta`
3. Déjalo en **Public**
4. Marca **Add a README file**
5. Clic en **Create repository**
6. Clic en **Add file → Upload files**
7. Arrastra los 4 archivos: `index.html`, `app.html`, `supabase_setup.sql`, `README.md`
8. Clic en **Commit changes**

---

## PASO 3 — Crear proyecto en Supabase (10 min)

1. Ve a **https://supabase.com**
2. Clic en **Start your project** → **Sign up with GitHub** (usa la cuenta que creaste)
3. Clic en **New project**
4. Nombre: `ldz-hojas-de-ruta`
5. Elige una contraseña segura para la base de datos (guárdala)
6. Región: **South America (São Paulo)** — la más cercana a Chile
7. Clic en **Create new project** (tarda ~2 min)

---

## PASO 4 — Crear la base de datos (5 min)

1. Dentro de tu proyecto Supabase, ve al menú izquierdo → **SQL Editor**
2. Clic en **New query**
3. Abre el archivo `supabase_setup.sql` con el Bloc de notas
4. Copia todo el contenido y pégalo en el editor
5. Clic en **Run** (botón verde)
6. Deberías ver: `Success. No rows returned`

---

## PASO 5 — Obtener las claves de Supabase (2 min)

1. En el menú izquierdo → **Settings → API**
2. Copia estos dos valores:
   - **Project URL** → algo como `https://abcdefgh.supabase.co`
   - **anon public key** → una cadena larga de letras y números

---

## PASO 6 — Conectar la app a Supabase (5 min)

En los archivos `index.html` y `app.html`, busca estas dos líneas y reemplaza con tus valores:

```javascript
const SUPABASE_URL = 'https://TU_PROYECTO.supabase.co';
const SUPABASE_KEY = 'TU_ANON_KEY';
```

Por ejemplo:
```javascript
const SUPABASE_URL = 'https://abcdefgh.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Luego vuelve a subir los archivos actualizados a GitHub (mismos pasos del Paso 2).

---

## PASO 7 — Crear los usuarios (10 min)

Por cada persona del equipo:

1. En Supabase → **Authentication → Users**
2. Clic en **Add user → Create new user**
3. Ingresa email y contraseña temporal
4. Luego ve a **SQL Editor** y ejecuta este comando para asignar el rol:

```sql
update public.usuarios
set nombre = 'Nombre Apellido', rol = 'Legal', obra = 'Todas'
where email = 'correo@ldz.cl';
```

**Roles disponibles:**
- `Legal` — revisa documentos legales
- `Laboral` — revisa documentos laborales
- `Prevención` — revisa prevención de riesgos
- `Calidad` — revisa calidad
- `J. Bodega` — jefe de bodega
- `J. Terreno` — jefe de terreno
- `Of. Técnica` — jefe de oficina técnica
- `Adm. Obra` — administrador de obra
- `Finanzas` — finanzas y pago
- `Pagador` — solo vista resumen
- `Admin` — acceso total

**Para asignar obra específica** (si una persona solo trabaja en una obra):
```sql
update public.usuarios
set obra = '072 – Holiday Inn Vitacura'
where email = 'correo@ldz.cl';
```

---

## PASO 8 — Publicar en Vercel (5 min)

1. Ve a **https://vercel.com**
2. Clic en **Sign up → Continue with GitHub**
3. Clic en **Add New → Project**
4. Selecciona el repositorio `ldz-hojas-de-ruta`
5. Clic en **Deploy**
6. En ~1 minuto tendrás una URL como `ldz-hojas-de-ruta.vercel.app`

¡Listo! Comparte esa URL con tu equipo.

---

## AGREGAR EPs NUEVOS CADA QUINCENA

Cuando descargues el nuevo reporte de Iconstruye, ejecuta en SQL Editor:

```sql
-- Solo insertar EPs nuevos (no pisa los existentes)
insert into public.eps (numero_ep, subcontratista, descripcion, obra, monto, monto_fmt, tipo, quincena)
values
  ('072-35-1', 'Nombre Subcontratista', 'Descripción trabajo', '072 – Holiday Inn Vitacura', 1500000, '$1.500.000', 'Avance', 'Q2-2026-03')
on conflict (numero_ep) do nothing;  -- si ya existe, lo ignora
```

El `on conflict do nothing` garantiza que nunca se pisan los EPs que ya tienen aprobaciones.

---

## CONECTAR AL SERVIDOR SQL DE ICONSTRUYE (futuro)

Cuando estés listo, esto se puede automatizar con:
1. Un script que lea la BD de Iconstruye cada X horas
2. Inserte solo EPs nuevos en Supabase
3. Sin tocar ningún EP que ya tenga aprobaciones

Esto requiere abrir un puerto en el servidor de la oficina o crear una VPN.
Podemos trabajar en esto como siguiente etapa.

---

## SOPORTE

Si algo no funciona, vuelve a esta conversación con el mensaje de error
y lo resolvemos paso a paso.

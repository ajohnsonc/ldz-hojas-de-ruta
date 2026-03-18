-- ============================================================
-- LDZ CONSTRUCTORA — Script de base de datos
-- Ejecutar en Supabase > SQL Editor
-- ============================================================

-- 1. TABLA DE USUARIOS (perfiles)
-- Extiende la tabla auth.users de Supabase
create table public.usuarios (
  id uuid references auth.users(id) on delete cascade primary key,
  nombre text not null,
  email text not null,
  rol text not null check (rol in (
    'Legal','Laboral','Prevención','Calidad',
    'J. Bodega','J. Terreno','Of. Técnica',
    'Adm. Obra','Finanzas','Pagador','Admin'
  )),
  obra text default 'Todas',  -- 'Todas' o nombre de obra específica
  activo boolean default true,
  created_at timestamptz default now()
);

-- 2. TABLA DE EPs (viene de Iconstruye)
create table public.eps (
  id serial primary key,
  numero_ep text not null unique,       -- ej: '072-22-13'
  subcontratista text not null,
  descripcion text,
  obra text not null,
  monto numeric default 0,
  monto_fmt text,                        -- ej: '$7.377.832'
  tipo text default 'Avance',           -- 'Avance' o 'Retención'
  quincena text,                         -- ej: 'Q1-2026-03'
  activo boolean default true,
  created_at timestamptz default now()
);

-- 3. TABLA DE APROBACIONES
create table public.aprobaciones (
  id serial primary key,
  ep_id integer references public.eps(id) on delete cascade,
  rol text not null,
  estado text not null check (estado in ('ok','obs','pend')),
  observacion text default '',
  usuario_id uuid references auth.users(id),
  usuario_nombre text,
  updated_at timestamptz default now(),
  unique(ep_id, rol)  -- un registro por EP+rol, se actualiza con upsert
);

-- ============================================================
-- SEGURIDAD: Row Level Security (RLS)
-- ============================================================

-- Activar RLS en todas las tablas
alter table public.usuarios enable row level security;
alter table public.eps enable row level security;
alter table public.aprobaciones enable row level security;

-- USUARIOS: cada uno solo ve su propio perfil
-- Admin ve todos
create policy "usuarios_select" on public.usuarios
  for select using (
    auth.uid() = id
    or exists (select 1 from public.usuarios u where u.id = auth.uid() and u.rol = 'Admin')
  );

create policy "usuarios_update" on public.usuarios
  for update using (auth.uid() = id);

-- EPS: todos los usuarios autenticados pueden ver EPs
-- Solo Admin puede insertar/actualizar EPs
create policy "eps_select" on public.eps
  for select using (auth.role() = 'authenticated');

create policy "eps_insert" on public.eps
  for insert with check (
    exists (select 1 from public.usuarios u where u.id = auth.uid() and u.rol = 'Admin')
  );

create policy "eps_update" on public.eps
  for update using (
    exists (select 1 from public.usuarios u where u.id = auth.uid() and u.rol = 'Admin')
  );

-- APROBACIONES: todos pueden leer
-- Solo puede insertar/actualizar quien tiene el rol correspondiente
create policy "aprobaciones_select" on public.aprobaciones
  for select using (auth.role() = 'authenticated');

create policy "aprobaciones_upsert" on public.aprobaciones
  for insert with check (
    exists (
      select 1 from public.usuarios u
      where u.id = auth.uid() and u.rol = aprobaciones.rol
    )
  );

create policy "aprobaciones_update" on public.aprobaciones
  for update using (
    exists (
      select 1 from public.usuarios u
      where u.id = auth.uid() and u.rol = aprobaciones.rol
    )
  );

-- ============================================================
-- DATOS INICIALES: EPs de Iconstruye (quincena actual)
-- ============================================================

insert into public.eps (numero_ep, subcontratista, descripcion, obra, monto, monto_fmt, tipo, quincena) values
('067-90-1','Constructora Raul Tapia Fuentes E.I.R.L.','Impermeabilización Piso 1','067 - Stepke Temuco',12996000,'$12.996.000','Avance','Q1-2026-03'),
('068-71-10','Alfredo Carlos Lacoste Catalan','Testiguera','068 - Atelier Temuco',1178010,'$1.178.010','Retención','Q1-2026-03'),
('070-11-5','HCC Herramientas Spa','Arriendo Sonda','070 - Strip Center',700000,'$700.000','Avance','Q1-2026-03'),
('070-74-3','Cimientos R&S Spa','Instalación de Cerámicas y Porcelanatos','070 - Strip Center',0,'$0','Retención','Q1-2026-03'),
('070-78-5','Comercial y Transporte de Carga Transriquelme Spa','Arriendo Camión Pluma Riquelme','070 - Strip Center',400000,'$400.000','Avance','Q1-2026-03'),
('070-80-5','Inversiones y Transportes Tesco Spa','Retiro de Escombros','070 - Strip Center',1408000,'$1.408.000','Avance','Q1-2026-03'),
('070-93-1','JJS Rental Limitada','Elevador Eléctrico Tijera','070 - Strip Center',1160000,'$1.160.000','Avance','Q1-2026-03'),
('072-6-16','Climatización y Aire Acondicionado Andrea Carrasco E.I.R.L.','Clima e Inst. Aire Acondicionado','072 – Holiday Inn Vitacura',8640498,'$8.640.498','Avance','Q1-2026-03'),
('072-19-9','Pinturas Le Os Limitada','Pintor','072 – Holiday Inn Vitacura',18475608,'$18.475.608','Avance','Q1-2026-03'),
('072-22-13','Madera Pais Spa','Rev. Madera','072 – Holiday Inn Vitacura',7377832,'$7.377.832','Avance','Q1-2026-03'),
('072-28-3','Construcciones LD3 Spa','Retiro Escombros LD3','072 – Holiday Inn Vitacura',380000,'$380.000','Avance','Q1-2026-03'),
('072-31-4','Gleis Spa','Abastecimiento de agua Sauce','072 – Holiday Inn Vitacura',90000,'$90.000','Avance','Q1-2026-03'),
('074-8-2','Sociedad Jaque y Vera Limitada','Arriendo Grúa Horquilla','074 - Hotel Plaza El Bosque',695000,'$695.000','Avance','Q1-2026-03'),
('075-5-6','Ernesto Vilche Pena Construcciones Limitada','SC Sanitario','075 - Valle Nevado II',3292576,'$3.292.576','Avance','Q1-2026-03');

-- ============================================================
-- FUNCIÓN: crear perfil automáticamente al registrar usuario
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.usuarios (id, nombre, email, rol)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nombre', split_part(new.email,'@',1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'rol', 'Legal')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

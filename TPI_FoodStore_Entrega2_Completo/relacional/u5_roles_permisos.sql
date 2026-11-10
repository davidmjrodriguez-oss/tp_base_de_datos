-- Parte A: Diseño e implementación de roles y permisos
-- Creación de roles de grupo
CREATE ROLE rol_app_lectura;
CREATE ROLE rol_app_escritura;
CREATE ROLE rol_soporte;
CREATE ROLE rol_reportes;

-- Creación de roles de login
CREATE ROLE app_web WITH LOGIN PASSWORD 'AppWeb_FoodStore_2026';
CREATE ROLE admin_datos WITH LOGIN PASSWORD 'AdminDatos_FoodStore_2026';

-- Asignación de roles de grupo a roles de login
GRANT rol_app_lectura, rol_app_escritura TO app_web;
GRANT rol_soporte, rol_reportes TO admin_datos;

-- Permisos básicos (Principio de mínimo privilegio sobre Food Store)
GRANT USAGE ON SCHEMA public TO rol_app_lectura;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_app_lectura;

GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rol_app_escritura;

-- Permiso a nivel de columna (ej. ocultar email de usuarios al rol reportes)
GRANT SELECT (id, rol, fecha_alta) ON usuario TO rol_reportes;

-- Alter default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rol_app_lectura;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT INSERT, UPDATE, DELETE ON TABLES TO rol_app_escritura;

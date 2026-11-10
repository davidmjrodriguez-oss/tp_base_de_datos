-- Parte C: Laboratorio: simulacro de incidente de acceso indebido
-- Múltiples intentos fallidos de inicio de sesión
SELECT fn_autenticar('admin_datos', 'clave123');
SELECT fn_autenticar('admin_datos', 'admin');
SELECT fn_autenticar('admin_datos', 'password');

-- Inicio de sesión exitoso
SELECT fn_autenticar('admin_datos', 'AdminDatos_FoodStore_2026');

-- Lectura masiva de la tabla sensible
SELECT * FROM usuario;

-- Intento de escalamiento de privilegios desde un rol bajo
SET ROLE app_web;
GRANT admin_datos TO app_web; -- Esto arrojará ERROR por falta de privilegios

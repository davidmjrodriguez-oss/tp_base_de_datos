-- Parte B: Activación y prueba de la auditoría
-- Operación de lectura
SELECT * FROM usuario LIMIT 5;

-- Operación de inserción
INSERT INTO usuario (nombre, email, rol, fecha_alta) VALUES ('Usuario Prueba', 'prueba@foodstore.com', 'Cliente', CURRENT_DATE);

-- Operación de actualización
UPDATE usuario SET nombre = 'Usuario Prueba Modificado' WHERE email = 'prueba@foodstore.com';

-- Simulación de inicio de sesión fallido (Se ejecutaría desde consola: psql -U app_web -d food_store -W)

-- Parte D: Protección de datos personales: anonimización
CREATE TABLE usuario_anon AS
SELECT
    id,
    'Usuario_' || id AS nombre,
    'user_' || id || '@anon-foodstore.com' AS email,
    rol,
    fecha_alta
FROM usuario;

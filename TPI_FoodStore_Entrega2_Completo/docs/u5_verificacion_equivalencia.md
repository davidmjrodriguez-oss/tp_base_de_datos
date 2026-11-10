# Verificación de Equivalencia de Datos

**Consulta de Agregación Solicitada:**
`Proporciona una consulta SQL para agrupar y contar la cantidad de usuarios por rol utilizando la tabla usuario_anon, y su contraparte para la tabla real usuario.`

**Consultas Ejecutadas:**
```sql
-- Ejecución sobre la tabla real
SELECT rol, count(*) AS cantidad FROM usuario GROUP BY rol;

-- Ejecución sobre la tabla anonimizada
SELECT rol, count(*) AS cantidad FROM usuario_anon GROUP BY rol;
```

**Resultado de la Equivalencia:**
Ambas consultas arrojan idénticos conteos y agrupamientos para cada uno de los roles. Esto demuestra que la anonimización de la tabla protege las identidades individuales sin romper la utilidad estadística de la base.

**Restricción de Datos Hacia IA:**
Nunca se debe enviar a la IA el volcado de las tablas transaccionales en texto plano que contenga emails reales, nombres de clientes o identificadores personales directos de la base Food Store sin aplicar el proceso de anonimización previo, a fin de evitar incidentes de exposición en servicios de terceros.

# Informe de Incidente de Seguridad

**Contraste (Reconstrucción IA vs Realidad Ejecutada):**
La IA logró identificar correctamente el ataque de fuerza bruta contra la función de autenticación, el acceso exitoso y la exfiltración (lectura masiva) de la tabla de usuarios. Sin embargo, la IA omitió señalar que el intento final de escalamiento de privilegios falló rotundamente. La IA asumió que el atacante logró escalar privilegios al rol administrador, lo cual contradice el `ERROR` registrado explícitamente en el log debido a nuestro diseño de permisos.

**Decisión de Contención del Equipo:**
Ante la confirmación de la filtración de datos pero el fallo en el escalamiento de privilegios, se decide:
1. Bloquear a nivel de firewall la dirección IP origen del ataque de fuerza bruta.
2. Forzar el reseteo inmediato de la contraseña del rol `admin_datos`.
3. Informar a los usuarios afectados por la lectura masiva, ya que se comprometió su privacidad, aunque la integridad de la base no fue alterada.

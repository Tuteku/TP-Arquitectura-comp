# sw/

Software de PC.

| Carpeta | Contenido |
|---|---|
| `ensamblador/` | Traduce `.asm` a `.hex` (una palabra de 32 bits por línea, para `$readmemh` y para la carga por UART) |
| `modelo/` | Modelo de referencia: ejecuta el mismo programa en Python y genera el estado final esperado |
| `interfaz/` | Interfaz con la Debug Unit (protocolo en [docs/protocolo.md](../docs/protocolo.md)) |
| `programas/` | Programas de prueba en ensamblador |

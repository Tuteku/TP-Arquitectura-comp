# rtl/

Código Verilog sintetizable.

| Carpeta | Módulos |
|---|---|
| `core/` | Procesador: etapas del pipeline, banco de registros, ALU, generador de inmediatos, control, forwarding, detección de riesgos, memorias |
| `debug/` | Debug Unit |
| `uart/` | Generador de baudios, receptor, transmisor e interfaz buffer + flag del TP2 |
| `top/` | Módulo tope que conecta UART, Debug Unit y procesador con los pines de la placa |

La jerarquía completa está en [docs/arquitectura.md](../docs/arquitectura.md).

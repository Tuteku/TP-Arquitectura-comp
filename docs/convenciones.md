# Convenciones del proyecto

Issue: #1

Este documento fija cómo se organiza el repositorio y cómo se escribe el código, para que los dos trabajemos igual desde el primer módulo. Las convenciones de Verilog salen de lo que ya veníamos usando en el TP1 y el TP2.

## Estructura del repositorio

```
TP-Arquitectura-comp/
├── rtl/                 Código Verilog sintetizable
│   ├── core/            Procesador: etapas, banco de registros, ALU, control, memorias
│   ├── debug/           Debug Unit
│   ├── uart/            UART del TP2 (baud rate, rx, tx, interfaz buffer + flag)
│   └── top/             Módulo tope que conecta todo con la placa
├── tb/                  Test benches, uno por módulo (tb_<módulo>.v)
├── sw/                  Software de PC
│   ├── ensamblador/     Traduce .asm a .hex
│   ├── modelo/          Modelo de referencia (simulador del ISA en Python)
│   ├── interfaz/        CLI/TUI/GUI que habla con la Debug Unit
│   └── programas/       Programas de prueba en ensamblador (.asm)
├── constraints/         Archivos .xdc de la Basys3
├── scripts/             Scripts de Vivado (.tcl) y de simulación
├── docs/                Documentación de diseño
│   └── diagramas/       Diagramas en SVG
└── tps_anteriores/      TP1 y TP2 tal como se entregaron
```

El proyecto de Vivado no se sube. Cada uno lo arma en `vivado/` (ignorada por git) agregando las fuentes de `rtl/`, `tb/` y `constraints/` sin copiarlas ("Add sources", desmarcando "Copy sources into project"). Así el repositorio tiene una sola copia de cada archivo y no hay conflictos con los archivos generados. Más adelante, en `scripts/`, va un `.tcl` que recrea el proyecto.

La ALU y la UART de los TP anteriores se copian a `rtl/` cuando arranque M1. `tps_anteriores/` no se modifica.

## Verilog

### Archivos y módulos

- Un módulo por archivo, con el mismo nombre: `alu.v` contiene `module alu`.
- Nombres en minúscula con guiones bajos: `register_file`, `forwarding_unit`.
- Test bench: `tb_<módulo>.v`, en `tb/`.
- Verilog 2001 (`wire`/`reg`, `always @(*)`, `always @(posedge i_clk)`).
- Cada archivo arranca con `` `timescale 1ns / 1ps `` y un comentario corto con qué hace el módulo. El encabezado vacío que genera Vivado se borra.

### Puertos y señales

| Elemento | Convención | Ejemplo |
|---|---|---|
| Entradas | prefijo `i_` | `i_rs1_addr` |
| Salidas | prefijo `o_` | `o_alu_result` |
| Reloj | `i_clk` | |
| Reset | `i_reset`, síncrono, activo en alto | |
| Habilitación global | `i_enable` | |
| Registro de una FSM | sufijo `_reg` y `_next` | `state_reg`, `state_next` |
| Campos de un latch | prefijo con el nombre del latch | `ifid_pc`, `idex_rs1_data`, `exmem_alu_result`, `memwb_rd` |
| Señales activas en bajo | sufijo `_n` (evitarlas si se puede) | `rst_n` |

### Parámetros

- Parámetros en mayúsculas. Anchos con prefijo `NB_` (number of bits): `NB_DATA`, `NB_ADDR`, `NB_REG`.
- Constantes internas con `localparam`, también en mayúsculas: `OP_RTYPE`, `ALU_ADD`.
- Los códigos de opcode, funct3 y operación de la ALU se definen una sola vez en `rtl/core/riscv_defs.vh` y se incluyen donde hagan falta, en lugar de repetir números mágicos.

### Estilo

- Lógica combinacional en `always @(*)` con valores por defecto al principio del bloque para no inferir latches (como en las FSM del TP2).
- Lógica secuencial en `always @(posedge i_clk)` solo con asignaciones no bloqueantes (`<=`).
- Reset síncrono con prioridad sobre todo lo demás.
- FSM con dos bloques: uno secuencial con los registros y uno combinacional que calcula el estado siguiente.
- Indentación de 4 espacios, sin tabs.

### Test benches

- Autoverificables: comparan contra un valor esperado y cuentan errores, como `tb_alu` del TP1. Terminan imprimiendo `TEST PASSED` o `TEST FAILED`.
- Las entradas se cambian en el flanco negativo y las salidas se leen después del flanco positivo, para no depender del orden de evaluación del simulador.
- El detalle está en [verificacion.md](verificacion.md).

## Software (Python)

- Python 3, nombres en `snake_case`, un módulo por responsabilidad.
- Dependencias en `sw/requirements.txt`.
- Los programas de prueba van en `sw/programas/<nombre>.asm`. El `.hex` se genera con el ensamblador y no se sube.

## Flujo de trabajo en git

### Ramas

- `main` tiene siempre algo que simula sin errores. No se hacen commits directos.
- Una rama por issue o por grupo chico de issues relacionadas:

| Tipo | Uso | Ejemplo |
|---|---|---|
| `feat/` | Módulo o funcionalidad nueva | `feat/12-banco-registros` |
| `fix/` | Corrección | `fix/25-forwarding-x0` |
| `docs/` | Documentación | `docs/m0-diseno` |
| `test/` | Solo test benches o programas de prueba | `test/30-programas-riesgos` |

### Commits

Formato `tipo(ámbito): descripción en minúscula`, en presente. El cuerpo explica el porqué si no es obvio, y la última línea referencia la issue.

```
feat(core): banco de registros con bypass de escritura

La lectura devuelve el dato que se está escribiendo cuando las
direcciones coinciden, así WB e ID pueden usar el mismo registro
en el mismo ciclo.

Refs #12
```

### Pull Requests

- Todo entra a `main` por PR.
- El PR lo revisa el otro integrante antes del merge.
- La descripción dice qué cambia y cómo se probó, y usa `Closes #n` para cerrar las issues.
- Merge con "Squash and merge" para ramas de un solo tema; "Create a merge commit" cuando los commits por separado cuentan algo útil (como esta rama de documentación, que tiene un commit por issue).

### Issues

- Cada issue pertenece a un milestone (M0 a M8) y tiene un responsable.
- Las tareas se marcan en la checklist de la issue a medida que se completan.
- Las dependencias se escriben en la issue ("Bloqueada por #5").

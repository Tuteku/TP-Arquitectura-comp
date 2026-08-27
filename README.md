# TP N° 1 — ALU
Arquitectura de Computadoras

## Estructura

```
src/            modulos de diseño (.v)   <- va a la FPGA
tb/             testbenches (.v)         <- solo simulacion
constraints/    archivo .xdc de pines
docs/           consigna, informes
create_project.tcl   reconstruye el proyecto de Vivado
```

La carpeta `vivado_project/` **no se sube**: la genera cada uno en su maquina.

---

## Primera vez (cada integrante, una sola vez)

```bash
git clone <url-del-repo>
cd <repo>
```

En Vivado: `Tools -> Run Tcl Script...` y elegir `create_project.tcl`.
(O en la Tcl Console: `cd C:/ruta/al/repo` y despues `source create_project.tcl`.)

Listo. El proyecto queda en `vivado_project/` con todos los archivos enlazados.

---

## Uso diario

```bash
git pull                         # SIEMPRE antes de empezar
# ... editar los .v (en Vivado o en cualquier editor) ...
git add .
git commit -m "alu: corrijo extension de signo en SRA"
git push
```

### Cuando el otro pushea cambios

| Que cambio el otro | Que tenes que hacer |
|---|---|
| **Contenido** de un archivo existente | `git pull` y listo. Vivado lee el archivo actualizado solo |
| **Agrego o borro** un archivo | `git pull` + volver a correr `create_project.tcl` |

Esto funciona porque los archivos estan **enlazados por referencia**, no copiados
adentro del proyecto. Ver la nota de abajo.

---

## IMPORTANTE: como agregar archivos nuevos en Vivado

Al usar `Add Sources`, **DESTILDAR** la opcion:

    [ ] Copy sources into project

Si queda tildada, Vivado copia el archivo adentro de `vivado_project/`
(que esta en el .gitignore) y tus cambios nunca llegan al repo.

Guardar los archivos nuevos directamente en `src/` o `tb/`.

---

## Simulacion rapida sin Vivado (opcional, recomendado)

Vivado tarda mucho en arrancar. Para iterar rapido:

```bash
iverilog -o sim tb/tb_alu.v src/alu.v && vvp sim
yosys -p "read_verilog src/alu.v; synth; stat"    # ver latches / conteo de celdas
```

Usar Vivado solo para la sintesis final, el analisis de tiempo y el bitstream.

---

## Acuerdos del equipo

- `git pull` antes de empezar y antes de pushear.
- Avisarse quien toca que modulo, para no editar el mismo archivo a la vez.
- No commitear codigo que no compila.
- Mensajes de commit que digan **que** se cambio, no "cambios".

#!/usr/bin/env python3
"""Terminal para la ALU por UART.

Sirve tanto para la simulacion (/tmp/ttyALU) como para la placa (/dev/ttyUSB1).
Manda A, B y OP (un byte cada uno) y espera el byte de resultado.

    python3 alu_term.py                    # simulacion
    python3 alu_term.py /dev/ttyUSB1       # Basys3
    python3 alu_term.py --test             # corre una bateria de pruebas
"""
import argparse
import sys

import serial

OPS = {
    "ADD": 0b100000,
    "SUB": 0b100010,
    "AND": 0b100100,
    "OR":  0b100101,
    "XOR": 0b100110,
    "SRA": 0b000011,
    "SRL": 0b000010,
    "NOR": 0b100111,
}


def reference(a, b, op):
    sa = a - 256 if a & 0x80 else a
    sh = b & 0x7
    return {
        "ADD": a + b,
        "SUB": a - b,
        "AND": a & b,
        "OR":  a | b,
        "XOR": a ^ b,
        "SRA": sa >> sh,
        "SRL": a >> sh,
        "NOR": ~(a | b),
    }[op] & 0xFF


def parse_num(s):
    return int(s, 0) & 0xFF   # acepta 10, 0x0a, 0b1010, -3


def query(port, a, b, op):
    port.reset_input_buffer()
    port.write(bytes([a, b, OPS[op]]))
    r = port.read(1)
    if not r:
        raise TimeoutError("sin respuesta del DUT")
    return r[0]


def show(a, b, op, r):
    s = r - 256 if r & 0x80 else r
    print(f"  {op} 0x{a:02x}, 0x{b:02x} -> 0x{r:02x}  ({r} / {s} con signo)")


def run_tests(port):
    cases = [(5, 3), (0x7F, 1), (0x80, 1), (0xF0, 0x0F), (0x81, 3), (0, 0xFF)]
    fails = 0
    for op in OPS:
        for a, b in cases:
            r = query(port, a, b, op)
            exp = reference(a, b, op)
            ok = r == exp
            fails += not ok
            print(f"{'OK ' if ok else 'ERR'} {op:3} 0x{a:02x} 0x{b:02x} -> 0x{r:02x}"
                  + ("" if ok else f" (esperado 0x{exp:02x})"))
    print(f"\n{len(OPS) * len(cases) - fails}/{len(OPS) * len(cases)} OK")
    return fails == 0


def interactive(port):
    print("Formato: <OP> <A> <B>   ej: ADD 5 3   SUB 0x10 -1   SRA 0x80 2")
    print("OPs:", " ".join(OPS), "  | 'q' para salir")
    while True:
        try:
            line = input("alu> ").split()
        except EOFError:
            break
        if not line:
            continue
        if line[0].lower() in ("q", "quit", "exit"):
            break
        try:
            op = line[0].upper()
            if op not in OPS or len(line) != 3:
                raise ValueError
            a, b = parse_num(line[1]), parse_num(line[2])
        except ValueError:
            print("  entrada invalida")
            continue
        try:
            show(a, b, op, query(port, a, b, op))
        except TimeoutError as e:
            print(" ", e)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("port", nargs="?", default="/tmp/ttyALU")
    ap.add_argument("-b", "--baud", type=int, default=19200)
    ap.add_argument("--test", action="store_true")
    args = ap.parse_args()

    with serial.Serial(args.port, args.baud, timeout=5) as port:
        if args.test:
            sys.exit(0 if run_tests(port) else 1)
        interactive(port)


if __name__ == "__main__":
    main()

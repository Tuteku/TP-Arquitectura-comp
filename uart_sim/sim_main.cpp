// Co-simulacion de top_level con un puerto serie virtual (PTY).
//
// El harness crea un pseudo-terminal y lo conecta a i_rx / o_tx del diseño:
//   - cada byte que una terminal escribe en el PTY se serializa en i_rx (8N1)
//   - cada trama que el diseño saca por o_tx se decodifica y se escribe en el PTY
// Asi se puede probar el top_level con screen/minicom/pyserial igual que la placa.

#include <verilated.h>
#include "Vtop_level.h"

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fcntl.h>
#include <poll.h>
#include <termios.h>
#include <unistd.h>

#ifndef CLK_FREQ
#define CLK_FREQ 100000000
#endif
#ifndef BAUD_RATE
#define BAUD_RATE 19200
#endif

// Mismo calculo que baud_rate_generator: M ciclos por tick, 16 ticks por bit
static const long CYC_PER_BIT = (CLK_FREQ / (BAUD_RATE * 16L)) * 16L;

static Vtop_level *dut;
static uint64_t cycle = 0;

static void tick() {
    dut->i_clk = 0;
    dut->eval();
    dut->i_clk = 1;
    dut->eval();
    cycle++;
}

static int open_pty(const char *link_path) {
    int master = posix_openpt(O_RDWR | O_NOCTTY);
    if (master < 0 || grantpt(master) < 0 || unlockpt(master) < 0) {
        perror("posix_openpt");
        exit(1);
    }
    const char *slave_name = ptsname(master);

    // Modo raw: sin eco, sin traducir CR/LF, bytes tal cual
    int slave = open(slave_name, O_RDWR | O_NOCTTY);
    struct termios t;
    tcgetattr(slave, &t);
    cfmakeraw(&t);
    tcsetattr(slave, TCSANOW, &t);
    // El slave queda abierto para que el master no devuelva EIO
    // cuando la terminal cliente se desconecta.

    fcntl(master, F_SETFL, O_NONBLOCK);

    unlink(link_path);
    if (symlink(slave_name, link_path) < 0)
        perror("symlink");

    printf("Puerto serie simulado: %s  (link: %s)\n", slave_name, link_path);
    printf("CLK_FREQ=%d  BAUD_RATE=%d  ciclos/bit=%ld\n", CLK_FREQ, BAUD_RATE, CYC_PER_BIT);
    printf("Ctrl+C para terminar.\n");
    fflush(stdout);
    return master;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    const char *link_path = argc > 1 && argv[1][0] != '+' ? argv[1] : "/tmp/ttyALU";

    dut = new Vtop_level;
    int pty = open_pty(link_path);

    // Reset
    dut->i_rx = 1;
    dut->i_reset = 1;
    for (int i = 0; i < 10; i++) tick();
    dut->i_reset = 0;

    std::deque<uint8_t> to_dut;   // bytes pendientes de mandar por i_rx

    // Transmisor host -> DUT
    bool tx_busy = false;
    uint16_t tx_frame = 0;        // start + 8 datos + stop, LSB primero
    int tx_bit = 0;
    long tx_cnt = 0;

    // Receptor DUT -> host
    bool rx_busy = false;
    uint8_t rx_byte = 0;
    int rx_bit = 0;
    long rx_cnt = 0;

    for (;;) {
        // Si no hay nada en vuelo, bloquear esperando datos de la terminal
        // en lugar de quemar CPU simulando ciclos en vacio.
        bool idle = !tx_busy && !rx_busy && to_dut.empty() && dut->o_tx;
        if (idle) {
            struct pollfd p = {pty, POLLIN, 0};
            poll(&p, 1, 50);
        }

        uint8_t buf[64];
        ssize_t n = read(pty, buf, sizeof buf);
        for (ssize_t i = 0; i < n; i++) to_dut.push_back(buf[i]);

        // ---- host -> DUT ----
        if (!tx_busy && !to_dut.empty()) {
            uint8_t b = to_dut.front();
            to_dut.pop_front();
            tx_frame = (1u << 9) | (uint16_t(b) << 1);   // stop=1, start=0
            tx_bit = 0;
            tx_cnt = 0;
            tx_busy = true;
            printf("[%10.3f ms] -> DUT 0x%02x\n", cycle * 1e3 / CLK_FREQ, b);
            fflush(stdout);
        }
        if (tx_busy) {
            dut->i_rx = (tx_frame >> tx_bit) & 1;
            if (++tx_cnt == CYC_PER_BIT) {
                tx_cnt = 0;
                if (++tx_bit == 10) {
                    tx_busy = false;
                    dut->i_rx = 1;
                }
            }
        }

        tick();

        // ---- DUT -> host ----
        if (!rx_busy) {
            if (!dut->o_tx) {           // flanco de start
                rx_busy = true;
                rx_bit = -1;            // -1 = bit de start
                rx_cnt = 0;
                rx_byte = 0;
            }
        } else if (++rx_cnt == (rx_bit < 0 ? CYC_PER_BIT / 2 : CYC_PER_BIT)) {
            // Muestrea al medio de cada bit
            rx_cnt = 0;
            if (rx_bit < 0) {
                if (dut->o_tx) rx_busy = false;   // glitch, no era start
                else rx_bit = 0;
            } else if (rx_bit < 8) {
                rx_byte |= uint8_t(dut->o_tx) << rx_bit;
                rx_bit++;
            } else {
                if (!dut->o_tx)
                    printf("  (error de framing: stop bit en 0)\n");
                printf("[%10.3f ms] <- DUT 0x%02x\n", cycle * 1e3 / CLK_FREQ, rx_byte);
                fflush(stdout);
                if (write(pty, &rx_byte, 1) < 0 && errno != EAGAIN)
                    perror("write pty");
                rx_busy = false;
            }
        }
    }
}

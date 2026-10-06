// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop_level.h for the primary calling header

#ifndef VERILATED_VTOP_LEVEL___024ROOT_H_
#define VERILATED_VTOP_LEVEL___024ROOT_H_  // guard

#include "verilated.h"


class Vtop_level__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop_level___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(i_clk,0,0);
    VL_IN8(i_rx,0,0);
    VL_IN8(i_reset,0,0);
    VL_OUT8(o_tx,0,0);
    CData/*1:0*/ top_level__DOT__u_uart_rx__DOT__state_reg;
    CData/*1:0*/ top_level__DOT__u_uart_rx__DOT__state_next;
    CData/*3:0*/ top_level__DOT__u_uart_rx__DOT__s_reg;
    CData/*3:0*/ top_level__DOT__u_uart_rx__DOT__s_next;
    CData/*2:0*/ top_level__DOT__u_uart_rx__DOT__n_reg;
    CData/*2:0*/ top_level__DOT__u_uart_rx__DOT__n_next;
    CData/*7:0*/ top_level__DOT__u_uart_rx__DOT__b_reg;
    CData/*7:0*/ top_level__DOT__u_uart_rx__DOT__b_next;
    CData/*1:0*/ top_level__DOT__u_uart_tx__DOT__state_reg;
    CData/*1:0*/ top_level__DOT__u_uart_tx__DOT__state_next;
    CData/*3:0*/ top_level__DOT__u_uart_tx__DOT__s_reg;
    CData/*3:0*/ top_level__DOT__u_uart_tx__DOT__s_next;
    CData/*2:0*/ top_level__DOT__u_uart_tx__DOT__n_reg;
    CData/*2:0*/ top_level__DOT__u_uart_tx__DOT__n_next;
    CData/*7:0*/ top_level__DOT__u_uart_tx__DOT__b_reg;
    CData/*7:0*/ top_level__DOT__u_uart_tx__DOT__b_next;
    CData/*0:0*/ top_level__DOT__u_uart_tx__DOT__o_tx_reg;
    CData/*0:0*/ top_level__DOT__u_uart_tx__DOT__o_tx_next;
    CData/*2:0*/ top_level__DOT__u_uart_interface__DOT__state_reg;
    CData/*2:0*/ top_level__DOT__u_uart_interface__DOT__state_next;
    CData/*7:0*/ top_level__DOT__u_uart_interface__DOT__reg_a;
    CData/*7:0*/ top_level__DOT__u_uart_interface__DOT__reg_b;
    CData/*7:0*/ top_level__DOT__u_uart_interface__DOT__reg_a_next;
    CData/*7:0*/ top_level__DOT__u_uart_interface__DOT__reg_b_next;
    CData/*5:0*/ top_level__DOT__u_uart_interface__DOT__reg_op;
    CData/*5:0*/ top_level__DOT__u_uart_interface__DOT__reg_op_next;
    CData/*7:0*/ top_level__DOT__u_uart_interface__DOT__data_tx;
    CData/*7:0*/ top_level__DOT__u_uart_interface__DOT__data_tx_next;
    CData/*0:0*/ top_level__DOT__u_uart_interface__DOT__tx_start;
    CData/*0:0*/ top_level__DOT__u_uart_interface__DOT__tx_start_next;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__i_clk__0;
    CData/*0:0*/ __VactContinue;
    SData/*8:0*/ top_level__DOT__u_baud_rate_generator__DOT__count;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop_level__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtop_level___024root(Vtop_level__Syms* symsp, const char* v__name);
    ~Vtop_level___024root();
    VL_UNCOPYABLE(Vtop_level___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard

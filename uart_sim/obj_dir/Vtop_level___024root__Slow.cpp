// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop_level.h for the primary calling header

#include "Vtop_level__pch.h"
#include "Vtop_level__Syms.h"
#include "Vtop_level___024root.h"

void Vtop_level___024root___ctor_var_reset(Vtop_level___024root* vlSelf);

Vtop_level___024root::Vtop_level___024root(Vtop_level__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtop_level___024root___ctor_var_reset(this);
}

void Vtop_level___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vtop_level___024root::~Vtop_level___024root() {
}

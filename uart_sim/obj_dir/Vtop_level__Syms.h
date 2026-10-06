// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTOP_LEVEL__SYMS_H_
#define VERILATED_VTOP_LEVEL__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtop_level.h"

// INCLUDE MODULE CLASSES
#include "Vtop_level___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vtop_level__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtop_level* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtop_level___024root           TOP;

    // CONSTRUCTORS
    Vtop_level__Syms(VerilatedContext* contextp, const char* namep, Vtop_level* modelp);
    ~Vtop_level__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard

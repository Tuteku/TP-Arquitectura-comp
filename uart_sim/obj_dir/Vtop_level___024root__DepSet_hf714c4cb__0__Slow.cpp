// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop_level.h for the primary calling header

#include "Vtop_level__pch.h"
#include "Vtop_level___024root.h"

VL_ATTR_COLD void Vtop_level___024root___eval_static(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vtop_level___024root___eval_initial(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vtrigprevexpr___TOP__i_clk__0 = vlSelf->i_clk;
}

VL_ATTR_COLD void Vtop_level___024root___eval_final(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__stl(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtop_level___024root___eval_phase__stl(Vtop_level___024root* vlSelf);

VL_ATTR_COLD void Vtop_level___024root___eval_settle(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vtop_level___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../ALU.srcs/sources_1/new/top_level.v", 23, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vtop_level___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__stl(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtop_level___024root___stl_sequent__TOP__0(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___stl_sequent__TOP__0\n"); );
    // Init
    CData/*7:0*/ top_level__DOT__w_data;
    top_level__DOT__w_data = 0;
    CData/*0:0*/ top_level__DOT__u_uart_rx__DOT__rx_done_tick;
    top_level__DOT__u_uart_rx__DOT__rx_done_tick = 0;
    CData/*0:0*/ top_level__DOT__u_uart_tx__DOT__tx_done_tick;
    top_level__DOT__u_uart_tx__DOT__tx_done_tick = 0;
    // Body
    vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start_next = 0U;
    vlSelf->o_tx = vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__s_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__n_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg;
    vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_reg;
    vlSelf->top_level__DOT__u_uart_tx__DOT__n_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg;
    vlSelf->top_level__DOT__u_uart_tx__DOT__s_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__b_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__state_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg;
    vlSelf->top_level__DOT__u_uart_tx__DOT__state_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg;
    vlSelf->top_level__DOT__u_uart_tx__DOT__b_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__b_reg;
    top_level__DOT__u_uart_tx__DOT__tx_done_tick = 0U;
    if ((2U & (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg))) {
        vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next 
            = ((1U & (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg)) 
               || (1U & (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__b_reg)));
        if ((1U & (~ (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg)))) {
            if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
                if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg))) {
                    if ((7U != (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg))) {
                        vlSelf->top_level__DOT__u_uart_tx__DOT__n_next 
                            = (7U & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg)));
                        vlSelf->top_level__DOT__u_uart_tx__DOT__b_next 
                            = (0x7fU & ((IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__b_reg) 
                                        >> 1U));
                    }
                }
            }
        }
        if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg))) {
            if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
                if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg))) {
                    vlSelf->top_level__DOT__u_uart_tx__DOT__s_next = 0U;
                    vlSelf->top_level__DOT__u_uart_tx__DOT__state_next = 0U;
                    top_level__DOT__u_uart_tx__DOT__tx_done_tick = 1U;
                } else {
                    vlSelf->top_level__DOT__u_uart_tx__DOT__s_next 
                        = (0xfU & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg)));
                }
            }
        } else if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
            if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg))) {
                vlSelf->top_level__DOT__u_uart_tx__DOT__s_next = 0U;
                if ((7U == (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg))) {
                    vlSelf->top_level__DOT__u_uart_tx__DOT__state_next = 3U;
                }
            } else {
                vlSelf->top_level__DOT__u_uart_tx__DOT__s_next 
                    = (0xfU & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg)));
            }
        }
    } else {
        if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg))) {
            vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next = 0U;
            if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
                if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg))) {
                    vlSelf->top_level__DOT__u_uart_tx__DOT__n_next = 0U;
                    vlSelf->top_level__DOT__u_uart_tx__DOT__s_next = 0U;
                    vlSelf->top_level__DOT__u_uart_tx__DOT__state_next = 2U;
                } else {
                    vlSelf->top_level__DOT__u_uart_tx__DOT__s_next 
                        = (0xfU & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg)));
                }
            }
        } else {
            vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next = 1U;
            if (vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start) {
                vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next = 0U;
                vlSelf->top_level__DOT__u_uart_tx__DOT__s_next = 0U;
                vlSelf->top_level__DOT__u_uart_tx__DOT__state_next = 1U;
            }
        }
        if ((1U & (~ (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg)))) {
            if (vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start) {
                vlSelf->top_level__DOT__u_uart_tx__DOT__b_next 
                    = vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx;
            }
        }
    }
    top_level__DOT__w_data = (0xffU & ((0x20U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                        ? ((0x10U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                            ? 0U : 
                                           ((8U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                             ? 0U : 
                                            ((4U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                              ? ((2U 
                                                  & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                                  ? 
                                                 ((1U 
                                                   & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                                   ? 
                                                  (~ 
                                                   ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a) 
                                                    | (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b)))
                                                   : 
                                                  ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a) 
                                                   ^ (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b)))
                                                  : 
                                                 ((1U 
                                                   & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                                   ? 
                                                  ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a) 
                                                   | (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b))
                                                   : 
                                                  ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a) 
                                                   & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b))))
                                              : ((2U 
                                                  & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                                  ? 
                                                 ((1U 
                                                   & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                                   ? 0U
                                                   : 
                                                  ((IData)(1U) 
                                                   + 
                                                   (VL_EXTENDS_II(8,8, (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a)) 
                                                    + 
                                                    (~ 
                                                     VL_EXTENDS_II(8,8, (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b))))))
                                                  : 
                                                 ((1U 
                                                   & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                                   ? 0U
                                                   : 
                                                  ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a) 
                                                   + (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b)))))))
                                        : ((0x10U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                            ? 0U : 
                                           ((8U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                             ? 0U : 
                                            ((4U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                              ? 0U : 
                                             ((2U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                               ? ((1U 
                                                   & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op))
                                                   ? 
                                                  VL_SHIFTRS_III(8,8,3, (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a), 
                                                                 (7U 
                                                                  & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b)))
                                                   : 
                                                  ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a) 
                                                   >> 
                                                   (7U 
                                                    & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b))))
                                               : 0U))))));
    top_level__DOT__u_uart_rx__DOT__rx_done_tick = 0U;
    if ((2U & (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg))) {
        if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg))) {
            if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
                if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg))) {
                    vlSelf->top_level__DOT__u_uart_rx__DOT__s_next = 0U;
                    vlSelf->top_level__DOT__u_uart_rx__DOT__state_next = 0U;
                    top_level__DOT__u_uart_rx__DOT__rx_done_tick = 1U;
                } else {
                    vlSelf->top_level__DOT__u_uart_rx__DOT__s_next 
                        = (0xfU & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg)));
                }
            }
        } else if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
            if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg))) {
                vlSelf->top_level__DOT__u_uart_rx__DOT__s_next = 0U;
                if ((7U == (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg))) {
                    vlSelf->top_level__DOT__u_uart_rx__DOT__state_next = 3U;
                }
            } else {
                vlSelf->top_level__DOT__u_uart_rx__DOT__s_next 
                    = (0xfU & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg)));
            }
        }
        if ((1U & (~ (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg)))) {
            if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
                if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg))) {
                    if ((7U != (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg))) {
                        vlSelf->top_level__DOT__u_uart_rx__DOT__n_next 
                            = (7U & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg)));
                    }
                    vlSelf->top_level__DOT__u_uart_rx__DOT__b_next 
                        = (((IData)(vlSelf->i_rx) << 7U) 
                           | (0x7fU & ((IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg) 
                                       >> 1U)));
                }
            }
        }
    } else if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg))) {
        if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
            if ((7U == (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg))) {
                vlSelf->top_level__DOT__u_uart_rx__DOT__s_next = 0U;
                vlSelf->top_level__DOT__u_uart_rx__DOT__n_next = 0U;
                vlSelf->top_level__DOT__u_uart_rx__DOT__state_next = 2U;
            } else {
                vlSelf->top_level__DOT__u_uart_rx__DOT__s_next 
                    = (0xfU & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg)));
            }
        }
    } else if ((1U & (~ (IData)(vlSelf->i_rx)))) {
        vlSelf->top_level__DOT__u_uart_rx__DOT__s_next = 0U;
        vlSelf->top_level__DOT__u_uart_rx__DOT__state_next = 1U;
    }
    vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx_next 
        = vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx;
    vlSelf->top_level__DOT__u_uart_interface__DOT__state_next 
        = vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg;
    if ((4U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
        if ((2U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
            vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = 0U;
        } else if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
            vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = 0U;
        } else if (top_level__DOT__u_uart_tx__DOT__tx_done_tick) {
            vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = 0U;
        }
    } else if ((2U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
        if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
            vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = 4U;
        } else if (top_level__DOT__u_uart_rx__DOT__rx_done_tick) {
            vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = 3U;
        }
    } else if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
        if (top_level__DOT__u_uart_rx__DOT__rx_done_tick) {
            vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = 2U;
        }
    } else if (top_level__DOT__u_uart_rx__DOT__rx_done_tick) {
        vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = 1U;
    }
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op_next 
        = vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op;
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b_next 
        = vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b;
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a_next 
        = vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a;
    if ((1U & (~ ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg) 
                  >> 2U)))) {
        if ((2U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
            if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
                vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start_next = 1U;
                vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx_next 
                    = top_level__DOT__w_data;
            }
            if ((1U & (~ (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg)))) {
                if (top_level__DOT__u_uart_rx__DOT__rx_done_tick) {
                    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op_next 
                        = (0x3fU & (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg));
                }
            }
        }
        if ((1U & (~ ((IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg) 
                      >> 1U)))) {
            if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg))) {
                if (top_level__DOT__u_uart_rx__DOT__rx_done_tick) {
                    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b_next 
                        = vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg;
                }
            }
            if ((1U & (~ (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg)))) {
                if (top_level__DOT__u_uart_rx__DOT__rx_done_tick) {
                    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a_next 
                        = vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg;
                }
            }
        }
    }
}

VL_ATTR_COLD void Vtop_level___024root___eval_stl(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vtop_level___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vtop_level___024root___eval_triggers__stl(Vtop_level___024root* vlSelf);

VL_ATTR_COLD bool Vtop_level___024root___eval_phase__stl(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtop_level___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vtop_level___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__ico(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VicoTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__act(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge i_clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__nba(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge i_clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtop_level___024root___ctor_var_reset(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->i_rx = VL_RAND_RESET_I(1);
    vlSelf->i_clk = VL_RAND_RESET_I(1);
    vlSelf->i_reset = VL_RAND_RESET_I(1);
    vlSelf->o_tx = VL_RAND_RESET_I(1);
    vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count = VL_RAND_RESET_I(9);
    vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg = VL_RAND_RESET_I(2);
    vlSelf->top_level__DOT__u_uart_rx__DOT__state_next = VL_RAND_RESET_I(2);
    vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg = VL_RAND_RESET_I(4);
    vlSelf->top_level__DOT__u_uart_rx__DOT__s_next = VL_RAND_RESET_I(4);
    vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg = VL_RAND_RESET_I(3);
    vlSelf->top_level__DOT__u_uart_rx__DOT__n_next = VL_RAND_RESET_I(3);
    vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_rx__DOT__b_next = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg = VL_RAND_RESET_I(2);
    vlSelf->top_level__DOT__u_uart_tx__DOT__state_next = VL_RAND_RESET_I(2);
    vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg = VL_RAND_RESET_I(4);
    vlSelf->top_level__DOT__u_uart_tx__DOT__s_next = VL_RAND_RESET_I(4);
    vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg = VL_RAND_RESET_I(3);
    vlSelf->top_level__DOT__u_uart_tx__DOT__n_next = VL_RAND_RESET_I(3);
    vlSelf->top_level__DOT__u_uart_tx__DOT__b_reg = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_tx__DOT__b_next = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_reg = VL_RAND_RESET_I(1);
    vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next = VL_RAND_RESET_I(1);
    vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg = VL_RAND_RESET_I(3);
    vlSelf->top_level__DOT__u_uart_interface__DOT__state_next = VL_RAND_RESET_I(3);
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a_next = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b_next = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op = VL_RAND_RESET_I(6);
    vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op_next = VL_RAND_RESET_I(6);
    vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx_next = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start = VL_RAND_RESET_I(1);
    vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start_next = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__i_clk__0 = VL_RAND_RESET_I(1);
}

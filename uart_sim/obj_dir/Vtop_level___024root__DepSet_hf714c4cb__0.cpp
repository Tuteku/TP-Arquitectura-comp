// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop_level.h for the primary calling header

#include "Vtop_level__pch.h"
#include "Vtop_level___024root.h"

VL_INLINE_OPT void Vtop_level___024root___ico_sequent__TOP__0(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___ico_sequent__TOP__0\n"); );
    // Body
    vlSelf->top_level__DOT__u_uart_rx__DOT__s_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__b_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__state_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg;
    if ((2U & (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg))) {
        if ((1U & (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg))) {
            if ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))) {
                if ((0xfU == (IData)(vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg))) {
                    vlSelf->top_level__DOT__u_uart_rx__DOT__s_next = 0U;
                    vlSelf->top_level__DOT__u_uart_rx__DOT__state_next = 0U;
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
}

void Vtop_level___024root___eval_ico(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_ico\n"); );
    // Body
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        Vtop_level___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void Vtop_level___024root___eval_triggers__ico(Vtop_level___024root* vlSelf);

bool Vtop_level___024root___eval_phase__ico(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__ico\n"); );
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vtop_level___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelf->__VicoTriggered.any();
    if (__VicoExecute) {
        Vtop_level___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vtop_level___024root___eval_act(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vtop_level___024root___nba_sequent__TOP__0(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*7:0*/ top_level__DOT__w_data;
    top_level__DOT__w_data = 0;
    CData/*0:0*/ top_level__DOT__u_uart_rx__DOT__rx_done_tick;
    top_level__DOT__u_uart_rx__DOT__rx_done_tick = 0;
    CData/*0:0*/ top_level__DOT__u_uart_tx__DOT__tx_done_tick;
    top_level__DOT__u_uart_tx__DOT__tx_done_tick = 0;
    // Body
    if (vlSelf->i_reset) {
        vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count = 0U;
        vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg = 0U;
        vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx = 0U;
        vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op = 0U;
        vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b = 0U;
        vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a = 0U;
        vlSelf->top_level__DOT__u_uart_tx__DOT__b_reg = 0U;
        vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg = 0U;
        vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg = 0U;
        vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg = 0U;
        vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg = 0U;
        vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg = 0U;
        vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg = 0U;
        vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg = 0U;
    } else {
        vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count 
            = ((0x144U == (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))
                ? 0U : (0x1ffU & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__u_baud_rate_generator__DOT__count))));
        vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg 
            = vlSelf->top_level__DOT__u_uart_rx__DOT__n_next;
        vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx 
            = vlSelf->top_level__DOT__u_uart_interface__DOT__data_tx_next;
        vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op 
            = vlSelf->top_level__DOT__u_uart_interface__DOT__reg_op_next;
        vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b 
            = vlSelf->top_level__DOT__u_uart_interface__DOT__reg_b_next;
        vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a 
            = vlSelf->top_level__DOT__u_uart_interface__DOT__reg_a_next;
        vlSelf->top_level__DOT__u_uart_tx__DOT__b_reg 
            = vlSelf->top_level__DOT__u_uart_tx__DOT__b_next;
        vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg 
            = vlSelf->top_level__DOT__u_uart_tx__DOT__n_next;
        vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg 
            = vlSelf->top_level__DOT__u_uart_rx__DOT__b_next;
        vlSelf->top_level__DOT__u_uart_interface__DOT__state_reg 
            = vlSelf->top_level__DOT__u_uart_interface__DOT__state_next;
        vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg 
            = vlSelf->top_level__DOT__u_uart_tx__DOT__s_next;
        vlSelf->top_level__DOT__u_uart_tx__DOT__state_reg 
            = vlSelf->top_level__DOT__u_uart_tx__DOT__state_next;
        vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg 
            = vlSelf->top_level__DOT__u_uart_rx__DOT__s_next;
        vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg 
            = vlSelf->top_level__DOT__u_uart_rx__DOT__state_next;
    }
    vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_reg 
        = ((IData)(vlSelf->i_reset) || (IData)(vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next));
    vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start 
        = ((1U & (~ (IData)(vlSelf->i_reset))) && (IData)(vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start_next));
    vlSelf->o_tx = vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_reg;
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
    vlSelf->top_level__DOT__u_uart_interface__DOT__tx_start_next = 0U;
    vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__o_tx_reg;
    vlSelf->top_level__DOT__u_uart_tx__DOT__n_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__n_reg;
    vlSelf->top_level__DOT__u_uart_tx__DOT__s_next 
        = vlSelf->top_level__DOT__u_uart_tx__DOT__s_reg;
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
    vlSelf->top_level__DOT__u_uart_rx__DOT__s_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__s_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__n_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__n_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__b_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__b_reg;
    vlSelf->top_level__DOT__u_uart_rx__DOT__state_next 
        = vlSelf->top_level__DOT__u_uart_rx__DOT__state_reg;
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

void Vtop_level___024root___eval_nba(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vtop_level___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vtop_level___024root___eval_triggers__act(Vtop_level___024root* vlSelf);

bool Vtop_level___024root___eval_phase__act(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtop_level___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vtop_level___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtop_level___024root___eval_phase__nba(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtop_level___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__ico(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__nba(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__act(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG

void Vtop_level___024root___eval(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelf->__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY((0x64U < __VicoIterCount))) {
#ifdef VL_DEBUG
            Vtop_level___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("../ALU.srcs/sources_1/new/top_level.v", 23, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vtop_level___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelf->__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vtop_level___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("../ALU.srcs/sources_1/new/top_level.v", 23, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vtop_level___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("../ALU.srcs/sources_1/new/top_level.v", 23, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vtop_level___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vtop_level___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtop_level___024root___eval_debug_assertions(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->i_rx & 0xfeU))) {
        Verilated::overWidthError("i_rx");}
    if (VL_UNLIKELY((vlSelf->i_clk & 0xfeU))) {
        Verilated::overWidthError("i_clk");}
    if (VL_UNLIKELY((vlSelf->i_reset & 0xfeU))) {
        Verilated::overWidthError("i_reset");}
}
#endif  // VL_DEBUG

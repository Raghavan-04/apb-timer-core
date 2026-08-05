// SystemVerilog Functional Coverage for APB Timer IP Core
`timescale 1ns/1ps

module timer_cov (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        timer_en,
  input  logic        oneshot_en,
  input  logic        pwm_en,
  input  logic [15:0] prescaler,
  input  logic [31:0] timer_val,
  input  logic [31:0] reload_val,
  input  logic [31:0] compare_val,
  input  logic [1:0]  irq_en,
  input  logic [1:0]  irq_stat,
  input  logic        pwm_out
);

  // ---------------------------------------------------------------------------
  // 1. Control & Prescaler Coverage (Gated by rst_n)
  // ---------------------------------------------------------------------------
  covergroup cg_ctrl @(posedge clk iff rst_n);
    option.per_instance = 1;

    cp_timer_en:   coverpoint timer_en;
    cp_oneshot_en: coverpoint oneshot_en;
    cp_pwm_en:     coverpoint pwm_en;

    cp_prescaler: coverpoint prescaler {
      bins zero       = {16'h0000};
      bins one        = {16'h0001};
      bins max        = {16'hFFFF};
      bins mid_range  = {[16'h0002 : 16'hFFFE]};
    }

    // Cross timer mode and prescaler classes
    cross_mode_prescale: cross cp_oneshot_en, cp_prescaler;
  endgroup

  // ---------------------------------------------------------------------------
  // 2. Reload, Compare, Counter & PWM Coverage (Gated by rst_n)
  // ---------------------------------------------------------------------------
  covergroup cg_timer_cfg @(posedge clk iff rst_n);
    option.per_instance = 1;

    cp_rel_cmp_rel: coverpoint (compare_val < reload_val) {
      bins compare_less_than_reload = {1'b1};
      bins compare_gte_reload       = {1'b0};
    }

    cp_rel_cmp_equal: coverpoint (compare_val == reload_val) {
      bins compare_equals_reload    = {1'b1};
    }

    // Counter value coverage
    cp_timer_val: coverpoint timer_val {
      bins zero    = {32'h0000_0000};
      bins max_val = {32'hFFFF_FFFF};
      bins mid_val = {[32'h0000_0001 : 32'hFFFF_FFFE]};
    }

    // PWM output activity & transitions
    cp_pwm_out: coverpoint pwm_out {
      bins low         = {1'b0};
      bins high        = {1'b1};
      bins low_to_high = (1'b0 => 1'b1);
      bins high_to_low = (1'b1 => 1'b0);
    }
  endgroup

  // ---------------------------------------------------------------------------
  // 3. Interrupt Events, Masking & Write-1-to-Clear (Gated by rst_n)
  // ---------------------------------------------------------------------------
  covergroup cg_irq @(posedge clk iff rst_n);
    option.per_instance = 1;

    // Bit 0: Overflow IRQ, Bit 1: Compare Match IRQ
    cp_irq_stat: coverpoint irq_stat {
      bins none_asserted    = {2'b00};
      bins overflow_pending = {2'b01};
      bins compare_pending  = {2'b10};
      bins both_pending     = {2'b11};
    }

    cp_irq_en: coverpoint irq_en {
      bins none_enabled     = {2'b00};
      bins overflow_enabled = {2'b01};
      bins compare_enabled  = {2'b10};
      bins both_enabled     = {2'b11};
    }

    // Write-1-to-Clear (W1C) transitions
    cp_overflow_w1c: coverpoint irq_stat[0] {
      bins overflow_cleared = (1'b1 => 1'b0);
    }

    cp_compare_w1c: coverpoint irq_stat[1] {
      bins compare_cleared = (1'b1 => 1'b0);
    }

    // Cross status against both mask bits
    cross_irq_mask: cross cp_irq_stat, cp_irq_en;
  endgroup

  // Instantiate covergroups
  cg_ctrl      cg_ctrl_inst      = new();
  cg_timer_cfg cg_timer_cfg_inst = new();
  cg_irq       cg_irq_inst       = new();

endmodule
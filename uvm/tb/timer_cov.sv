// SystemVerilog Functional Coverage for APB Timer IP Core
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
  // 1. Control & Prescaler Coverage
  // ---------------------------------------------------------------------------
  covergroup cg_ctrl @(posedge clk);
    option.per_instance = 1;

    cp_timer_en:   coverpoint timer_en;
    cp_oneshot_en: coverpoint oneshot_en;
    cp_pwm_en:     coverpoint pwm_en;

    cp_prescaler: coverpoint prescaler {
      bins zero     = {16'h0000};
      bins one      = {16'h0001};
      bins max      = {16'hFFFF};
      bins mid_range = {[16'h0002 : 16'hFFFE]};
    }

    // Cross timer mode and prescaler classes
    cross_mode_prescale: cross cp_oneshot_en, cp_prescaler;
  endgroup

  // ---------------------------------------------------------------------------
  // 2. Reload vs Compare Duty Cycle Relation
  // ---------------------------------------------------------------------------
  covergroup cg_timer_cfg @(posedge clk);
    option.per_instance = 1;

    cp_rel_cmp_rel: coverpoint (compare_val < reload_val) {
      bins compare_less_than_reload    = {1'b1};
      bins compare_gte_reload          = {1'b0};
    }

    cp_rel_cmp_equal: coverpoint (compare_val == reload_val) {
      bins compare_equals_reload       = {1'b1};
    }
  endgroup

  // ---------------------------------------------------------------------------
  // 3. Interrupt Events & Write-1-to-Clear Coverage
  // ---------------------------------------------------------------------------
  covergroup cg_irq @(posedge clk);
    option.per_instance = 1;

    cp_overflow_irq: coverpoint irq_stat[0] {
      bins overflow_triggered = {1'b1};
    }
    cp_compare_irq:  coverpoint irq_stat[1] {
      bins compare_triggered  = {1'b1};
    }

    cross_irq_mask: cross cp_overflow_irq, irq_en;
  endgroup

  // Instantiate covergroups
  cg_ctrl      cg_ctrl_inst      = new();
  cg_timer_cfg cg_timer_cfg_inst = new();
  cg_irq       cg_irq_inst       = new();

endmodule
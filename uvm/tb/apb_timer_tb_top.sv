module apb_timer_tb_top;
  import uvm_pkg::*;
  import apb_timer_uvm_pkg::*;

  logic pclk;
  logic presetn;

  // Clock generation (100MHz / 10ns period)
  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
  end

  // Reset generation
  initial begin
    presetn = 0;
    #20 presetn = 1;
  end

  // Interfaces
  apb_if   apb_vif   (pclk, presetn);
  timer_if timer_vif (pclk, presetn);

  // Bind Functional Coverage module to DUT wrapper
  bind apb_timer_wrapper timer_cov u_timer_cov (
    .clk         (clk),
    .rst_n       (rst_n),
    .timer_en    (ctrl_reg[0]),
    .oneshot_en  (ctrl_reg[1]),
    .pwm_en      (ctrl_reg[2]),
    .prescaler   (ctrl_reg[31:16]),
    .timer_val   (timer_val),
    .reload_val  (reload_reg),
    .compare_val (compare_reg),
    .irq_en      (irq_en_reg[1:0]),
    .irq_stat    (irq_stat_reg[1:0]),
    .pwm_out     (pwm_out)
  );

  // DUT instantiation
  apb_timer_wrapper #(
    .C_APB_DATA_WIDTH (32),
    .C_APB_ADDR_WIDTH (8)
  ) u_dut (
    .i_timer_pclk    (pclk),
    .i_timer_presetn (presetn),

    .i_timer_paddr   (apb_vif.paddr),
    .i_timer_psel    (apb_vif.psel),
    .i_timer_penable (apb_vif.penable),
    .i_timer_pwrite  (apb_vif.pwrite),
    .i_timer_pwdata  (apb_vif.pwdata),
    .i_timer_pstrb   (apb_vif.pstrb),
    .o_timer_prdata  (apb_vif.prdata),
    .o_timer_pready  (apb_vif.pready),
    .o_timer_pslverr (apb_vif.pslverr),

    .o_timer_pwm     (timer_vif.o_timer_pwm),
    .o_timer_irq     (timer_vif.o_timer_irq)
  );

  // Pass virtual interfaces to UVM config DB & run test
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.m_apb_agent.*", "apb_vif", apb_vif);
    uvm_config_db#(virtual timer_if)::set(null, "uvm_test_top.env.m_timer_agent.*", "timer_vif", timer_vif);

    run_test();
  end
endmodule
`define SLAVE_ADD_WRITE 8'ha2
`define SLAVE_ADD_READ 8'ha3

module pcf8563(
  input wire mclk,
  input wire reset,
  inout wire scl,
  inout wire sda,

  input wire rtc_get,
  output wire[55:0] rtc,

  input wire rtc_set,
  input wire[55:0] rtc_in
);
//input mclk;
//input reset;
//inout scl,sda;
//output[7:0] led,seg,com;

reg clk;
//reg [7:0]led,seg,com;
reg scl_hi_z;
reg sda_hi_z;
reg scl_reg;
reg sda_reg;
reg[3:0] p_state;
reg[7:0] write_reg;
reg[7:0] read_reg;
reg[3:0] seg_reg;
reg[10:0] i;
reg[7:0] s_reg;
reg[7:0] m_reg;
reg[7:0] h_reg;
reg[7:0] d_reg;
reg[7:0] wd_reg;
reg[7:0] cm_reg;
reg[7:0] y_reg;

reg[3:0] cnt;
integer cnt2;
reg[15:0] cnt3;
reg[2:0] cnt4;

parameter prepare=0;
parameter idle=1;
parameter start=2;
parameter stop=3;
parameter write_data=4;
parameter wait_ack=5;
parameter error=6;
parameter read_data=7;
parameter ack=8;
parameter nack=9;


//assign rtc[55:0] = {s_reg,m_reg,h_reg,d_reg,wd_reg,cm_reg,y_reg};
assign rtc[55:0] = {s_reg,m_reg,h_reg,d_reg,rtc_set,reset,wd_reg[5:0],cnt3};

assign scl=scl_hi_z? 1'bz:1'b0;
assign sda=sda_hi_z? 1'bz:1'b0;

//div
always @(posedge mclk) begin
  //if (reset) begin
    cnt<=cnt+1;
    if (cnt==4'b1000) begin
      cnt<=0;
      clk<=~clk;
    end
  //end else cnt<=0;
end

always @(posedge mclk)
  sda_reg<=sda;

//reg rtc_set_a = 1'b0;
//reg rtc_set_b = 1'b0;
//reg rtc_set_prev = 1'b0;
//wire rtc_set_sig = rtc_set_a ^ rtc_set_b;
//always @(posedge mclk) begin
  //rtc_set_prev <= rtc_set;
  //if (!rtc_set_prev && rtc_set) begin
    //rtc_set_a <= ~rtc_set_a;
  //end
//end


always @(posedge clk) begin
  if (!reset) begin
    p_state<=prepare;
    cnt2<=0;
    cnt3<=rtc_set ? 16'd0 : 16'd10;
    cnt4<=0;
    write_reg<=0;
    //led<=8'h00;
    s_reg<=8'h00;
    m_reg<=8'h00;
    h_reg<=8'h00;
    d_reg<=8'h00;
    wd_reg<=8'h00;
    cm_reg<=8'h00;
    y_reg<=8'h00;
  end else begin
    case(p_state)
      prepare:
        begin
          scl_hi_z<=1;
          sda_hi_z<=1;
          cnt2<=cnt2+1;
          if(cnt2==10) begin
            cnt2<=0;
            p_state<=idle;
          end else p_state<=prepare;
        end

      idle:
        begin
          cnt3<=cnt3+1;
          case (cnt3)
            //16'd0:if (rtc_set) p_state<=start;
            //16'd1:if (rtc_set) begin p_state<=write_data;write_reg<=`SLAVE_ADD_WRITE ; end
            //16'd2:if (rtc_set) begin p_state<=write_data;write_reg<=8'h02 ; end
            //16'd3:if (rtc_set) begin p_state<=write_data;write_reg<=8'h00 ; end  //s set
            //16'd4:if (rtc_set) begin p_state<=write_data;write_reg<=8'h59; end  //m set
            //16'd5:if (rtc_set) begin p_state<=write_data;write_reg<=8'h23 ; end  //h set
            //16'd6:if (rtc_set) begin p_state<=write_data;write_reg<=8'h03 ; end  //d set
            //16'd7:if (rtc_set) begin p_state<=write_data;write_reg<=8'h06 ; end  //week
            //16'd8:if (rtc_set) begin p_state<=write_data;write_reg<=8'h01 ; end  //month
            //16'd9:if (rtc_set) begin p_state<=write_data;write_reg<=8'h10 ; end  //year
            16'd0:p_state<=start;
            16'd1:begin p_state<=write_data;write_reg<=`SLAVE_ADD_WRITE ; end
            16'd2:begin p_state<=write_data;write_reg<=8'h02 ; end
            16'd3:begin p_state<=write_data;write_reg<=8'h00 ; end  //s set
            16'd4:begin p_state<=write_data;write_reg<=8'h59; end  //m set
            16'd5:begin p_state<=write_data;write_reg<=8'h23 ; end  //h set
            16'd6:begin p_state<=write_data;write_reg<=8'h03 ; end  //d set
            16'd7:begin p_state<=write_data;write_reg<=8'h06 ; end  //week
            16'd8:begin p_state<=write_data;write_reg<=8'h01 ; end  //month
            16'd9:begin p_state<=write_data;write_reg<=8'h10 ; end  //year
            16'd10:p_state<=start;
            16'd11:begin p_state<=write_data;write_reg<=`SLAVE_ADD_WRITE ; end
            16'd12:begin p_state<=write_data;write_reg<=8'h02 ; end
            16'd13:p_state<=start;
            16'd14:begin p_state<=write_data;write_reg<=`SLAVE_ADD_READ ; end
            16'd15:p_state<=read_data;
            16'd16:p_state<=ack;
            16'd17:begin p_state<=read_data; s_reg<=read_reg; end
            16'd18:p_state<=ack;
            16'd19:begin p_state<=read_data; m_reg<=read_reg; end
            16'd20:p_state<=ack;
            16'd21:begin p_state<=read_data; h_reg<=read_reg; end

            //16'd22:p_state<=nack;
            //16'd23:begin p_state<=stop;   d_reg<=read_reg; end
            //16'd24:begin   cnt3<=10; end

            16'd22:p_state<=ack;
            16'd23:begin p_state<=read_data; d_reg<=read_reg; end
            16'd24:p_state<=ack;
            16'd25:begin p_state<=read_data; wd_reg<=read_reg; end
            16'd26:p_state<=ack;
            16'd27:begin p_state<=read_data; cm_reg<=read_reg; end
            16'd28:p_state<=nack;
            16'd29:begin p_state<=stop; y_reg<=read_reg; end
            16'd30:begin cnt3<=10; end





            //16'd0:begin p_state<=start; end
            //16'd1:begin p_state<=write_data;write_reg<=`SLAVE_ADD_WRITE ; end
            //16'd2:begin p_state<=write_data;write_reg<=8'h02 ; end
            //16'd3:p_state<=start;
            //16'd4:begin p_state<=write_data;write_reg<=`SLAVE_ADD_READ ; end
            //16'd5:p_state<=read_data;
            //16'd6:p_state<=ack;
            //16'd7:begin p_state<=read_data; s_reg<=read_reg; end
            //16'd8:p_state<=ack;
            //16'd9:begin p_state<=read_data; m_reg<=read_reg; end
            //16'd10:p_state<=ack;
            //16'd11:begin p_state<=read_data; h_reg<=read_reg; end
            //16'd12:p_state<=ack;
            //16'd13:begin p_state<=read_data; d_reg<=read_reg; end
            //16'd14:p_state<=ack;
            //16'd15:begin p_state<=read_data; wd_reg<=read_reg; end
            //16'd16:p_state<=ack;
            //16'd17:begin p_state<=read_data; cm_reg<=read_reg; end
            //16'd18:p_state<=nack;
            //16'd19:begin p_state<=stop; y_reg<=read_reg; end
            //16'd20:begin   cnt3<=0; end

            //16'd30:p_state<=start;
            //16'd31:begin p_state<=write_data;write_reg<=`SLAVE_ADD_WRITE ; end
            //16'd32:begin p_state<=write_data;write_reg<=8'h02 ; end
            //16'd33:begin p_state<=write_data;write_reg<=8'h00 ; end  //s set
            //16'd34:begin p_state<=write_data;write_reg<=8'h59; end  //m set
            //16'd35:begin p_state<=write_data;write_reg<=8'h23 ; end  //h set
            //16'd36:begin p_state<=write_data;write_reg<=8'h03 ; end  //d set
            //16'd37:begin p_state<=write_data;write_reg<=8'h06 ; end  //week
            //16'd38:begin p_state<=write_data;write_reg<=8'h01 ; end  //month
            //16'd39:begin p_state<=write_data;write_reg<=8'h10 ; end  //year
            //16'd40:begin p_state<=start; cnt3<=0; end

          endcase
        end

      start:
        begin
          cnt2<=cnt2+1;
          case (cnt2)
          0:begin scl_hi_z<=1;
                  sda_hi_z<=1;
                  end
          1:begin scl_hi_z<=1;
                  sda_hi_z<=0;
                  end
          2:begin scl_hi_z<=0;
                  sda_hi_z<=0;
                  end

          4:begin cnt2<=0;
                  p_state<=idle;
                  end
          //default:cnt2<=0;
          endcase
        end

      stop:
        begin
          cnt2<=cnt2+1;
          case (cnt2)
            1: sda_hi_z<=0;
            2: scl_hi_z<=1;
            3: sda_hi_z<=1;
            4: begin
              cnt2<=0;
                p_state<=idle;
                end
          endcase
        end


      write_data:
        begin
          cnt2<=cnt2+1;
          case (cnt2)
            1: sda_hi_z<=write_reg[7-cnt4];
            2: scl_hi_z<=1;
            4: scl_hi_z<=0;
            5: begin
              cnt2<=0;
              cnt4<=cnt4+1;
              if (cnt4==3'd7)
              p_state<=wait_ack;
              //cnt4<=0;
              else
              p_state<=write_data;
              end
          endcase

        end


      wait_ack:
        begin
          cnt2<=cnt2+1;
          case (cnt2)
            0:sda_hi_z<=1;
            1:scl_hi_z<=1;
            4:begin
                if (!sda_reg) begin
                  scl_hi_z<=0;
                  p_state<=idle;
                  cnt2<=0;
                end else begin
                  p_state<=error;
                  cnt2<=0;
                  //led<=8'h0e;
                end
              end
          endcase
        end

      error:
        begin
          p_state<=error;
        end

      read_data:
        begin
          cnt2<=cnt2+1;
          case (cnt2)

          0: sda_hi_z<=1;
          1: scl_hi_z<=1;
          2: read_reg[7-cnt4]<=sda_reg;
          3: scl_hi_z<=0;
          4: begin
            cnt2<=0;
            cnt4<=cnt4+1;
            if (cnt4==3'd7)
            p_state<=idle;
            else
            p_state<=read_data;
            end
          endcase
        end


      ack:
        begin
          cnt2<=cnt2+1;
          case (cnt2)
            0:sda_hi_z<=0;
            1:scl_hi_z<=1;

            4:begin
            cnt2<=0;
            p_state<=idle;
            scl_hi_z<=0;
            end
          endcase
        end

      nack:
        begin
          cnt2<=cnt2+1;
          case (cnt2)

          0:sda_hi_z<=1;
          1:scl_hi_z<=1;

          4:begin
            cnt2<=0;
            p_state<=idle;
            scl_hi_z<=0;
            end

          endcase
        end



      default p_state<='bx;
    endcase
  end
end

endmodule

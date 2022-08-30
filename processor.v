`timescale 1ns / 1ps
 
 
module top();
 
reg [15:0] GPR [32:0]; ////32 Register are user accessible , R[32] -- mul
reg [31:0] IR; 
reg [31:0] temp;
 
`define opcode IR[31:27]
`define rdst IR[26:22]
`define src1 IR[21:17]
`define imm_sel IR[16]
`define src2 IR[15:11]
/////////////////////////
 
 
 
//// opcode(5) reg_dst(5) src1_reg (5) sel_mode src2_reg(5)
/// rdst = rsrc1 + rsrc2;
/// rdst = rsrc1 + immediate_number
`define mov 5'b00000
`define add 5'b00001
`define sub 5'b00010
`define mul 5'b00011
 
//////////////////Logical Operations //////////////////
`define and 5'b00100
`define or 5'b00101
`define xor 5'b00110
`define nand 5'b00111
`define nor 5'b01000
`define xnor 5'b01001
`define not 5'b01010
 
 
////////////////////Load Store Direct addresing mode /////////
`define load  5'b01011  /////Load data into Register from BRAM
`define storeimm 5'b01100 ////Store immediate data into the BRAM
`define storereg 5'b01101 ////Store Reg data into the BRAM
 
///////////////////////////////////////////////////////////////
`define jump 5'b01110
`define imm_addr IR[15:0]
`define jump_sel IR[16:15]
 reg [15:0] lr;
 reg [15:0] PC = 0;
/////////////////////////////////////////////////////////////
 
`define bonc 5'b01111
`define bonz 5'b10000
`define bonn 5'b10001
`define bonv 5'b10010
 
`define bonnc 5'b10011
`define bonnz 5'b10100
`define bonnn 5'b10101
`define bonnv 5'b10110
 
reg [15:0] blr;
reg zero = 0;
reg sign = 0;
reg carry = 0;
reg overflow = 0;
integer count2 = 0;
 
/////////////////////////////////////////////
`define halt 5'b10111
 reg stop = 0;
 
/////////////////////////////////////////////
 
 
task execute();
begin
                                                                                                                                                                                                                                                                                                                                         
case(`opcode)
/////////Updating Register data
`mov : begin
if(`imm_sel == 1'b1)
GPR[`rdst] = IR[15:0];
else
GPR[`rdst] = GPR[`src1];
end
 
`add: begin
if(`imm_sel == 1'b1)
GPR[`rdst] = GPR[`src1] + IR[15:0 ];
else
GPR[`rdst] = GPR[`src1] + GPR[`src2];
conditionflag();
end
 
`sub: begin
if(`imm_sel == 1'b1)
GPR[`rdst] = GPR[`src1] - IR[15:0];
else
GPR[`rdst] = GPR[`src1] - GPR[`src2];
conditionflag();
end
 
`mul : begin
if(`imm_sel == 1'b1)
GPR[`rdst] = GPR[`src1] * IR[15:0];
else
temp = GPR[`src1] * GPR[`src2];
GPR[`rdst] =temp[15:0];
GPR[32] = temp[31:16];
conditionflag();
end
 
//////////////////////////////////////////
 
`and: begin
 if(`imm_sel == 1'b1)
 GPR[`rdst] = GPR[`src1] & IR[15:0];
 else
 GPR[`rdst] = GPR[`src1] & GPR[`src2];
end
 
`or: begin
 if(`imm_sel == 1'b1)
 GPR[`rdst] = GPR[`src1] | IR[15:0];
 else
 GPR[`rdst] = GPR[`src1] | GPR[`src2];
end
 
`xor: begin
 if(`imm_sel == 1'b1)
 GPR[`rdst] = GPR[`src1] ^ IR[15:0];
 else
 GPR[`rdst] = GPR[`src1] ^ GPR[`src2];
end
 
`nand: begin
 if(`imm_sel == 1'b1)
 GPR[`rdst] = ~(GPR[`src1] & IR[15:0]);
 else
 GPR[`rdst] = ~(GPR[`src1] & GPR[`src2]);
end
 
 
`nor: begin
 if(`imm_sel == 1'b1)
 GPR[`rdst] = ~(GPR[`src1] | IR[15:0]);
 else
 GPR[`rdst] = ~(GPR[`src1] | GPR[`src2]);
end
 
`xnor: begin
 if(`imm_sel == 1'b1)
 GPR[`rdst] = GPR[`src1] ~^ IR[15:0];
 else
 GPR[`rdst] = GPR[`src1] ~^ GPR[`src2];
end
 
 
`not:begin
 if(`imm_sel == 1'b1)
 GPR[`rdst] =  ~ (IR[15:0]);
 else
 GPR[`rdst] = ~(GPR[`src1]) ;
end
 
 
 
/////////////////////////////////////////////////////
 
`storeimm: begin
write_mem_imm();
end
 
`storereg: begin
write_mem_reg();
end
 
`load:begin
read_mem();
end
 
////////////////////////////////////////////////////
 
`jump:begin
lr = PC;
if(`imm_sel == 1'b1) begin
PC = `imm_addr;
end
end
 
/////////////////////////////////////////////////////
////////////////////////////////////////////////////
 
`bonc : begin
if(carry == 1'b1) begin
PC = `imm_addr;
end
else begin
blr = PC + 1;
end
end
 
`bonz : begin
if(zero == 1'b1) begin
PC = `imm_addr;
end 
else begin
blr = PC + 1 ;
end
end
 
`bonn : begin
if(sign == 1'b1) begin
PC = `imm_addr;
end
else begin
blr = PC + 1;
end
end
 
`bonv : begin
if(overflow == 1'b1) begin
PC = `imm_addr;
end
else begin
blr = PC + 1;
end
end
 
//////////////////////////////////////////
`bonnc : begin
if(carry == 1'b0) begin
PC = `imm_addr; 
end
else begin
blr = PC + 1;
end
end
 
`bonnz : begin
 
if(zero == 1'b0) begin
blr = `imm_addr;
end
else begin
blr = PC + 1;
end
end
 
`bonnn : begin
if(sign == 1'b0) begin
PC = `imm_addr;
end 
else begin
blr = PC + 1;
end
end
 
`bonnv : begin
if(overflow == 1'b0) begin
PC = `imm_addr;
end
else begin
blr = PC + 1;
end
end
 
 
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
`halt: begin
 stop = 1'b1;
 end
/////////////////////////////////////
 
endcase
end
endtask
////////////////////////////////////
reg [15:0] s1, s2;
reg [32:0] o;
reg clk = 0;
always@(posedge clk)
begin
if(PC == 0)begin
zero <= 0;
carry <= 0;
overflow <= 0;
sign <= 0;
s1 <= 0;
s2 <= 0;
o <= 0;
 
/////////////////////////////
stop <= 0;
 
end
end
////////////////////////////////
 
 
 
/////////////Condition flag Task
 
 
task conditionflag();
begin
 
if(`imm_sel == 1'b1) begin
s1 = GPR[`src1];
s2 = IR[15:0];
end
else begin
s1 = GPR[`src1];
s2 = GPR[`src2];
end
 
case(`opcode)
`add: o = s1 + s2;
`sub: o = s1 - s2;
`mul: o = s1 * s2;
default: o = 0;
endcase
 
zero = ~(|o[32:0]);
sign = (o[15] & ~IR[28] & IR[27] ) | (o[15] & IR[28] & ~IR[27]) | (o[31] & IR[28] & IR[27] );
carry = o[16] & ~IR[28] & IR[27];
overflow = ( ~s1[15] & ~s2[15] & o[15] & ~IR[28] & IR[27] ) |
           ( s1[15] & s2[15] & ~o[15] & ~IR[28] & IR[27] ) |
           ( ~s1[15] & s2[15] & o[15] & IR[28] & ~IR[27] ) |
           ( s1[15] & ~s2[15] & ~o[15] & IR[28] & ~IR[27] );
end
endtask
 
 
///////////////////////////////////////////////////
wire enh;
wire weh;
wire [10:0] addrh;
wire [15:0] douth;
wire [15:0] dinh;
wire clkn;
 
blk_mem_gen_1 uut1 (.clka(clkn),.ena(enh), .wea(weh),.addra(addrh), .dina(dinh),.douta(douth));
 
reg enp;
reg wep;
reg [10:0] addrp;
reg [15:0] doutp;
reg [15:0] dinp;
 
 
`define rdaddr IR[26:16]
`define rdreg IR[15:11]
`define wrreg IR[15:11]
`define input_data IR[15:0]
 
task read_mem();
begin
enp <= 1'b1;
wep <= 1'b0;
addrp <= `rdaddr;
GPR[`rdreg] <= douth;
end
endtask
 
task write_mem_imm();
begin
enp <= 1'b1;
wep <= 1'b1;
addrp <= `rdaddr;
dinp <= `input_data;
end
endtask
 
task write_mem_reg();
begin
enp <= 1'b1;
wep <= 1'b1;
addrp <= `rdaddr;
dinp <= GPR[`wrreg];
end
endtask
 
assign addrh = addrp;
assign enh = enp;
assign weh = wep;
assign dinh = dinp;
 
////////////////////////////////////////////////////
 
wire [15:0] addrn;
wire [31:0] doutn;
reg enrom;
blk_mem_gen_0 uut2 (.clka(clkn),.ena(enrom), .addra(addrn),.douta(doutn));
 
 
reg [2:0] state = 0;
//////////////////////////////
 
always #5 clk = ~clk;
 
integer count = 0;
 
always@(posedge clk)
begin
case(state)
0: begin
if(stop == 1'b1)
state <= 0;
else
state <= 1;
end
 
1:begin
IR <= doutn;
enrom <= 1'b1;
if(count <= 2) begin
count <= count + 1;
state <= 1;
end
else begin
count <= 0;
state <= 2;
end
end
 
 
2: begin
enrom <= 1'b0;
execute();
state <= 3;
end
 
3: begin
if(count <= 2) 
count <= count + 1;
else begin
count <= 0;
state <= 4;
end
end
 
 
 
4: begin 
state <= 5;
if(`opcode == 5'b01110) begin// | `opcode == 5'b10100) begin
PC <= `imm_addr;
end
else if (`opcode == 5'b10100)begin
PC <= blr;
end
else begin
PC <= PC + 1;
end
end
 
5: begin
if(count <= 2) 
count <= count + 1;
else begin
count <= 0;
state <= 0;
end
end
endcase
end
 
assign addrn = PC;
assign clkn =  clk;
 
 
//////////////////////////////////////////////////////
 
integer i;
initial begin
for(i = 0; i < 33; i= i + 1)
begin
GPR[i] = 0;
end
#10000;
$finish;
end
//////////////////////////////////////////////////
 
 
 
 
 
 
endmodule
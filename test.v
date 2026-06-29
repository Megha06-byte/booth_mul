module multiplier_seq (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [3:0] ip_A,
    input wire [3:0] ip_B,
    output reg [7:0] product,
    output reg done
);

//state definition
localparam IDLE = 3'b000,
           LOAD = 3'b001,
           CHECK = 3'b010,
           ADD = 3'b011,
           SUB = 3'b100,
           SHIFT = 3'b101,
           COUNT = 3'b110,
           DONE = 3'b111;

//Registers
reg [2:0] state, next_state;
reg signed [4:0] A; //-16 -> 15
reg signed [4:0] M; // -16 -> 15
reg [3:0] Q;
//reg signed [3:0] A,M,Q; //accumulated result, Mulitplicand, Multiplier,indicator
reg Q_1;
//reg C; //carry output
reg [2:0] counter;

//control signals (output)
reg load_en;
reg add_en;
reg sub_en;
reg shift_en;
reg counter_update;


//combinational output logic
always @(*) begin
    load_en = 0;
    add_en = 0;
    sub_en = 0;
    shift_en = 0;
    counter_update = 0;
    done = 0;
    case(state)
        LOAD : load_en = 1;
        ADD : begin
            add_en = 1;
        end
        SUB : begin
            sub_en = 1;
        end
        SHIFT :  begin
            shift_en = 1;
        end
        COUNT : begin
            counter_update = 1;
        end
        DONE : begin
            done = 1;
        end
    endcase
end
//next state logic
always @(*) begin
    next_state = state;
    case(state)
        IDLE : begin
            if(start) 
                next_state = LOAD;
        end
        LOAD : next_state = CHECK;
        CHECK : begin
            case({Q[0],Q_1})

                2'b00:
                    next_state = SHIFT;

                2'b11:
                    next_state = SHIFT;

                2'b01:
                    next_state = ADD;

                2'b10:
                    next_state = SUB;

            endcase
        end
        ADD : next_state = SHIFT;
        SUB : next_state = SHIFT;
        SHIFT : next_state = COUNT;
        COUNT : begin
            if (counter == 3'd3)
                next_state = DONE;
            else 
                next_state = CHECK;
        end
        DONE : begin 
                next_state = IDLE;
        end
    endcase
end

//datapath register UPDATE
always @(posedge clk) begin
    if(rst) begin
        A <= 0;
        M <= 0;
        Q <= 0;
        //C <= 0;
        product <= 0;
        counter <= 0;
    end else begin
        if(load_en) begin
            A <= 0;
            //M <= ip_A;
            M <= {ip_A[3], ip_A};
            Q <= ip_B;
            counter <= 0;
            //C <= 0;
            product <= 0;
            Q_1 <= 0;
        end
        else if(add_en) begin
            A <= A + M;
        end
        else if(sub_en) begin
            A <= A - M;
        end
        else if(shift_en) begin
            //{A,Q,Q_1} <= {A,Q,Q_1} >>> 1;
            Q_1 <= Q[0];
            Q   <= {A[0], Q[3:1]};
            A   <= {A[4], A[4:1]};
        end
        else if(counter_update) begin
            if(counter == 3'd3)
                //product <= {A,Q};
                product <= {A[3:0], Q};
            counter <= counter + 1;
        end

        else begin
        end
    end
end

//register UPDATE
always @(posedge clk) begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end

endmodule



module seq_multiplier #(
    parameter WIDTH = 8
)(
    input  wire                        clk,
    input  wire                        rst,
    input  wire                        start,
    input  wire signed [WIDTH-1:0]     ip_A,
    input  wire signed [WIDTH-1:0]     ip_B,

    output reg  signed [2*WIDTH-1:0]   product,
    output reg                         done
);

//stage encoding

localparam IDLE  = 3'd0,
           LOAD  = 3'd1,
           CHECK = 3'd2,
           ADD   = 3'd3,
           SHIFT = 3'd4,
           COUNT = 3'd5,
           DONE  = 3'd6;

reg [2:0] state, next_state;

// Datapath Registers

reg sign;

reg [WIDTH:0] A;
reg [WIDTH:0] M;
reg [WIDTH-1:0] Q;
reg C;

localparam COUNT_W = $clog2(WIDTH);
reg [COUNT_W:0] counter;

// Control Signals

reg load_en;
reg add_en;
reg shift_en;
reg count_en;

// Output Logic

always @(*) begin

    load_en  = 1'b0;
    add_en   = 1'b0;
    shift_en = 1'b0;
    count_en = 1'b0;
    done     = 1'b0;

    case(state)

        LOAD  : load_en  = 1'b1;
        ADD   : add_en   = 1'b1;
        SHIFT : shift_en = 1'b1;
        COUNT : count_en = 1'b1;
        DONE  : done     = 1'b1;

        default: ;

    endcase

end

// Next State Logic

always @(*) begin

    next_state = state;

    case(state)

        IDLE:
            if(start)
                next_state = LOAD;

        LOAD:
            next_state = CHECK;

        CHECK:
            if(Q[0])
                next_state = ADD;
            else
                next_state = SHIFT;

        ADD:
            next_state = SHIFT;

        SHIFT:
            next_state = COUNT;

        COUNT:
            if(counter == WIDTH-1)
                next_state = DONE;
            else
                next_state = CHECK;

        DONE:
            next_state = IDLE;

        default:
            next_state = IDLE;

    endcase

end

// Datapath

always @(posedge clk) begin

    if(rst) begin

        A       <= '0;
        M       <= '0;
        Q       <= '0;
        C       <= 1'b0;
        sign    <= 1'b0;
        counter <= '0;
        product <= '0;

    end
    else begin

        if(load_en) begin

            sign <= ip_A[WIDTH-1] ^ ip_B[WIDTH-1];

            M <= ip_A[WIDTH-1] ? {1'b0,(~ip_A + 1'b1)} : {1'b0,ip_A};
            Q <= ip_B[WIDTH-1] ? (~ip_B + 1'b1) : ip_B;

            A <= '0;
            C <= 1'b0;

            counter <= '0;
            product <= '0;

        end

        else if(add_en) begin

            {C,A} <= {1'b0,A} + {1'b0,M};

        end

        else if(shift_en) begin

            {C,A,Q} <= {C,A,Q} >> 1;

        end

        else if(count_en) begin

            if(counter == WIDTH-1) begin

                if(sign)
                    product <= -$signed({A[WIDTH-1:0],Q});
                else
                    product <=  $signed({A[WIDTH-1:0],Q});

            end

            counter <= counter + 1'b1;

        end

    end

end

// State Register

always @(posedge clk) begin

    if(rst)
        state <= IDLE;
    else
        state <= next_state;

end

endmodule
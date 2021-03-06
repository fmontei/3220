library verilog;
use verilog.vl_types.all;
entity Execute is
    port(
        I_CLOCK         : in     vl_logic;
        I_LOCK          : in     vl_logic;
        I_PC            : in     vl_logic_vector(15 downto 0);
        I_Opcode        : in     vl_logic_vector(7 downto 0);
        I_IR            : in     vl_logic_vector(31 downto 0);
        I_Src1Value     : in     vl_logic_vector(15 downto 0);
        I_Src2Value     : in     vl_logic_vector(15 downto 0);
        I_DestRegIdx    : in     vl_logic_vector(3 downto 0);
        I_DestVRegIdx   : in     vl_logic_vector(5 downto 0);
        I_Imm           : in     vl_logic_vector(15 downto 0);
        I_CCValue       : in     vl_logic_vector(2 downto 0);
        I_Idx           : in     vl_logic_vector(1 downto 0);
        I_VecSrc1Value  : in     vl_logic_vector(63 downto 0);
        I_VecSrc2Value  : in     vl_logic_vector(63 downto 0);
        I_DE_Valid      : in     vl_logic;
        I_GPUStallSignal: in     vl_logic;
        O_LOCK          : out    vl_logic;
        O_Opcode        : out    vl_logic_vector(7 downto 0);
        O_IR            : out    vl_logic_vector(31 downto 0);
        O_PC            : out    vl_logic_vector(15 downto 0);
        O_R15PC         : out    vl_logic_vector(15 downto 0);
        O_DestRegIdx    : out    vl_logic_vector(3 downto 0);
        O_DestVRegIdx   : out    vl_logic_vector(5 downto 0);
        O_DestValue     : out    vl_logic_vector(15 downto 0);
        O_CCValue       : out    vl_logic_vector(2 downto 0);
        O_VecSrc1Value  : out    vl_logic_vector(63 downto 0);
        O_VecDestValue  : out    vl_logic_vector(63 downto 0);
        O_EX_Valid      : out    vl_logic;
        O_MARValue      : out    vl_logic_vector(15 downto 0);
        O_MDRValue      : out    vl_logic_vector(15 downto 0);
        O_BranchPC_Signal: out    vl_logic_vector(15 downto 0);
        O_BranchAddrSelect_Signal: out    vl_logic;
        O_RegWEn        : out    vl_logic;
        O_VRegWEn       : out    vl_logic;
        O_CCWEn         : out    vl_logic;
        O_RegWEn_Signal : out    vl_logic;
        O_VRegWEn_Signal: out    vl_logic;
        O_CCWEn_Signal  : out    vl_logic
    );
end Execute;

# Luajit 解释器

** lj_dispatch

GG_State->dispatch[GG_LEN_DISP] 

BC__MAX = 97 // bytecode count
GG_NUM_ASMFF = 57
GG_LEN_DDISP = BC__MAX + GG_NUM_ASMFF // GG_LEN_DDISP = 154
GG_LEN_SDISP = BC_FUNCF // BC_FUNCF = 89
GG_LEN_DISP = GG_LEN_DDISP + GGL_LEN_SDISP // GG_LEN_DISP = 243

---------+<----- dynamic dispatch start
| ISLT   |---> pointer to ISLT bytecode proc
| ISGE   |---> pointer to ISGE bytecode proc
|  ...   |---> .....
| FORI   |<---- BC_FORI = 77 
| JFORI  |
| FORL   | --> init value = disp[BC_IFORL]
| IFORL  |
| JFORL  |
| ITERL  | --> init value = disp[BC_IITERL]
| IITERL |
| JITERL |
| LOOP   | --> init value = disp[BC_ILOOP]
| ILOOP  |
| JLOOP  |
| JMP    |
+--------+  <------ SDISP = 89
| FUNCF  | --> init value = disp[BC_IFUNCF]
| IFUNCF |
| JFUNCF |
| FUNCV  | --> init value = disp[BC_IFUNCV]
| IFUNCV |
| JFUNCV |
| FUNCC  |
| FUNCCW |
+--------+ <----- BC__MAX
| ASMFF  |
| ASMFF  |
| ....   |
+--------+ <---- BC__MAX + GG_NUM_ASMFF = 154  
+--------+ <----- static dispatch start
|  ISLT  | 
|  ISGE  |
|  ...   |
| FORI   |
| JFORI  |
| FORL   |
| IFORL  |
| JFORL  |
| ITERL  |
| IITERL |
| JITERL |
| LOOP   |
| ILOOP  |
| JLOOP  |
| JMP    |
+--------+ <--- END = 154 + 89 = 243




*** dispatch_init
    for (i = 0; i< GG_LEN_SDISP; i++)
        disp[GG_LEN_DDISP+i] = disp[i] = makeasmfunc(lj_bc_ofs[i])











** OpCode List
  /* Comparison ops. ORDER OPR. */ \
  _(ISLT,   var,    ___,    var,    lt) \
  _(ISGE,   var,    ___,    var,    lt) \
  _(ISLE,   var,    ___,    var,    le) \
  _(ISGT,   var,    ___,    var,    le) \
  \
  _(ISEQV,  var,    ___,    var,    eq) \
  _(ISNEV,  var,    ___,    var,    eq) \
  _(ISEQS,  var,    ___,    str,    eq) \
  _(ISNES,  var,    ___,    str,    eq) \
  _(ISEQN,  var,    ___,    num,    eq) \
  _(ISNEN,  var,    ___,    num,    eq) \
  _(ISEQP,  var,    ___,    pri,    eq) \
  _(ISNEP,  var,    ___,    pri,    eq) \
  \
  /* Unary test and copy ops. */ \
  _(ISTC,   dst,    ___,    var,    ___) \
  _(ISFC,   dst,    ___,    var,    ___) \
  _(IST,    ___,    ___,    var,    ___) \
  _(ISF,    ___,    ___,    var,    ___) \
  _(ISTYPE, var,    ___,    lit,    ___) \
  _(ISNUM,  var,    ___,    lit,    ___) \
  \
  /* Unary ops. */ \
  _(MOV,    dst,    ___,    var,    ___) \
  _(NOT,    dst,    ___,    var,    ___) \
  _(UNM,    dst,    ___,    var,    unm) \
  _(LEN,    dst,    ___,    var,    len) \
  \
  /* Binary ops. ORDER OPR. VV last, POW must be next. */ \
  _(ADDVN,  dst,    var,    num,    add) \
  _(SUBVN,  dst,    var,    num,    sub) \
  _(MULVN,  dst,    var,    num,    mul) \
  _(DIVVN,  dst,    var,    num,    div) \
  _(MODVN,  dst,    var,    num,    mod) \
  \
  _(ADDNV,  dst,    var,    num,    add) \
  _(SUBNV,  dst,    var,    num,    sub) \
  _(MULNV,  dst,    var,    num,    mul) \
  _(DIVNV,  dst,    var,    num,    div) \
  _(MODNV,  dst,    var,    num,    mod) \
  \
  _(ADDVV,  dst,    var,    var,    add) \
  _(SUBVV,  dst,    var,    var,    sub) \
  _(MULVV,  dst,    var,    var,    mul) \
  _(DIVVV,  dst,    var,    var,    div) \
  _(MODVV,  dst,    var,    var,    mod) \
  \
  _(POW,    dst,    var,    var,    pow) \
  _(CAT,    dst,    rbase,  rbase,  concat) \
  \
  /* Constant ops. */ \
  _(KSTR,   dst,    ___,    str,    ___) \
  _(KCDATA, dst,    ___,    cdata,  ___) \
  _(KSHORT, dst,    ___,    lits,   ___) \
  _(KNUM,   dst,    ___,    num,    ___) \
  _(KPRI,   dst,    ___,    pri,    ___) \
  _(KNIL,   base,   ___,    base,   ___) \
  \
  /* Upvalue and function ops. */ \
  _(UGET,   dst,    ___,    uv, ___) \
  _(USETV,  uv, ___,    var,    ___) \
  _(USETS,  uv, ___,    str,    ___) \
  _(USETN,  uv, ___,    num,    ___) \
  _(USETP,  uv, ___,    pri,    ___) \
  _(UCLO,   rbase,  ___,    jump,   ___) \
  _(FNEW,   dst,    ___,    func,   gc) \
  \
  /* Table ops. */ \
  _(TNEW,   dst,    ___,    lit,    gc) \
  _(TDUP,   dst,    ___,    tab,    gc) \
  _(GGET,   dst,    ___,    str,    index) \
  _(GSET,   var,    ___,    str,    newindex) \
  _(TGETV,  dst,    var,    var,    index) \
  _(TGETS,  dst,    var,    str,    index) \
  _(TGETB,  dst,    var,    lit,    index) \
  _(TGETR,  dst,    var,    var,    index) \
  _(TSETV,  var,    var,    var,    newindex) \
  _(TSETS,  var,    var,    str,    newindex) \
  _(TSETB,  var,    var,    lit,    newindex) \
  _(TSETM,  base,   ___,    num,    newindex) \
  _(TSETR,  var,    var,    var,    newindex) \
  \
  /* Calls and vararg handling. T = tail call. */ \
  _(CALLM,  base,   lit,    lit,    call) \
  _(CALL,   base,   lit,    lit,    call) \
  _(CALLMT, base,   ___,    lit,    call) \
  _(CALLT,  base,   ___,    lit,    call) \
  _(ITERC,  base,   lit,    lit,    call) \
  _(ITERN,  base,   lit,    lit,    call) \
  _(VARG,   base,   lit,    lit,    ___) \
  _(ISNEXT, base,   ___,    jump,   ___) \
  \
  /* Returns. */ \
  _(RETM,   base,   ___,    lit,    ___) \
  _(RET,    rbase,  ___,    lit,    ___) \
  _(RET0,   rbase,  ___,    lit,    ___) \
  _(RET1,   rbase,  ___,    lit,    ___) \
  \
  /* Loops and branches. I/J = interp/JIT, I/C/L = init/call/loop. */ \
  _(FORI,   base,   ___,    jump,   ___) \
  _(JFORI,  base,   ___,    jump,   ___) \
  \
  _(FORL,   base,   ___,    jump,   ___) \
  _(IFORL,  base,   ___,    jump,   ___) \
  _(JFORL,  base,   ___,    lit,    ___) \
  \
  _(ITERL,  base,   ___,    jump,   ___) \
  _(IITERL, base,   ___,    jump,   ___) \
  _(JITERL, base,   ___,    lit,    ___) \
  \
  _(LOOP,   rbase,  ___,    jump,   ___) \
  _(ILOOP,  rbase,  ___,    jump,   ___) \
  _(JLOOP,  rbase,  ___,    lit,    ___) \
  \
  _(JMP,    rbase,  ___,    jump,   ___) \
  \
  /* Function headers. I/J = interp/JIT, F/V/C = fixarg/vararg/C func. */ \
  _(FUNCF,  rbase,  ___,    ___,    ___) \
  _(IFUNCF, rbase,  ___,    ___,    ___) \
  _(JFUNCF, rbase,  ___,    lit,    ___) \
  _(FUNCV,  rbase,  ___,    ___,    ___) \
  _(IFUNCV, rbase,  ___,    ___,    ___) \
  _(JFUNCV, rbase,  ___,    lit,    ___) \
  _(FUNCC,  rbase,  ___,    ___,    ___) \
  _(FUNCCW, rbase,  ___,    ___,    ___)


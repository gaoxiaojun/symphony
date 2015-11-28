######################################################################
# Automatically generated by qmake (3.0) ?? 11? 28 16:24:14 2015
######################################################################

TEMPLATE = app
TARGET = vm
INCLUDEPATH += .

# Input
HEADERS += core/lj_alloc.h \
           core/lj_arch.h \
           core/lj_debug.h \
           core/lj_def.h \
           core/lj_dispatch.h \
           core/lj_err.h \
           core/lj_errmsg.h \
           core/lj_ff.h \
           core/lj_ffdef.h \
           core/lj_frame.h \
           core/lj_func.h \
           core/lj_gc.h \
           core/lj_lib.h \
           core/lj_libdef.h \
           core/lj_meta.h \
           core/lj_obj.h \
           core/lj_profile.h \
           core/lj_state.h \
           core/lj_tab.h \
           core/lj_udata.h \
           core/lj_vm.h \
           core/lj_vmevent.h \
           dynasm/dasm_arm.h \
           dynasm/dasm_arm64.h \
           dynasm/dasm_mips.h \
           dynasm/dasm_ppc.h \
           dynasm/dasm_proto.h \
           dynasm/dasm_x86.h \
           ffi/lj_carith.h \
           ffi/lj_ccall.h \
           ffi/lj_ccallback.h \
           ffi/lj_cconv.h \
           ffi/lj_cdata.h \
           ffi/lj_clib.h \
           ffi/lj_cparse.h \
           ffi/lj_crecord.h \
           ffi/lj_ctype.h \
           ffi/lj_ffrecord.h \
           jit/lj_asm.h \
           jit/lj_folddef.h \
           jit/lj_jit.h \
           jit/lj_mcode.h \
           jit/lj_recdef.h \
           jit/lj_record.h \
           jit/lj_snap.h \
           jit/lj_target.h \
           jit/lj_trace.h \
           jit/lj_traceerr.h \
           lua/lauxlib.h \
           lua/lua.h \
           lua/lua.hpp \
           lua/luaconf.h \
           lua/luajit.h \
           lua/lualib.h \
           tool/buildvm.h \
           tool/buildvm_arch.h \
           tool/buildvm_libbc.h \
           core/bytecode/lj_bc.h \
           core/bytecode/lj_bcdef.h \
           core/bytecode/lj_bcdump.h \
           core/lang/lj_lex.h \
           core/lang/lj_parse.h \
           core/util/lj_buf.h \
           core/util/lj_char.h \
           core/util/lj_str.h \
           core/util/lj_strfmt.h \
           core/util/lj_strscan.h \
           jit/arch/lj_asm_arm.h \
           jit/arch/lj_asm_mips.h \
           jit/arch/lj_asm_ppc.h \
           jit/arch/lj_asm_x86.h \
           jit/arch/lj_emit_arm.h \
           jit/arch/lj_emit_mips.h \
           jit/arch/lj_emit_ppc.h \
           jit/arch/lj_emit_x86.h \
           jit/arch/lj_target_arm.h \
           jit/arch/lj_target_arm64.h \
           jit/arch/lj_target_mips.h \
           jit/arch/lj_target_ppc.h \
           jit/arch/lj_target_x86.h \
           jit/ir/lj_ir.h \
           jit/ir/lj_ircall.h \
           jit/ir/lj_iropt.h \
           util/gdb/lj_gdbjit.h
SOURCES += core/lj_alloc.c \
           core/lj_api.c \
           core/lj_debug.c \
           core/lj_dispatch.c \
           core/lj_err.c \
           core/lj_func.c \
           core/lj_gc.c \
           core/lj_lib.c \
           core/lj_load.c \
           core/lj_meta.c \
           core/lj_obj.c \
           core/lj_profile.c \
           core/lj_state.c \
           core/lj_tab.c \
           core/lj_udata.c \
           core/lj_vmevent.c \
           core/lj_vmmath.c \
           ffi/lj_carith.c \
           ffi/lj_ccall.c \
           ffi/lj_ccallback.c \
           ffi/lj_cconv.c \
           ffi/lj_cdata.c \
           ffi/lj_clib.c \
           ffi/lj_cparse.c \
           ffi/lj_crecord.c \
           ffi/lj_ctype.c \
           ffi/lj_ffrecord.c \
           jit/lj_asm.c \
           jit/lj_mcode.c \
           jit/lj_record.c \
           jit/lj_snap.c \
           jit/lj_trace.c \
           lua/luajit.c \
           tool/buildvm.c \
           tool/buildvm_asm.c \
           tool/buildvm_fold.c \
           tool/buildvm_lib.c \
           tool/buildvm_peobj.c \
           tool/minilua.c \
           util/ljamalg.c \
           core/bytecode/lj_bc.c \
           core/bytecode/lj_bcread.c \
           core/bytecode/lj_bcwrite.c \
           core/lang/lj_lex.c \
           core/lang/lj_parse.c \
           core/util/lj_buf.c \
           core/util/lj_char.c \
           core/util/lj_str.c \
           core/util/lj_strfmt.c \
           core/util/lj_strscan.c \
           jit/ir/lj_ir.c \
           jit/opt/lj_opt_dce.c \
           jit/opt/lj_opt_fold.c \
           jit/opt/lj_opt_loop.c \
           jit/opt/lj_opt_mem.c \
           jit/opt/lj_opt_narrow.c \
           jit/opt/lj_opt_sink.c \
           jit/opt/lj_opt_split.c \
           lua/lib/lib_aux.c \
           lua/lib/lib_base.c \
           lua/lib/lib_bit.c \
           lua/lib/lib_debug.c \
           lua/lib/lib_ffi.c \
           lua/lib/lib_init.c \
           lua/lib/lib_io.c \
           lua/lib/lib_jit.c \
           lua/lib/lib_math.c \
           lua/lib/lib_os.c \
           lua/lib/lib_package.c \
           lua/lib/lib_string.c \
           lua/lib/lib_table.c \
           util/gdb/lj_gdbjit.c

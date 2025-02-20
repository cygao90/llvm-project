; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -mattr=+m,+v < %s | FileCheck --check-prefix=RV32 %s
; RUN: llc -mtriple=riscv64 -mattr=+m,+v < %s | FileCheck --check-prefix=RV64 %s

; FIXME: We can rematerialize "addi s0, a2, 32" (ideally along the edge
; %do.call -> %exit), and shrink wrap this routine
define void @vecaddr_straightline(i32 zeroext %a, ptr %p) {
; RV32-LABEL: vecaddr_straightline:
; RV32:       # %bb.0:
; RV32-NEXT:    addi sp, sp, -16
; RV32-NEXT:    .cfi_def_cfa_offset 16
; RV32-NEXT:    sw ra, 12(sp) # 4-byte Folded Spill
; RV32-NEXT:    sw s0, 8(sp) # 4-byte Folded Spill
; RV32-NEXT:    .cfi_offset ra, -4
; RV32-NEXT:    .cfi_offset s0, -8
; RV32-NEXT:    addi s0, a1, 32
; RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV32-NEXT:    vle32.v v8, (s0)
; RV32-NEXT:    vadd.vi v8, v8, 1
; RV32-NEXT:    vse32.v v8, (s0)
; RV32-NEXT:    li a1, 57
; RV32-NEXT:    beq a0, a1, .LBB0_2
; RV32-NEXT:  # %bb.1: # %do_call
; RV32-NEXT:    call foo
; RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV32-NEXT:  .LBB0_2: # %exit
; RV32-NEXT:    vle32.v v8, (s0)
; RV32-NEXT:    vadd.vi v8, v8, 1
; RV32-NEXT:    vse32.v v8, (s0)
; RV32-NEXT:    lw ra, 12(sp) # 4-byte Folded Reload
; RV32-NEXT:    lw s0, 8(sp) # 4-byte Folded Reload
; RV32-NEXT:    .cfi_restore ra
; RV32-NEXT:    .cfi_restore s0
; RV32-NEXT:    addi sp, sp, 16
; RV32-NEXT:    .cfi_def_cfa_offset 0
; RV32-NEXT:    ret
;
; RV64-LABEL: vecaddr_straightline:
; RV64:       # %bb.0:
; RV64-NEXT:    addi sp, sp, -16
; RV64-NEXT:    .cfi_def_cfa_offset 16
; RV64-NEXT:    sd ra, 8(sp) # 8-byte Folded Spill
; RV64-NEXT:    sd s0, 0(sp) # 8-byte Folded Spill
; RV64-NEXT:    .cfi_offset ra, -8
; RV64-NEXT:    .cfi_offset s0, -16
; RV64-NEXT:    addi s0, a1, 32
; RV64-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV64-NEXT:    vle32.v v8, (s0)
; RV64-NEXT:    vadd.vi v8, v8, 1
; RV64-NEXT:    vse32.v v8, (s0)
; RV64-NEXT:    li a1, 57
; RV64-NEXT:    beq a0, a1, .LBB0_2
; RV64-NEXT:  # %bb.1: # %do_call
; RV64-NEXT:    call foo
; RV64-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV64-NEXT:  .LBB0_2: # %exit
; RV64-NEXT:    vle32.v v8, (s0)
; RV64-NEXT:    vadd.vi v8, v8, 1
; RV64-NEXT:    vse32.v v8, (s0)
; RV64-NEXT:    ld ra, 8(sp) # 8-byte Folded Reload
; RV64-NEXT:    ld s0, 0(sp) # 8-byte Folded Reload
; RV64-NEXT:    .cfi_restore ra
; RV64-NEXT:    .cfi_restore s0
; RV64-NEXT:    addi sp, sp, 16
; RV64-NEXT:    .cfi_def_cfa_offset 0
; RV64-NEXT:    ret
  %gep = getelementptr i8, ptr %p, i32 32
  %v1 = load <4 x i32>, ptr %gep
  %v2 = add <4 x i32> %v1, splat (i32 1)
  store <4 x i32> %v2, ptr %gep
  %cmp0 = icmp eq i32 %a, 57
  br i1 %cmp0, label %exit, label %do_call
do_call:
  call i32 @foo()
  br label %exit
exit:
  %v3 = load <4 x i32>, ptr %gep
  %v4 = add <4 x i32> %v3, splat (i32 1)
  store <4 x i32> %v4, ptr %gep
  ret void
}

; In this case, the second use is in a loop, so using a callee
; saved register to avoid a remat is the profitable choice.
; FIXME: We can shrink wrap the frame setup around the loop
; and avoid it along the %bb.0 -> %exit edge
define void @vecaddr_loop(i32 zeroext %a, ptr %p) {
; RV32-LABEL: vecaddr_loop:
; RV32:       # %bb.0:
; RV32-NEXT:    addi sp, sp, -16
; RV32-NEXT:    .cfi_def_cfa_offset 16
; RV32-NEXT:    sw ra, 12(sp) # 4-byte Folded Spill
; RV32-NEXT:    sw s0, 8(sp) # 4-byte Folded Spill
; RV32-NEXT:    .cfi_offset ra, -4
; RV32-NEXT:    .cfi_offset s0, -8
; RV32-NEXT:    addi s0, a1, 32
; RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV32-NEXT:    vle32.v v8, (s0)
; RV32-NEXT:    vadd.vi v8, v8, 1
; RV32-NEXT:    vse32.v v8, (s0)
; RV32-NEXT:    li a1, 57
; RV32-NEXT:    beq a0, a1, .LBB1_2
; RV32-NEXT:  .LBB1_1: # %do_call
; RV32-NEXT:    # =>This Inner Loop Header: Depth=1
; RV32-NEXT:    call foo
; RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV32-NEXT:    vle32.v v8, (s0)
; RV32-NEXT:    vadd.vi v8, v8, 1
; RV32-NEXT:    vse32.v v8, (s0)
; RV32-NEXT:    bnez a0, .LBB1_1
; RV32-NEXT:  .LBB1_2: # %exit
; RV32-NEXT:    lw ra, 12(sp) # 4-byte Folded Reload
; RV32-NEXT:    lw s0, 8(sp) # 4-byte Folded Reload
; RV32-NEXT:    .cfi_restore ra
; RV32-NEXT:    .cfi_restore s0
; RV32-NEXT:    addi sp, sp, 16
; RV32-NEXT:    .cfi_def_cfa_offset 0
; RV32-NEXT:    ret
;
; RV64-LABEL: vecaddr_loop:
; RV64:       # %bb.0:
; RV64-NEXT:    addi sp, sp, -16
; RV64-NEXT:    .cfi_def_cfa_offset 16
; RV64-NEXT:    sd ra, 8(sp) # 8-byte Folded Spill
; RV64-NEXT:    sd s0, 0(sp) # 8-byte Folded Spill
; RV64-NEXT:    .cfi_offset ra, -8
; RV64-NEXT:    .cfi_offset s0, -16
; RV64-NEXT:    addi s0, a1, 32
; RV64-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV64-NEXT:    vle32.v v8, (s0)
; RV64-NEXT:    vadd.vi v8, v8, 1
; RV64-NEXT:    vse32.v v8, (s0)
; RV64-NEXT:    li a1, 57
; RV64-NEXT:    beq a0, a1, .LBB1_2
; RV64-NEXT:  .LBB1_1: # %do_call
; RV64-NEXT:    # =>This Inner Loop Header: Depth=1
; RV64-NEXT:    call foo
; RV64-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV64-NEXT:    vle32.v v8, (s0)
; RV64-NEXT:    vadd.vi v8, v8, 1
; RV64-NEXT:    vse32.v v8, (s0)
; RV64-NEXT:    bnez a0, .LBB1_1
; RV64-NEXT:  .LBB1_2: # %exit
; RV64-NEXT:    ld ra, 8(sp) # 8-byte Folded Reload
; RV64-NEXT:    ld s0, 0(sp) # 8-byte Folded Reload
; RV64-NEXT:    .cfi_restore ra
; RV64-NEXT:    .cfi_restore s0
; RV64-NEXT:    addi sp, sp, 16
; RV64-NEXT:    .cfi_def_cfa_offset 0
; RV64-NEXT:    ret
  %gep = getelementptr i8, ptr %p, i32 32
  %v1 = load <4 x i32>, ptr %gep
  %v2 = add <4 x i32> %v1, splat (i32 1)
  store <4 x i32> %v2, ptr %gep
  %cmp0 = icmp eq i32 %a, 57
  br i1 %cmp0, label %exit, label %do_call
do_call:
  %b = call i32 @foo()
  %v3 = load <4 x i32>, ptr %gep
  %v4 = add <4 x i32> %v3, splat (i32 1)
  store <4 x i32> %v4, ptr %gep

  %cmp1 = icmp eq i32 %b, 0
  br i1 %cmp1, label %exit, label %do_call
exit:
  ret void
}

declare zeroext i32 @foo()


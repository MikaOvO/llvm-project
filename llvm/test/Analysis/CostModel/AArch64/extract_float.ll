; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py UTC_ARGS: --version 5
; RUN: opt < %s -passes="print<cost-model>" 2>&1 -disable-output -mtriple=aarch64-unknown-linux \
; RUN:       -mattr=-fullfp16 | FileCheck %s --check-prefixes=CHECK,NOFP16
; RUN: opt < %s -passes="print<cost-model>" 2>&1 -disable-output -mtriple=aarch64-unknown-linux \
; RUN:       -mattr=+fullfp16 | FileCheck %s --check-prefixes=CHECK,FULLFP16

; res = lane 0 * lane 1
define double @extract_case1(<2 x double> %a) {
; CHECK-LABEL: 'extract_case1'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %1 = extractelement <2 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul double %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <2 x double> %a, i32 0
  %2 = extractelement <2 x double> %a, i32 1
  %res = fmul double %1, %2
  ret double %res
}

; res = lane 1 * lane 1
define double @extract_case2(<2 x double> %a) {
; CHECK-LABEL: 'extract_case2'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %0 = extractelement <2 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul double %0, %0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <2 x double> %a, i32 1
  %res = fmul double %1, %1
  ret double %res
}

; res = lane 0 * lane 0
define double @extract_case3(<2 x double> %a) {
; CHECK-LABEL: 'extract_case3'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul double %0, %0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <2 x double> %a, i32 0
  %res = fmul double %1, %1
  ret double %res
}

; res = lane 0 * scalar
define double @extract_case4(<2 x double> %a, double %b) {
; CHECK-LABEL: 'extract_case4'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul double %0, %b
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <2 x double> %a, i32 0
  %res = fmul double %1, %b
  ret double %res
}

; res = lane 1 * scalar
define double @extract_case5(<2 x double> %a, double %b) {
; CHECK-LABEL: 'extract_case5'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul double %0, %b
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <2 x double> %a, i32 1
  %res = fmul double %1, %b
  ret double %res
}

; Input vector = <3 x double> (i.e. odd length vector)
; res = lane 0 * lane 1
define double @extract_case6(<3 x double> %a) {
; CHECK-LABEL: 'extract_case6'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <3 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %1 = extractelement <3 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul double %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <3 x double> %a, i32 0
  %2 = extractelement <3 x double> %a, i32 1
  %res = fmul double %1, %2
  ret double %res
}

; res = lane 1 * lane 2
; Extract from lane 2 is equivalent to extract from lane 0 of other 128-bit
; register. But for other register sizes, this is not the case.
define double @extract_case7(<4 x double> %a) {
; CHECK-LABEL: 'extract_case7'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <4 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %1 = extractelement <4 x double> %a, i32 2
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul double %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <4 x double> %a, i32 1
  %2 = extractelement <4 x double> %a, i32 2
  %res = fmul double %1, %2
  ret double %res
}

; res = lane 0 * lane 1
; Additional insert of extract from lane 1.
define double @extract_case8(<2 x double> %a) {
; CHECK-LABEL: 'extract_case8'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %1 = extractelement <2 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %2 = insertelement <2 x double> %a, double %1, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 8 for instruction: %3 = call double @llvm.vector.reduce.fmul.v2f64(double 0.000000e+00, <2 x double> %2)
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %4 = fmul double %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %5 = fmul double %3, %4
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %5
entry:
  %1 = extractelement <2 x double> %a, i32 0
  %2 = extractelement <2 x double> %a, i32 1
  %3 = insertelement <2 x double> %a, double %2, i32 0
  %4 = call double @llvm.vector.reduce.fmul.v2f64(double 0.0, <2 x double> %3)
  %5 = fmul double %1, %2
  %6 = fmul double %4, %5
  ret double %6
}

; res = lane 0 * lane 1
; Additional insert of extract from lane 1.
define double @extract_case9(<2 x double> %a) {
; CHECK-LABEL: 'extract_case9'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %1 = extractelement <2 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %2 = insertelement <2 x double> %a, double %1, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 6 for instruction: %3 = call double @llvm.vector.reduce.fadd.v2f64(double 0.000000e+00, <2 x double> %2)
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %4 = fmul double %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %5 = fmul double %3, %4
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %5
entry:
  %1 = extractelement <2 x double> %a, i32 0
  %2 = extractelement <2 x double> %a, i32 1
  %3 = insertelement <2 x double> %a, double %2, i32 0
  %4 = call double @llvm.vector.reduce.fadd.v2f64(double 0.0, <2 x double> %3)
  %5 = fmul double %1, %2
  %6 = fmul double %4, %5
  ret double %6
}

; res = lane 0 * lane 1
; Extract from lane 1 passed as function param.
define double @extract_case10(<4 x double> %a) {
; CHECK-LABEL: 'extract_case10'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <4 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %1 = extractelement <4 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: call void @foo(double %1)
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %2 = fmul double %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %2
entry:
  %1 = extractelement <4 x double> %a, i32 0
  %2 = extractelement <4 x double> %a, i32 1
  call void @foo(double %2)
  %3 = fmul double %1, %2
  ret double %3
}

; res = lane 0 * lane 1
define half @extract_case11(<2 x half> %a) {
; NOFP16-LABEL: 'extract_case11'
; NOFP16-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x half> %a, i32 0
; NOFP16-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %1 = extractelement <2 x half> %a, i32 1
; NOFP16-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul half %0, %1
; NOFP16-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret half %res
;
; FULLFP16-LABEL: 'extract_case11'
; FULLFP16-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x half> %a, i32 0
; FULLFP16-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %1 = extractelement <2 x half> %a, i32 1
; FULLFP16-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul half %0, %1
; FULLFP16-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret half %res
entry:
  %1 = extractelement <2 x half> %a, i32 0
  %2 = extractelement <2 x half> %a, i32 1
  %res = fmul half %1, %2
  ret half %res
}

; res = lane 0 * lane 1
define float @extract_case12(<2 x float> %a) {
; CHECK-LABEL: 'extract_case12'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x float> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %1 = extractelement <2 x float> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %res = fmul float %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret float %res
entry:
  %1 = extractelement <2 x float> %a, i32 0
  %2 = extractelement <2 x float> %a, i32 1
  %res = fmul float %1, %2
  ret float %res
}

; res = lane 0 + lane 1
; Use of bin-op other than fmul.
define double @extract_case13(<2 x double> %a) {
; CHECK-LABEL: 'extract_case13'
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: %0 = extractelement <2 x double> %a, i32 0
; CHECK-NEXT:  Cost Model: Found an estimated cost of 2 for instruction: %1 = extractelement <2 x double> %a, i32 1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 1 for instruction: %res = fadd double %0, %1
; CHECK-NEXT:  Cost Model: Found an estimated cost of 0 for instruction: ret double %res
entry:
  %1 = extractelement <2 x double> %a, i32 0
  %2 = extractelement <2 x double> %a, i32 1
  %res = fadd double %1, %2
  ret double %res
}

declare void @foo(double)

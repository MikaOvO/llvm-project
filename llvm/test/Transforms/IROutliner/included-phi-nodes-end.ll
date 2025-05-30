; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --include-generated-funcs
; RUN: opt -S -passes=verify,iroutliner -ir-outlining-no-cost < %s | FileCheck %s

; Show that we are able to propagate inputs to the region into the split PHINode
; outside of the region if necessary.

define void @function1(ptr %a, ptr %b) {
entry:
  %0 = alloca i32, align 4
  %c = load i32, ptr %0, align 4
  %z = add i32 %c, %c
  br i1 true, label %test1, label %first
test1:
  %e = load i32, ptr %0, align 4
  %1 = add i32 %c, %c
  br i1 true, label %first, label %test
test:
  %d = load i32, ptr %0, align 4
  br i1 true, label %first, label %next
first:
  %2 = phi i32 [ %d, %test ], [ %e, %test1 ], [ %c, %entry ]
  %3 = phi i32 [ %d, %test ], [ %e, %test1 ], [ %c, %entry ]
  ret void
next:
  ret void
}

define void @function2(ptr %a, ptr %b) {
entry:
  %0 = alloca i32, align 4
  %c = load i32, ptr %0, align 4
  %z = mul i32 %c, %c
  br i1 true, label %test1, label %first
test1:
  %e = load i32, ptr %0, align 4
  %1 = add i32 %c, %c
  br i1 true, label %first, label %test
test:
  %d = load i32, ptr %0, align 4
  br i1 true, label %first, label %next
first:
  %2 = phi i32 [ %d, %test ], [ %e, %test1 ], [ %c, %entry ]
  %3 = phi i32 [ %d, %test ], [ %e, %test1 ], [ %c, %entry ]
  ret void
next:
  ret void
}
; CHECK-LABEL: @function1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = alloca i32, align 4
; CHECK-NEXT:    [[C:%.*]] = load i32, ptr [[TMP0]], align 4
; CHECK-NEXT:    [[Z:%.*]] = add i32 [[C]], [[C]]
; CHECK-NEXT:    [[TARGETBLOCK:%.*]] = call i1 @outlined_ir_func_0(ptr [[TMP0]], i32 [[C]])
; CHECK-NEXT:    br i1 [[TARGETBLOCK]], label [[NEXT:%.*]], label [[ENTRY_AFTER_OUTLINE:%.*]]
; CHECK:       entry_after_outline:
; CHECK-NEXT:    ret void
; CHECK:       next:
; CHECK-NEXT:    ret void
;
;
; CHECK-LABEL: @function2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = alloca i32, align 4
; CHECK-NEXT:    [[C:%.*]] = load i32, ptr [[TMP0]], align 4
; CHECK-NEXT:    [[Z:%.*]] = mul i32 [[C]], [[C]]
; CHECK-NEXT:    [[TARGETBLOCK:%.*]] = call i1 @outlined_ir_func_0(ptr [[TMP0]], i32 [[C]])
; CHECK-NEXT:    br i1 [[TARGETBLOCK]], label [[NEXT:%.*]], label [[ENTRY_AFTER_OUTLINE:%.*]]
; CHECK:       entry_after_outline:
; CHECK-NEXT:    ret void
; CHECK:       next:
; CHECK-NEXT:    ret void
;
;
; CHECK: define internal i1 @outlined_ir_func_0(
; CHECK-NEXT:  newFuncRoot:
; CHECK-NEXT:    br label [[ENTRY_TO_OUTLINE:%.*]]
; CHECK:       entry_to_outline:
; CHECK-NEXT:    br i1 true, label [[TEST1:%.*]], label [[FIRST:%.*]]
; CHECK:       test1:
; CHECK-NEXT:    [[E:%.*]] = load i32, ptr [[TMP0:%.*]], align 4
; CHECK-NEXT:    [[TMP2:%.*]] = add i32 [[TMP1:%.*]], [[TMP1]]
; CHECK-NEXT:    br i1 true, label [[FIRST]], label [[TEST:%.*]]
; CHECK:       test:
; CHECK-NEXT:    [[D:%.*]] = load i32, ptr [[TMP0]], align 4
; CHECK-NEXT:    br i1 true, label [[FIRST]], label [[NEXT_EXITSTUB:%.*]]
; CHECK:       first:
; CHECK-NEXT:    [[TMP3:%.*]] = phi i32 [ [[D]], [[TEST]] ], [ [[E]], [[TEST1]] ], [ [[TMP1]], [[ENTRY_TO_OUTLINE]] ]
; CHECK-NEXT:    [[TMP4:%.*]] = phi i32 [ [[D]], [[TEST]] ], [ [[E]], [[TEST1]] ], [ [[TMP1]], [[ENTRY_TO_OUTLINE]] ]
; CHECK-NEXT:    br label [[ENTRY_AFTER_OUTLINE_EXITSTUB:%.*]]
; CHECK:       next.exitStub:
; CHECK-NEXT:    ret i1 true
; CHECK:       entry_after_outline.exitStub:
; CHECK-NEXT:    ret i1 false
;

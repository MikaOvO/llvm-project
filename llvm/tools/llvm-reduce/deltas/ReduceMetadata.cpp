//===- ReduceMetadata.cpp - Specialized Delta Pass ------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements two functions used by the Generic Delta Debugging
// Algorithm, which are used to reduce Metadata nodes.
//
//===----------------------------------------------------------------------===//

#include "ReduceMetadata.h"
#include "llvm/ADT/Sequence.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

extern cl::OptionCategory LLVMReduceOptions;

static cl::opt<bool> AggressiveMetadataReduction(
    "aggressive-named-md-reduction",
    cl::desc("Reduce named metadata without taking its type into account"),
    cl::cat(LLVMReduceOptions));

static bool shouldKeepDebugIntrinsicMetadata(Instruction &I, MDNode &MD) {
  return isa<DILocation>(MD) && isa<DbgInfoIntrinsic>(I);
}

static bool shouldKeepDebugNamedMetadata(NamedMDNode &MD) {
  return MD.getName() == "llvm.dbg.cu" && MD.getNumOperands() != 0;
}

// Named metadata with simple list-like behavior, so that it's valid to remove
// operands individually.
static constexpr StringLiteral ListNamedMetadata[] = {
  "llvm.module.flags",
  "llvm.ident",
  "opencl.spir.version",
  "opencl.ocl.version",
  "opencl.used.extensions",
  "opencl.used.optional.core.features",
  "opencl.compiler.options"
};

/// Remove unneeded arguments to named metadata.
void llvm::reduceNamedMetadataDeltaPass(Oracle &O, ReducerWorkItem &WorkItem) {
  Module &M = WorkItem.getModule();

  for (NamedMDNode &I : M.named_metadata()) {
    // If we don't want to reduce mindlessly, check if our node is part of
    // ListNamedMetadata before reducing it
    if (!AggressiveMetadataReduction &&
        !is_contained(ListNamedMetadata, I.getName()))
      continue;

    bool MadeChange = false;
    SmallVector<MDNode *> KeptOperands;
    for (auto J : seq<unsigned>(0, I.getNumOperands())) {
      if (O.shouldKeep())
        KeptOperands.push_back(I.getOperand(J));
      else
        MadeChange = true;
    }

    if (MadeChange) {
      I.clearOperands();
      for (MDNode *KeptOperand : KeptOperands)
        I.addOperand(KeptOperand);
    }
  }
}

/// Removes all the Named and Unnamed Metadata Nodes, as well as any debug
/// functions that aren't inside the desired Chunks.
void llvm::reduceMetadataDeltaPass(Oracle &O, ReducerWorkItem &WorkItem) {
  Module &Program = WorkItem.getModule();

  // Get out-of-chunk Named metadata nodes
  SmallVector<NamedMDNode *> NamedNodesToDelete;
  for (NamedMDNode &MD : Program.named_metadata())
    if (!shouldKeepDebugNamedMetadata(MD) && !O.shouldKeep())
      NamedNodesToDelete.push_back(&MD);

  for (NamedMDNode *NN : NamedNodesToDelete) {
    for (auto I : seq<unsigned>(0, NN->getNumOperands()))
      NN->setOperand(I, nullptr);
    NN->eraseFromParent();
  }

  // Delete out-of-chunk metadata attached to globals.
  for (GlobalVariable &GV : Program.globals()) {
    SmallVector<std::pair<unsigned, MDNode *>> MDs;
    GV.getAllMetadata(MDs);
    for (std::pair<unsigned, MDNode *> &MD : MDs)
      if (!O.shouldKeep())
        GV.setMetadata(MD.first, nullptr);
  }

  for (Function &F : Program) {
    {
      SmallVector<std::pair<unsigned, MDNode *>> MDs;
      // Delete out-of-chunk metadata attached to functions.
      F.getAllMetadata(MDs);
      for (std::pair<unsigned, MDNode *> &MD : MDs)
        if (!O.shouldKeep())
          F.setMetadata(MD.first, nullptr);
    }

    // Delete out-of-chunk metadata attached to instructions.
    for (Instruction &I : instructions(F)) {
      SmallVector<std::pair<unsigned, MDNode *>> MDs;
      I.getAllMetadata(MDs);
      for (std::pair<unsigned, MDNode *> &MD : MDs) {
        if (!shouldKeepDebugIntrinsicMetadata(I, *MD.second) && !O.shouldKeep())
          I.setMetadata(MD.first, nullptr);
      }
    }
  }
}

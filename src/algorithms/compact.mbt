/// ================================================================================
/// COMPACT DIFF ALGORITHM
/// ================================================================================
///
/// The Compact algorithm post-processes diff operations to produce more
/// human-readable and compact output. It merges adjacent operations and
/// shifts operations to create cleaner diffs.
///
/// ALGORITHM OVERVIEW:
/// 1. Collect all diff operations from underlying algorithm
/// 2. Shift operations up and down to merge adjacent similar operations
/// 3. Merge consecutive insertions/deletions into single operations
/// 4. Sort operations to ensure consistent ordering
///
/// KEY INSIGHTS:
/// - Adjacent insertions can be merged into a single insertion
/// - Adjacent deletions can be merged into a single deletion  
/// - Operations can be shifted to align with common prefixes/suffixes
/// - This produces diffs that are more intuitive for human readers
///
/// TIME COMPLEXITY: O(N²) where N is the number of operations
/// SPACE COMPLEXITY: O(N)

///|
/// ================================================================================
/// COMPACT DIFF STRUCTURE
/// ================================================================================
///
/// A diff hook that wraps another hook and performs compaction on the operations
/// before passing them through.
pub(all) struct Compact[D, T] {
  /// Inner diff hook that receives the compacted operations
  d : D
  /// Temporary storage for collecting operations before compaction
  ops : Array[DiffOp]
  /// Reference to old sequence for context during compaction
  old : Array[T]
  /// Reference to new sequence for context during compaction
  new : Array[T]
}

///|
/// Creates a new Compact hook that wraps the provided diff hook
pub fn[D, T] Compact::new(
  d : D,
  old : Array[T],
  new : Array[T],
) -> Compact[D, T] {
  { d, ops: Array::new(), old, new }
}

///|
/// Consumes the Compact hook and returns the inner hook
pub fn[D, T] Compact::into_inner(self : Compact[D, T]) -> D {
  self.d
}

///|
/// Returns collected operations (for testing purposes)
pub fn[D, T] Compact::into_ops(self : Compact[D, T]) -> Array[DiffOp] {
  self.ops
}

/// ================================================================================
/// DIFF HOOK IMPLEMENTATION
/// ================================================================================
///
/// These implementations collect operations during the diff process

///|
/// Captures an Equal operation for later compaction
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with equal(
  self,
  old_index,
  new_index,
  len,
) -> Result[Unit, Error] {
  self.ops.push(DiffOp::Equal(old_index~, new_index~, len~))
  Ok(())
}

///|
/// Captures a Delete operation for later compaction
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with delete(
  self,
  old_index,
  old_len,
  new_index,
) -> Result[Unit, Error] {
  self.ops.push(DiffOp::Delete(old_index~, old_len~, new_index~))
  Ok(())
}

///|
/// Captures an Insert operation for later compaction
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with insert(
  self,
  old_index,
  new_index,
  new_len,
) -> Result[Unit, Error] {
  self.ops.push(DiffOp::Insert(old_index~, new_index~, new_len~))
  Ok(())
}

///|
/// Final processing step - applies compaction algorithms
///
/// PROCESSING PIPELINE:
/// 1. Clean up operations using shift algorithms
/// 2. Sort operations for consistent ordering
/// 3. Apply operations to inner hook
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with finish(self) -> Result[
  Unit,
  Error,
] {
  // Step 1: Apply compaction algorithms
  cleanup_diff_ops(self.old, self.new, self.ops)

  // Step 2: Ensure consistent ordering
  self.sort()

  // Step 3: Apply compacted operations to inner hook
  for op in self.ops {
    let _ = op.apply_to_hook(self.d)

  }
  self.d.finish()
}

/// ================================================================================
/// COMPACTION ALGORITHMS
/// ================================================================================

///|
/// Main compaction algorithm that coordinates the cleanup process
///
/// STRATEGY:
/// 1. First pass: shift and merge delete operations
/// 2. Second pass: shift and merge insert operations
/// 3. Each pass applies both upward and downward shifts
pub fn[T : Eq] cleanup_diff_ops(
  old : Array[T],
  new : Array[T],
  ops : Array[DiffOp],
) -> Unit {
  // Pass 1: Process delete operations
  let mut pointer = 0
  while pointer < ops.length() {
    let op = ops.get(pointer).unwrap()
    match op {
      DiffOp::Delete(..) => {
        // Shift delete operations up and down to enable merging
        pointer = shift_diff_ops_up(ops, old, new, pointer)
        pointer = shift_diff_ops_down(ops, old, new, pointer)
      }
      _ => ()
    }
    pointer += 1
  }

  // Pass 2: Process insert operations
  pointer = 0
  while pointer < ops.length() {
    let op = ops.get(pointer).unwrap()
    match op {
      DiffOp::Insert(..) => {
        // Shift insert operations up and down to enable merging
        pointer = shift_diff_ops_up(ops, old, new, pointer)
        pointer = shift_diff_ops_down(ops, old, new, pointer)
      }
      _ => ()
    }
    pointer += 1
  }
}

/// ================================================================================
/// SHIFTING ALGORITHMS
/// ================================================================================
///
/// These algorithms shift operations to enable merging and create cleaner diffs

///|
/// Shifts operations upward (earlier) to merge with previous operations
///
/// SHIFTING RULES:
/// 1. Swap insert/delete operations to group similar operations
/// 2. Merge adjacent operations of the same type
/// 3. Align operations with common prefixes/suffixes
/// 4. Remove empty operations
pub fn[T : Eq] shift_diff_ops_up(
  ops : Array[DiffOp],
  old : Array[T],
  new : Array[T],
  pointer : Int,
) -> Int {
  let mut pointer = pointer
  while pointer > 1 {
    let prev_op = ops[pointer - 1]
    let this_op = ops[pointer]
    match (this_op, prev_op) {
      // Rule 1: Swap insert/delete to group similar operations
      (DiffOp::Insert(..), DiffOp::Delete(..))
      | (DiffOp::Delete(..), DiffOp::Insert(..)) => {
        ops.swap(pointer - 1, pointer)
        pointer -= 1
      }

      // Rule 2: Merge adjacent insert operations
      (DiffOp::Insert(..), DiffOp::Insert(..)) => {
        ops[pointer - 1].grow_right(this_op.new_range().len())
        let _ = ops.remove(pointer)
        pointer -= 1
      }

      // Rule 3: Merge adjacent delete operations
      (DiffOp::Delete(..), DiffOp::Delete(..)) => {
        ops[pointer - 1].grow_right(this_op.old_range().len())
        let _ = ops.remove(pointer)
        pointer -= 1
      }

      // Rule 4: Align insert with common suffix
      (DiffOp::Insert(..), DiffOp::Equal(..)) => {
        let suffix_len = common_suffix_len(
          new,
          prev_op.new_range(),
          new,
          this_op.new_range(),
        )
        if suffix_len > 0 {
          // Found common suffix - can shift operation
          match ops.get(pointer + 1) {
            Some(DiffOp::Equal(..) as next_op) => next_op.grow_left(suffix_len)
            _ => {
              // Create new Equal operation for common suffix
              let old_index = this_op.old_range().end - suffix_len
              let new_index = this_op.new_range().end - suffix_len
              let len = suffix_len
              ops.insert(
                pointer + 1,
                DiffOp::Equal(old_index~, new_index~, len~),
              )
            }
          }

          // Adjust operation boundaries
          this_op.shift_left(suffix_len)
          prev_op.shrink_left(suffix_len)

          // Remove empty operations
          if prev_op.is_empty() {
            let _ = ops.remove(pointer - 1)
            pointer -= 1
          }
        } else if ops[pointer - 1].is_empty() {
          let _ = ops.remove(pointer - 1)
          pointer -= 1
        } else {
          break
        }
      }

      // Rule 5: Align delete with common suffix
      (DiffOp::Delete(..), DiffOp::Equal(..)) => {
        let suffix_len = common_suffix_len(
          old,
          prev_op.old_range(),
          old,
          this_op.old_range(),
        )
        if suffix_len > 0 {
          // Found common suffix - can shift operation
          match ops.get(pointer + 1) {
            Some(DiffOp::Equal(..) as next_op) => next_op.grow_left(suffix_len)
            _ => {
              // Create new Equal operation for common suffix
              let old_index = this_op.old_range().end - suffix_len
              let new_index = this_op.new_range().end - suffix_len
              let len = suffix_len
              ops.insert(
                pointer + 1,
                DiffOp::Equal(old_index~, new_index~, len~),
              )
            }
          }

          // Adjust operation boundaries
          this_op.shift_left(suffix_len)
          prev_op.shrink_left(suffix_len)

          // Remove empty operations
          if prev_op.is_empty() {
            let _ = ops.remove(pointer - 1)
            pointer -= 1
          }
        } else if ops[pointer - 1].is_empty() {
          let _ = ops.remove(pointer - 1)
          pointer -= 1
        } else {
          break
        }
      }
      _ => break
    }
  }
  pointer
}

///|
/// Shifts operations downward (later) to merge with following operations
///
/// Similar to shift_diff_ops_up but operates in the downward direction
/// Uses common prefixes instead of suffixes for alignment
pub fn[T : Eq] shift_diff_ops_down(
  ops : Array[DiffOp],
  old : Array[T],
  new : Array[T],
  pointer : Int,
) -> Int {
  let mut pointer = pointer
  while pointer < ops.length() - 1 {
    let next_op = ops[pointer + 1]
    let this_op = ops[pointer]
    match (this_op, next_op) {
      // Rule 1: Swap insert/delete operations
      (DiffOp::Insert(..), DiffOp::Delete(..))
      | (DiffOp::Delete(..), DiffOp::Insert(..)) => {
        ops.swap(pointer, pointer + 1)
        pointer += 1
      }

      // Rule 2: Merge adjacent insert operations
      (DiffOp::Insert(..), DiffOp::Insert(..)) => {
        this_op.grow_right(next_op.new_range().len())
        let _ = ops.remove(pointer + 1)

      }

      // Rule 3: Merge adjacent delete operations
      (DiffOp::Delete(..), DiffOp::Delete(..)) => {
        this_op.grow_right(next_op.old_range().len())
        let _ = ops.remove(pointer + 1)

      }

      // Rule 4: Align insert with common prefix
      (DiffOp::Insert(..), DiffOp::Equal(..)) => {
        let prefix_len = common_prefix_len(
          new,
          next_op.new_range(),
          new,
          this_op.new_range(),
        )
        if prefix_len > 0 {
          // Found common prefix - can shift operation
          match ops.get(pointer - 1) {
            Some(DiffOp::Equal(..) as prev_op) => prev_op.grow_right(prefix_len)
            _ => {
              // Create new Equal operation for common prefix
              let old_index = this_op.old_range().start
              let new_index = next_op.new_range().start
              let len = prefix_len
              ops.insert(pointer, DiffOp::Equal(old_index~, new_index~, len~))
              pointer += 1
            }
          }

          // Adjust operation boundaries
          this_op.shift_right(prefix_len)
          next_op.shrink_right(prefix_len)

          // Remove empty operations
          if next_op.is_empty() {
            let _ = ops.remove(pointer + 1)

          }
        } else if ops[pointer + 1].is_empty() {
          let _ = ops.remove(pointer + 1)

        } else {
          break
        }
      }

      // Rule 5: Align delete with common prefix
      (DiffOp::Delete(..), DiffOp::Equal(..)) => {
        let prefix_len = common_prefix_len(
          old,
          next_op.old_range(),
          old,
          this_op.old_range(),
        )
        if prefix_len > 0 {
          // Found common prefix - can shift operation
          match ops.get(pointer - 1) {
            Some(DiffOp::Equal(..) as prev_op) => prev_op.grow_right(prefix_len)
            _ => {
              // Create new Equal operation for common prefix
              let old_index = this_op.old_range().start
              let new_index = this_op.new_range().start
              let len = prefix_len
              ops.insert(pointer, DiffOp::Equal(old_index~, new_index~, len~))
              pointer += 1
            }
          }

          // Adjust operation boundaries
          this_op.shift_left(prefix_len)
          next_op.shrink_left(prefix_len)

          // Remove empty operations
          if next_op.is_empty() {
            let _ = ops.remove(pointer + 1)

          }
        } else if ops[pointer + 1].is_empty() {
          let _ = ops.remove(pointer + 1)

        } else {
          break
        }
      }
      _ => break
    }
  }
  pointer
}

///|
/// ================================================================================
/// SORTING ALGORITHM
/// ================================================================================
///
/// Ensures consistent ordering of operations for predictable output
/// Sorts primarily by old sequence position, secondarily by new sequence position
pub fn[D, T] Compact::sort(self : Compact[D, T]) -> Unit {
  fn get_old_new_index(op : DiffOp) -> (Int, Int)? {
    match op {
      DiffOp::Equal(old_index~, new_index~, len=_) =>
        Some((old_index, new_index))
      DiffOp::Delete(old_index~, old_len=_, new_index~) =>
        Some((old_index, new_index))
      DiffOp::Insert(old_index~, new_index~, new_len=_) =>
        Some((old_index, new_index))
      DiffOp::Replace(old_index~, old_len=_, new_index~, new_len=_) =>
        Some((old_index, new_index))
    }
  }

  self.ops.sort_by(fn(a : DiffOp, b : DiffOp) -> Int {
    let (a_old, a_new) = get_old_new_index(a).unwrap()
    let (b_old, b_new) = get_old_new_index(b).unwrap()
    if a_old == b_old {
      // When old positions match, prioritize deletes for consistent output
      match (a, b) {
        (Delete(..), Delete(..)) => a_new - b_new
        (Delete(..), _) => -1
        (_, Delete(..)) => 1
        _ => a_new - b_new
      }
    } else {
      a_old - b_old
    }
  })
}

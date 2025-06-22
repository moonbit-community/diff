///| a more compact diff result 
pub(all) struct Compact[D, T] {
  d : D
  ops : Array[DiffOp]
  old : Array[T]
  new : Array[T]
}

///|
pub fn[D : DiffHook, T] Compact::new(
  d : D,
  old : Array[T],
  new : Array[T]
) -> Compact[D, T] {
  { d, ops: Array::new(), old, new }
}

///|
pub fn[D : DiffHook, T] Compact::into_inner(self : Compact[D, T]) -> D {
  self.d
}

///|
pub fn[D, T] Compact::into_ops(self : Compact[D, T]) -> Array[DiffOp] {
  self.ops
}

///|
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with equal(
  self,
  old_index,
  new_index,
  len
) -> Result[Unit, Error] {
  self.ops.push(DiffOp::Equal(old_index~, new_index~, len~))
  Ok(())
}

///|
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with delete(
  self,
  old_index,
  old_len,
  new_index
) -> Result[Unit, Error] {
  self.ops.push(DiffOp::Delete(old_index~, old_len~, new_index~))
  Ok(())
}

///|
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with insert(
  self,
  old_index,
  new_index,
  new_len
) -> Result[Unit, Error] {
  self.ops.push(DiffOp::Insert(old_index~, new_index~, new_len~))
  Ok(())
}

///|
pub impl[D : DiffHook, T : Eq] DiffHook for Compact[D, T] with finish(self) -> Result[
  Unit,
  Error,
] {
  cleanup_diff_ops(self.old, self.new, self.ops)
  for op in self.ops {
    let _ = op.apply_to_hook(self.d)

  }
  self.d.finish()
}

///|
pub fn[T : Eq] cleanup_diff_ops(
  old : Array[T],
  new : Array[T],
  ops : Array[DiffOp]
) -> Unit {
  let mut pointer = 0
  while pointer < ops.length() {
    let op = ops.get(pointer).unwrap()
    match op {
      DiffOp::Insert(..) => {
        pointer = shift_diff_ops_up(ops, old, new, pointer)
        pointer = shift_diff_ops_down(ops, old, new, pointer)
      }
      _ => ()
    }
    pointer += 1
  }
  let mut pointer = 0
  while pointer < ops.length() {
    let op = ops.get(pointer).unwrap()
    match op {
      DiffOp::Delete(..) => {
        pointer = shift_diff_ops_up(ops, old, new, pointer)
        pointer = shift_diff_ops_down(ops, old, new, pointer)
      }
      _ => ()
    }
    pointer += 1
  }
}

///| Find Common Suffix between equal with insert/delete ops

///| try to shift insert/delete ops upwards to merge with equal ops
pub fn[T : Eq] shift_diff_ops_up(
  ops : Array[DiffOp],
  old : Array[T],
  new : Array[T],
  pointer : Int
) -> Int {
  let mut pointer = pointer
  while pointer > 1 {
    let prev_op = ops[pointer - 1]
    let this_op = ops[pointer]
    match (this_op, prev_op) {

      // swap delete and insert
      (DiffOp::Insert(..), DiffOp::Delete(..))
      | (DiffOp::Delete(..), DiffOp::Insert(..)) => {
        ops.swap(pointer - 1, pointer)
        pointer -= 1
      }
      // merge  
      (DiffOp::Insert(..), DiffOp::Insert(..)) => {
        ops[pointer - 1].grow_right(this_op.new_range().len())
        let _ = ops.remove(pointer)
        pointer -= 1
      }
      (DiffOp::Delete(..), DiffOp::Delete(..)) => {
        ops[pointer - 1].grow_right(this_op.old_range().len())
        let _ = ops.remove(pointer)
        pointer -= 1
      }
      // Shift Inserts Upwards 
      (DiffOp::Insert(..), DiffOp::Equal(..)) => {
        // Insert means adding some items to "new"
        let suffix_len = common_suffix_len(
          new,
          prev_op.new_range(),
          new,
          this_op.new_range(),
        )
        if suffix_len > 0 {
          // merge/add new equal op 
          match ops.get(pointer + 1) {
            Some(DiffOp::Equal(..) as next_op) => next_op.grow_left(suffix_len)
            _ => {
              let old_index = this_op.old_range().end - suffix_len
              let new_index = this_op.new_range().end - suffix_len
              let len = suffix_len
              ops.insert(
                pointer + 1,
                DiffOp::Equal(old_index~, new_index~, len~),
              )
            }
          }
          // update this_op and prev_op 
          this_op.shift_left(suffix_len)
          prev_op.shrink_left(suffix_len)
          if prev_op.is_empty() {
            let _ = ops.remove(pointer - 1)
            pointer -= 1
          }
        } else if ops[pointer - 1].is_empty() {
          let _ = ops.remove(pointer - 1)
          pointer -= 1
        } else {
          // can't shift anymore
          break
        }
      }

      // Shift Deletes Upwards 
      (DiffOp::Delete(..), DiffOp::Equal(..)) => {
        // Delete means removing some items from "old"
        let suffix_len = common_suffix_len(
          old,
          prev_op.old_range(),
          old,
          this_op.old_range(),
        )
        if suffix_len > 0 {
          // merge/add new equal op 
          match ops.get(pointer + 1) {
            Some(DiffOp::Equal(..) as next_op) => next_op.grow_left(suffix_len)
            _ => {
              let old_index = this_op.old_range().end - suffix_len
              let new_index = this_op.new_range().end - suffix_len
              let len = suffix_len
              ops.insert(
                pointer + 1,
                DiffOp::Equal(old_index~, new_index~, len~),
              )
            }
          }
          this_op.shift_left(suffix_len)
          prev_op.shrink_left(suffix_len)
          if prev_op.is_empty() {
            let _ = ops.remove(pointer - 1)
            pointer -= 1
          }
        } else if ops[pointer - 1].is_empty() {
          let _ = ops.remove(pointer - 1)
          pointer -= 1
        } else {
          // can't shift anymore
          break
        }
      }
      _ => break
    }
  }
  pointer
}

///|
pub fn[T : Eq] shift_diff_ops_down(
  ops : Array[DiffOp],
  old : Array[T],
  new : Array[T],
  pointer : Int
) -> Int {
  let mut pointer = pointer
  while pointer < ops.length() - 1 {
    let next_op = ops[pointer + 1]
    let this_op = ops[pointer]
    match (this_op, next_op) {

      // swap delete and insert
      (DiffOp::Insert(..), DiffOp::Delete(..))
      | (DiffOp::Delete(..), DiffOp::Insert(..)) => {
        ops.swap(pointer, pointer + 1)
        pointer += 1
      }
      // merge  
      (DiffOp::Insert(..), DiffOp::Insert(..)) => {
        this_op.grow_right(next_op.new_range().len())
        let _ = ops.remove(pointer + 1)

      }
      (DiffOp::Delete(..), DiffOp::Delete(..)) => {
        this_op.grow_right(next_op.old_range().len())
        let _ = ops.remove(pointer + 1)

      }
      // Shift Inserts Upwards 
      (DiffOp::Insert(..), DiffOp::Equal(..)) => {
        // Insert means adding some items to "new"
        let prefix_len = common_prefix_len(
          new,
          next_op.new_range(),
          new,
          this_op.new_range(),
        )
        if prefix_len > 0 {
          // merge/add new equal op 
          match ops.get(pointer - 1) {
            Some(DiffOp::Equal(..) as prev_op) => prev_op.grow_right(prefix_len)
            _ => {
              let old_index = this_op.old_range().start
              let new_index = next_op.new_range().start
              let len = prefix_len
              ops.insert(pointer, DiffOp::Equal(old_index~, new_index~, len~))
              pointer += 1
            }
          }
          // update this_op and prev_op 
          this_op.shift_right(prefix_len)
          next_op.shrink_right(prefix_len)
          if next_op.is_empty() {
            let _ = ops.remove(pointer + 1)

          }
        } else if ops[pointer + 1].is_empty() {
          let _ = ops.remove(pointer + 1)

        } else {
          // can't shift anymore
          break
        }
      }

      // Shift Deletes Upwards 
      (DiffOp::Delete(..), DiffOp::Equal(..)) => {
        // Delete means removing some items from "old"
        let prefix_len = common_prefix_len(
          old,
          next_op.old_range(),
          old,
          this_op.old_range(),
        )
        if prefix_len > 0 {
          // merge/add new equal op 
          match ops.get(pointer - 1) {
            Some(DiffOp::Equal(..) as prev_op) => prev_op.grow_right(prefix_len)
            _ => {
              let old_index = this_op.old_range().start
              let new_index = this_op.new_range().start
              let len = prefix_len
              ops.insert(pointer, DiffOp::Equal(old_index~, new_index~, len~))
              pointer += 1
            }
          }
          this_op.shift_left(prefix_len)
          next_op.shrink_left(prefix_len)
          if next_op.is_empty() {
            let _ = ops.remove(pointer + 1)

          }
        } else if ops[pointer + 1].is_empty() {
          let _ = ops.remove(pointer + 1)

        } else {
          // can't shift anymore
          break
        }
      }
      _ => break
    }
  }
  pointer
}

///|
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

///| A DiffHook that captures all diff operations.

///| It stores a sequence of `DiffOp` as they are reported.
type Capture Array[DiffOp] derive(Default)

///| Creates a new, empty `Capture` hook.
pub fn Capture::new() -> Capture {
  Capture::default()
}

///| Consumes the `Capture` hook and returns the captured operations.
pub fn Capture::into_ops(self : Capture) -> Array[DiffOp] {
  self.inner()
}

///| Returns an iterator over the captured operations.
pub fn Capture::to_iter(self : Capture) -> Iter[DiffOp] {
  self.inner().iter()
}

///| Returns a reference to the captured operations.
pub fn Capture::ops(self : Capture) -> Array[DiffOp] {
  self.inner()
}

///| Captures an `Equal` operation.
pub impl DiffHook for Capture with equal(
  self : Capture,
  old_index : Int,
  new_index : Int,
  len : Int,
) -> Result[Unit, Error] {
  self.inner().push(DiffOp::Equal(old_index~, new_index~, len~))
  Ok(())
}

///| Captures a `Delete` operation.
pub impl DiffHook for Capture with delete(
  self : Capture,
  old_index : Int,
  old_len : Int,
  new_index : Int,
) -> Result[Unit, Error] {
  self.inner().push(DiffOp::Delete(old_index~, old_len~, new_index~))
  Ok(())
}

///| Captures an `Insert` operation.
pub impl DiffHook for Capture with insert(
  self : Capture,
  old_index : Int,
  new_index : Int,
  new_len : Int,
) -> Result[Unit, Error] {
  self.inner().push(DiffOp::Insert(old_index~, new_index~, new_len~))
  Ok(())
}

///| Captures a `Replace` operation.
pub impl DiffHook for Capture with replace(
  self : Capture,
  old_index : Int,
  old_len : Int,
  new_index : Int,
  new_len : Int,
) -> Result[Unit, Error] {
  self.inner().push(DiffOp::Replace(old_index~, old_len~, new_index~, new_len~))
  Ok(())
}

///| Sorts the captured operations when the diff is finished.
pub impl DiffHook for Capture with finish(self : Capture) -> Result[Unit, Error] {
  self.sort()
  Ok(())
}

///| Sorts the captured operations to ensure a consistent order.

///| This is useful because some algorithms might report operations out of order.
pub fn Capture::sort(self : Capture) -> Unit {
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

  self
  .inner()
  .sort_by(fn(a : DiffOp, b : DiffOp) -> Int {
    let (a_old, a_new) = get_old_new_index(a).unwrap()
    let (b_old, b_new) = get_old_new_index(b).unwrap()
    if a_old == b_old {
      // If old indices are the same, `Delete` should come before other operations. (for Replace style result)
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

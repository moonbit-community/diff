///| A DiffHook that captures all diff operations
type Capture Array[DiffOp] derive(Default)

///|
pub fn Capture::new() -> Capture {
  Capture::default()
}

///|
pub fn Capture::into_ops(self : Capture) -> Array[DiffOp] {
  self._
}

///|
pub fn Capture::to_iter(self : Capture) -> Iter[DiffOp] {
  self._.iter()
}

///|
pub fn Capture::ops(self : Capture) -> Array[DiffOp] {
  self._
}

///|
pub impl DiffHook for Capture with equal(
  self : Capture,
  old_index : Int,
  new_index : Int,
  len : Int
) -> Result[Unit, Error] {
  self._.push(DiffOp::Equal(old_index~, new_index~, len~))
  Ok(())
}

///|
pub impl DiffHook for Capture with delete(
  self : Capture,
  old_index : Int,
  old_len : Int,
  new_index : Int
) -> Result[Unit, Error] {
  self._.push(DiffOp::Delete(old_index~, old_len~, new_index~))
  Ok(())
}

///|
pub impl DiffHook for Capture with insert(
  self : Capture,
  old_index : Int,
  new_index : Int,
  new_len : Int
) -> Result[Unit, Error] {
  self._.push(DiffOp::Insert(old_index~, new_index~, new_len~))
  Ok(())
}

///|
pub impl DiffHook for Capture with replace(
  self : Capture,
  old_index : Int,
  old_len : Int,
  new_index : Int,
  new_len : Int
) -> Result[Unit, Error] {
  self._.push(DiffOp::Replace(old_index~, old_len~, new_index~, new_len~))
  Ok(())
}

///|
pub impl DiffHook for Capture with finish(self : Capture) -> Result[Unit, Error] {
  self.sort()
  Ok(())
}

///|
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
      DiffOp::Finish => None
    }
  }

  self._.sort_by(fn(a : DiffOp, b : DiffOp) -> Int {
    match a {
      DiffOp::Finish => -1
      _ => {
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
      }
    }
  })
}

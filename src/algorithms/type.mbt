///| 
pub(all) enum DiffOp {
  Equal(mut old_index~ : Int, mut new_index~ : Int, mut len~ : Int)
  Delete(mut old_index~ : Int, mut old_len~ : Int, mut new_index~ : Int)
  Insert(mut old_index~ : Int, mut new_index~ : Int, mut new_len~ : Int)
  Replace(
    mut old_index~ : Int,
    mut old_len~ : Int,
    mut new_index~ : Int,
    mut new_len~ : Int
  )
} derive(Eq, Show, Hash, Compare)

///|
pub fn[D : DiffHook] DiffOp::apply_to_hook(
  self : Self,
  d : D
) -> Result[Unit, Error] {
  match self {
    Equal(old_index~, new_index~, len~) => d.equal(old_index, new_index, len)
    Delete(old_index~, old_len~, new_index~) =>
      d.delete(old_index, old_len, new_index)
    Insert(old_index~, new_index~, new_len~) =>
      d.insert(old_index, new_index, new_len)
    Replace(old_index~, old_len~, new_index~, new_len~) =>
      d.replace(old_index, old_len, new_index, new_len)
  }
}

///|
pub fn DiffOp::old_range(self : Self) -> Range {
  match self {
    Equal(old_index~, new_index=_, len~) =>
      Range::new(old_index, old_index + len)
    Delete(old_index~, old_len~, new_index=_) =>
      Range::new(old_index, old_index + old_len)
    Insert(old_index~, new_index=_, new_len=_) =>
      Range::new(old_index, old_index)
    Replace(old_index~, old_len~, new_index=_, new_len=_) =>
      Range::new(old_index, old_index + old_len)
  }
}

///|
pub fn DiffOp::new_range(self : Self) -> Range {
  match self {
    Equal(old_index=_, new_index~, len~) =>
      Range::new(new_index, new_index + len)
    Delete(old_index=_, old_len=_, new_index~) =>
      Range::new(new_index, new_index)
    Insert(old_index=_, new_index~, new_len~) =>
      Range::new(new_index, new_index + new_len)
    Replace(old_index=_, old_len=_, new_index~, new_len~) =>
      Range::new(new_index, new_index + new_len)
  }
}

///|
pub fn DiffOp::is_empty(self : Self) -> Bool {
  self.old_range().is_empty() && self.new_range().is_empty()
}

///|
pub fn DiffOp::shift_left(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, true), (0, false))
}

///|
pub fn DiffOp::shift_right(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, false), (0, false))
}

///|
pub fn DiffOp::grow_left(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, true), (adjust, false))
}

///|
pub fn DiffOp::grow_right(self : Self, adjust : Int) -> Unit {
  self.adjust((0, false), (adjust, false))
}

///|
pub fn DiffOp::shrink_left(self : Self, adjust : Int) -> Unit {
  self.adjust((0, false), (adjust, false))
}

///|
pub fn DiffOp::shrink_right(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, false), (adjust, true))
}

///|
fn DiffOp::adjust(
  self : Self,
  adjust_offset : (Int, Bool),
  adjust_len : (Int, Bool)
) -> Unit {
  // false means grow, true means shrink
  fn modify(val : Int, adjust : (Int, Bool)) -> Int {
    if adjust.1 {
      val - adjust.0
    } else {
      val + adjust.0
    }
  }

  match self {
    DiffOp::Equal(old_index~, new_index~, len~) as op => {
      op.old_index = modify(old_index, adjust_offset)
      op.new_index = modify(new_index, adjust_offset)
      op.len = modify(len, adjust_len)
    }
    DiffOp::Delete(old_index~, old_len~, new_index~) as op => {
      op.old_index = modify(old_index, adjust_offset)
      op.old_len = modify(old_len, adjust_len)
      op.new_index = modify(new_index, adjust_offset)
    }
    DiffOp::Insert(old_index~, new_index~, new_len~) as op => {
      op.old_index = modify(old_index, adjust_offset)
      op.new_index = modify(new_index, adjust_offset)
      op.new_len = modify(new_len, adjust_len)
    }
    DiffOp::Replace(old_index~, old_len~, new_index~, new_len~) as op => {
      op.old_index = modify(old_index, adjust_offset)
      op.old_len = modify(old_len, adjust_len)
      op.new_index = modify(new_index, adjust_offset)
      op.new_len = modify(new_len, adjust_len)
    }
  }
}

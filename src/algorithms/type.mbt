///|
/// Represents the different types of operations in a diff.
pub(all) enum DiffOp {
  /// A sequence of items that are the same in both versions.
  Equal(mut old_index~ : Int, mut new_index~ : Int, mut len~ : Int)
  /// A sequence of items that were deleted from the old version.
  Delete(mut old_index~ : Int, mut old_len~ : Int, mut new_index~ : Int)
  /// A sequence of items that were inserted in the new version.
  Insert(mut old_index~ : Int, mut new_index~ : Int, mut new_len~ : Int)
  /// A sequence of items that were replaced.
  Replace(
    mut old_index~ : Int,
    mut old_len~ : Int,
    mut new_index~ : Int,
    mut new_len~ : Int
  )
} derive(Eq, Show, Hash, Compare)

///|
/// Applies the given `DiffOp` to a `DiffHook`.
pub fn[D : DiffHook] DiffOp::apply_to_hook(
  self : Self,
  d : D,
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
/// Returns the range of the operation in the old sequence.
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
/// Returns the range of the operation in the new sequence.
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
/// Checks if the operation is empty (i.e., has a length of zero).
pub fn DiffOp::is_empty(self : Self) -> Bool {
  self.old_range().is_empty() && self.new_range().is_empty()
}

///| Shifts the operation to the left by a given amount.

///|
/// Used by the `Compact` hook to merge operations.
pub fn DiffOp::shift_left(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, true), (0, false))
}

///| Shifts the operation to the right by a given amount.

///|
/// Used by the `Compact` hook to merge operations.
pub fn DiffOp::shift_right(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, false), (0, false))
}

///| Grows the operation to the left by a given amount.

///|
/// Used by the `Compact` hook to merge operations.
pub fn DiffOp::grow_left(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, true), (adjust, false))
}

///| Grows the operation to the right by a given amount.

///|
/// Used by the `Compact` hook to merge operations.
pub fn DiffOp::grow_right(self : Self, adjust : Int) -> Unit {
  self.adjust((0, false), (adjust, false))
}

///| Shrinks the operation from the left by a given amount.

///|
/// Used by the `Compact` hook to merge operations.
pub fn DiffOp::shrink_left(self : Self, adjust : Int) -> Unit {
  self.adjust((0, false), (adjust, false))
}

///| Shrinks the operation from the right by a given amount.

///|
/// Used by the `Compact` hook to merge operations.
pub fn DiffOp::shrink_right(self : Self, adjust : Int) -> Unit {
  self.adjust((adjust, false), (adjust, true))
}

///| Helper function to adjust the offsets and lengths of an operation.

///|
/// false means grow, true means shrink
fn DiffOp::adjust(
  self : Self,
  adjust_offset : (Int, Bool),
  adjust_len : (Int, Bool),
) -> Unit {
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

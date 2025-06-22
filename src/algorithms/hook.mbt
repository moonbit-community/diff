///| The `DiffHook` trait defines a set of callbacks for handling diff operations.

///| Different hooks can be implemented to process or store the diff results.
pub(open) trait DiffHook {
  ///| Called when a sequence of equal items is found.
  equal(Self, old_index : Int, new_index : Int, len : Int) -> Result[
    Unit,
    Error,
  ] = _
  ///| Called when a sequence of items is deleted from the old sequence.
  delete(Self, old_index : Int, old_len : Int, new_index : Int) -> Result[
    Unit,
    Error,
  ] = _
  ///| Called when a sequence of items is inserted into the new sequence.
  insert(Self, old_index : Int, new_index : Int, new_len : Int) -> Result[
    Unit,
    Error,
  ] = _
  ///| Called when a sequence of items is replaced.
  replace(Self, old_index : Int, old_len : Int, new_index : Int, new_len : Int) -> Result[
    Unit,
    Error,
  ] = _
  ///| Called when the diffing process is complete.
  finish(Self) -> Result[Unit, Error] = _
}

///| Default implementation for `equal`.
impl DiffHook with equal(
  _self : Self,
  _old_index : Int,
  _new_index : Int,
  _len : Int
) -> Result[Unit, Error] {
  Ok(())
}

///| Default implementation for `delete`.
impl DiffHook with delete(
  _self : Self,
  _old_index : Int,
  _old_len : Int,
  _new_index : Int
) -> Result[Unit, Error] {
  Ok(())
}

///| Default implementation for `insert`.
impl DiffHook with insert(
  _self : Self,
  _old_index : Int,
  _new_index : Int,
  _new_len : Int
) -> Result[Unit, Error] {
  Ok(())
}

///| Default implementation for `replace`.
impl DiffHook with replace(
  _self : Self,
  _old_index : Int,
  _old_len : Int,
  _new_index : Int,
  _new_len : Int
) -> Result[Unit, Error] {
  Ok(())
}

///| Default implementation for `finish`.
impl DiffHook with finish(_self : Self) -> Result[Unit, Error] {
  Ok(())
}

///| A hook that wraps another `DiffHook` but ignores the `finish` call.

///| This is useful for chaining hooks where only the outermost hook's `finish` should be called.
pub(all) struct NoFinishHook[D] {
  d : D
}

///| Creates a new `NoFinishHook`.
pub fn[D] NoFinishHook::new(d : D) -> NoFinishHook[D] {
  NoFinishHook::{ d, }
}

///| Consumes the `NoFinishHook` and returns the inner hook.
pub fn[D] NoFinishHook::into_inner(self : NoFinishHook[D]) -> D {
  self.d
}

///| Forwards the `equal` call to the inner hook.
impl[D : DiffHook] DiffHook for NoFinishHook[D] with equal(
  self,
  old_index,
  new_index,
  len
) {
  self.d.equal(old_index, new_index, len)
}

///| Forwards the `delete` call to the inner hook.
impl[D : DiffHook] DiffHook for NoFinishHook[D] with delete(
  self,
  old_index,
  old_len,
  new_index
) {
  self.d.delete(old_index, old_len, new_index)
}

///| Forwards the `insert` call to the inner hook.
impl[D : DiffHook] DiffHook for NoFinishHook[D] with insert(
  self,
  old_index,
  new_index,
  new_len
) {
  self.d.insert(old_index, new_index, new_len)
}

///| Forwards the `replace` call to the inner hook.
impl[D : DiffHook] DiffHook for NoFinishHook[D] with replace(
  self,
  old_index,
  old_len,
  new_index,
  new_len
) {
  self.d.replace(old_index, old_len, new_index, new_len)
}

///| Ignores the `finish` call.
impl[D : DiffHook] DiffHook for NoFinishHook[D] with finish(_self) {
  Ok(())
}

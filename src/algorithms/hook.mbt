///|
pub(open) trait DiffHook {
  equal(Self, old_index : Int, new_index : Int, len : Int) -> Result[
    Unit,
    Error,
  ] = _
  delete(Self, old_index : Int, old_len : Int, new_index : Int) -> Result[
    Unit,
    Error,
  ] = _
  insert(Self, old_index : Int, new_index : Int, new_len : Int) -> Result[
    Unit,
    Error,
  ] = _
  replace(Self, old_index : Int, old_len : Int, new_index : Int, new_len : Int) -> Result[
    Unit,
    Error,
  ] = _
  finish(Self) -> Result[Unit, Error] = _
}

///|
impl DiffHook with equal(
  _self : Self,
  _old_index : Int,
  _new_index : Int,
  _len : Int
) -> Result[Unit, Error] {
  Ok(())
}

///|
impl DiffHook with delete(
  _self : Self,
  _old_index : Int,
  _old_len : Int,
  _new_index : Int
) -> Result[Unit, Error] {
  Ok(())
}

///|
impl DiffHook with insert(
  _self : Self,
  _old_index : Int,
  _new_index : Int,
  _new_len : Int
) -> Result[Unit, Error] {
  Ok(())
}

///|
impl DiffHook with replace(
  _self : Self,
  _old_index : Int,
  _old_len : Int,
  _new_index : Int,
  _new_len : Int
) -> Result[Unit, Error] {
  Ok(())
}

///|
impl DiffHook with finish(_self : Self) -> Result[Unit, Error] {
  Ok(())
}

///|
pub(all) struct NoFinishHook[D] {
  d : D
}

///|
pub fn[D] NoFinishHook::new(d : D) -> NoFinishHook[D] {
  NoFinishHook::{ d, }
}

///|
pub fn[D] NoFinishHook::into_inner(self : NoFinishHook[D]) -> D {
  self.d
}

///|
impl[D : DiffHook] DiffHook for NoFinishHook[D] with equal(
  self,
  old_index,
  new_index,
  len
) {
  self.d.equal(old_index, new_index, len)
}

///|
impl[D : DiffHook] DiffHook for NoFinishHook[D] with delete(
  self,
  old_index,
  old_len,
  new_index
) {
  self.d.delete(old_index, old_len, new_index)
}

///|
impl[D : DiffHook] DiffHook for NoFinishHook[D] with insert(
  self,
  old_index,
  new_index,
  new_len
) {
  self.d.insert(old_index, new_index, new_len)
}

///|
impl[D : DiffHook] DiffHook for NoFinishHook[D] with replace(
  self,
  old_index,
  old_len,
  new_index,
  new_len
) {
  self.d.replace(old_index, old_len, new_index, new_len)
}

///|
impl[D : DiffHook] DiffHook for NoFinishHook[D] with finish(_self) {
  Ok(())
}

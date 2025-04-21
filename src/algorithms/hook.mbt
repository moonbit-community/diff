///|
pub(open) trait DiffHook {
  equal(Self, old_index : Int, new_index : Int, len : Int) ->
       Result[Unit, Error] = _
  delete(Self, old_index : Int, old_len : Int, new_index : Int) ->
       Result[Unit, Error] = _
  insert(Self, old_index : Int, new_index : Int, new_len : Int) ->
       Result[Unit, Error] = _
  replace(Self, old_index : Int, old_len : Int, new_index : Int, new_len : Int) ->
       Result[Unit, Error] = _
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

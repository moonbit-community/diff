///| A `DiffHook` that merges adjacent `Insert` and `Delete` operations

///| into a single `Replace` operation.
pub(all) struct Replace[D] {
  // The inner diff hook to which operations are reported.
  d : D
  // A pending delete operation, if any.
  mut del : (Int, Int, Int)?
  // A pending insert operation, if any.
  mut ins : (Int, Int, Int)?
  // A pending equal operation, if any.
  mut eq : (Int, Int, Int)?
}

///| Creates a new `Replace` hook.
pub fn[D] Replace::new(d : D) -> Replace[D] {
  { d, del: None, ins: None, eq: None }
}

///| Consumes the `Replace` hook and returns the inner hook.
pub fn[D] Replace::into_inner(self : Replace[D]) -> D {
  self.d
}

///| Flushes any pending `Equal` operation to the inner hook.
pub fn[D : DiffHook] Replace::flush_eq(
  self : Replace[D]
) -> Result[Unit, Error] {
  match self.eq {
    Some((old_index, new_index, len)) => {
      self.eq = None
      self.d.equal(old_index, new_index, len)
    }
    None => Ok(())
  }
}

///| Flushes any pending `Delete` and `Insert` operations to the inner hook.

///| If both are present, they are merged into a `Replace` operation.
pub fn[D : DiffHook] Replace::flush_del_ins(
  self : Replace[D]
) -> Result[Unit, Error] {
  match self.del {
    Some((del_old_index, del_len, del_new_index)) => {
      self.del = None
      match self.ins {
        Some((_, ins_new_index, ins_len)) => {
          self.ins = None
          self.d.replace(del_old_index, del_len, ins_new_index, ins_len)
        }
        None => self.d.delete(del_old_index, del_len, del_new_index)
      }
    }
    None =>
      match self.ins {
        Some((ins_old_index, ins_new_index, ins_len)) => {
          self.ins = None
          self.d.insert(ins_old_index, ins_new_index, ins_len)
        }
        None => Ok(())
      }
  }
}

///| Handles an `Equal` operation.

///| It flushes any pending insert/delete ops and merges consecutive equal ops.
pub impl[D : DiffHook] DiffHook for Replace[D] with equal(
  self,
  old_index,
  new_index,
  len
) {
  let _ = self.flush_del_ins()
  self.eq = match self.eq {
    Some((eq_old_index, eq_new_index, eq_len)) =>
      Some((eq_old_index, eq_new_index, eq_len + len))
    None => Some((old_index, new_index, len))
  }
  Ok(())
}

///| Handles a `Delete` operation.

///| It flushes any pending equal ops and merges consecutive delete ops.
pub impl[D : DiffHook] DiffHook for Replace[D] with delete(
  self,
  old_index,
  old_len,
  new_index
) {
  let _ = self.flush_eq()
  match self.del {
    Some((del_old_index, del_old_len, del_new_index)) =>
      self.del = Some((del_old_index, del_old_len + old_len, del_new_index))
    None => self.del = Some((old_index, old_len, new_index))
  }
  Ok(())
}

///| Handles an `Insert` operation.

///| It flushes any pending equal ops and merges consecutive insert ops.
pub impl[D : DiffHook] DiffHook for Replace[D] with insert(
  self,
  old_index,
  new_index,
  new_len
) {
  let _ = self.flush_eq()
  match self.ins {
    Some((ins_old_index, ins_new_index, ins_len)) =>
      self.ins = Some((ins_old_index, ins_new_index, ins_len + new_len))
    None => self.ins = Some((old_index, new_index, new_len))
  }
  Ok(())
}

///| Handles a `Replace` operation.

///| It flushes any pending operations and forwards the replace to the inner hook.
pub impl[D : DiffHook] DiffHook for Replace[D] with replace(
  self,
  old_index,
  old_len,
  new_index,
  new_len
) {
  let _ = self.flush_eq()
  let _ = self.flush_del_ins()
  self.d.replace(old_index, old_len, new_index, new_len)
}

///| Finishes the diffing process by flushing any remaining pending operations.
pub impl[D : DiffHook] DiffHook for Replace[D] with finish(self) {
  let _ = self.flush_eq()
  let _ = self.flush_del_ins()
  self.d.finish()
}

///| A test for the `Replace` hook with the Myers algorithm.
test "test_myers_replace" {
  let a = [
    ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n", "a\n", "b\n", "c\n", "================================\n",
    "d\n", "e\n", "f\n", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n",
  ]
  let b = [
    ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n", "x\n", "b\n", "c\n", "================================\n",
    "y\n", "e\n", "f\n", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n",
  ]
  let capture = Capture::new()
  let d = Replace::new(capture)
  let _ = Myers::diff(
    d,
    a,
    Range::new(0, a.length()),
    b,
    Range::new(0, b.length()),
  )
  let ops = capture.ops()
  inspect(
    ops,
    content="[Equal(old_index=0, new_index=0, len=1), Replace(old_index=1, old_len=1, new_index=1, new_len=1), Equal(old_index=2, new_index=2, len=3), Replace(old_index=5, old_len=1, new_index=5, new_len=1), Equal(old_index=6, new_index=6, len=3)]",
  )
}

///| Another test for the `Replace` hook.
test "test_replace" {
  let a = [0, 1, 2, 3, 4]
  let b = [0, 1, 2, 7, 8, 9]
  let capture = Capture::new()
  let d = Replace::new(capture)
  let _ = Myers::diff(
    d,
    a,
    Range::new(0, a.length()),
    b,
    Range::new(0, b.length()),
  )
  let ops = capture.ops()
  inspect(
    ops,
    content="[Equal(old_index=0, new_index=0, len=3), Replace(old_index=3, old_len=2, new_index=3, new_len=3)]",
  )
}

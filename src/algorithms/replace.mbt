
pub(all) struct Replace[D] {
  d: D
  mut del: (Int, Int, Int)?
  mut ins: (Int, Int, Int)?
  mut eq: (Int, Int, Int)?
}

pub fn Replace::new[D: DiffHook](d: D) -> Replace[D] {
  { d, del: None, ins: None, eq: None }
}

pub fn Replace::into_inner[D: DiffHook](self: Replace[D]) -> D {
  self.d
}

pub fn Replace::flush_eq[D: DiffHook](self: Replace[D]) -> Result[Unit, Error] {
  match self.eq {
    Some((old_index, new_index, len)) => {
      self.eq = None
      self.d.equal(old_index, new_index, len)
    }
    None => Ok(())
  }
}

pub fn Replace::flush_del_ins[D: DiffHook](self: Replace[D]) -> Result[Unit, Error] {
  match self.del {
    Some((del_old_index, del_len, del_new_index)) => {
      self.del = None
      match self.ins {
        Some((_, ins_new_index, ins_len)) => {
          self.ins = None
          self.d.replace(del_old_index, del_len, ins_new_index, ins_len)
        }
        None => {
          self.d.delete(del_old_index, del_len, del_new_index)
        }
      }
    }
    None => {
      match self.ins {
        Some((ins_old_index, ins_new_index, ins_len)) => {
          self.ins = None
          self.d.insert(ins_old_index, ins_new_index, ins_len)
        }
        None => Ok(())
      }
    }
  }
}


pub impl DiffHook for Replace[&DiffHook] with equal(self, old_index, new_index, len) {
  let _ = self.flush_del_ins()
  self.eq = match self.eq {
    Some((eq_old_index, eq_new_index, eq_len)) => {
      Some((eq_old_index, eq_new_index, eq_len + len))
    }
    None => {
      Some((old_index, new_index, len))
    }
  }

  Ok(())
}


pub impl DiffHook for Replace[&DiffHook] with delete(self, old_index, old_len, new_index) {
  let _ = self.flush_eq() 

  match self.del {
    Some((del_old_index, del_old_len, del_new_index)) => {
      self.del = Some((del_old_index, del_old_len + old_len, del_new_index))
    }
    None => {
      self.del = Some((old_index, old_len, new_index))
    }
  }

  Ok(())
}

pub impl DiffHook for Replace[&DiffHook] with insert(self, old_index, new_index, new_len) {
  let _ = self.flush_eq()

  match self.ins {
    Some((ins_old_index, ins_new_index, ins_len)) => {
      self.ins = Some((ins_old_index, ins_new_index, ins_len + new_len))
    }
    None => {
      self.ins = Some((old_index, new_index, new_len))
    }
  }

  Ok(())
}


pub impl DiffHook for Replace[&DiffHook] with replace(self, old_index, old_len, new_index, new_len) {
  let _ = self.flush_eq()
  let _ = self.flush_del_ins()
  self.d.replace(old_index, old_len, new_index, new_len)
}


pub impl DiffHook for Replace[&DiffHook] with finish(self) {
  let _ = self.flush_eq()
  let _ = self.flush_del_ins()
  self.d.finish()
}


test "test_myers_replace" {
  let a = [">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n",
        "a\n",
        "b\n",
        "c\n",
        "================================\n",
        "d\n",
        "e\n",
        "f\n",
        "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n",
    ]
  let b = [
        ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n",
        "x\n",
        "b\n",
        "c\n",
        "================================\n",
        "y\n",
        "e\n",
        "f\n",
        "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n",
    ]
  
  let capture = Capture::new()
  let d = Replace::new(capture as &DiffHook)
  let _ = Myers::diff(d, a, Range::new(0, a.length()), b, Range::new(0, b.length()))

  println(capture.ops())
}

test "test_replace" {
  let a = [0, 1, 2, 3, 4]
  let b = [0, 1, 2, 7, 8, 9]
  let capture = Capture::new()
  let d = Replace::new(capture as &DiffHook)
  let _ = Myers::diff(d, a, Range::new(0, a.length()), b, Range::new(0, b.length()))

  println(capture.ops())
}
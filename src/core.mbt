///|
typealias @algorithms.Range

///|
typealias @algorithms.DiffOp

///|
pub fn diff[T : Eq](old : Array[T], new : Array[T]) -> Array[DiffOp] {
  let d = @algorithms.Replace::new(@algorithms.Capture::new())
  let _ = @algorithms.Myers::diff(
    d,
    old,
    Range::new(0, old.length()),
    new,
    Range::new(0, new.length()),
  )
  d.into_inner().into_ops()
}

///|
pub fn diff_str(old : String, new : String) -> Array[DiffOp] {
  diff(old.to_array(), new.to_array())
}

///|
pub fn diff_line(old : Array[String], new : Array[String]) -> Array[DiffOp] {
  diff(old, new)
}

///|
pub fn print_diff_line(old : Array[String], new : Array[String]) -> Unit {
  let ops = diff(old, new)
  print_diff_ops(old, new, ops)
}

///|
pub fn print_diff_ops[T : Show](
  old : Array[T],
  new : Array[T],
  ops : Array[DiffOp]
) -> Unit {
  for op in ops {
    match op {
      DiffOp::Equal(old_index~, new_index=_, len~) => {
        let mut i = 0
        while i < len {
          println("   \{old[old_index + i]}")
          i += 1
        }
      }
      DiffOp::Delete(old_index~, old_len~, new_index=_) => {
        let mut i = 0
        while i < old_len {
          println(" - \{old[old_index + i]}")
          i += 1
        }
      }
      DiffOp::Insert(old_index=_, new_index~, new_len~) => {
        let mut i = 0
        while i < new_len {
          println(" + \{new[new_index + i]}")
          i += 1
        }
      }
      DiffOp::Replace(old_index~, old_len~, new_index~, new_len~) => {
        let mut i = 0
        while i < old_len {
          println(" - \{old[old_index + i]}")
          i += 1
        }
        i = 0
        while i < new_len {
          println(" + \{new[new_index + i]}")
          i += 1
        }
      }
      DiffOp::Finish => break
    }
  }
}

///|
test "test_diff" {
  let a = [1, 2, 3, 4, 5, 8, 9]
  let b = [1, 2, 0, 4, 5, 6, 7]
  let diffs = diff(a, b)
  inspect!(
    diffs,
    content="[Equal(old_index=0, new_index=0, len=2), Replace(old_index=2, old_len=1, new_index=2, new_len=1), Equal(old_index=3, new_index=3, len=2), Replace(old_index=5, old_len=2, new_index=5, new_len=2)]",
  )
}

///|
test "test_print_diff_line" {
  let old = ["0", "1", "2", "3", "4", "5"]
  let new = ["9", "1", "2", "5", "6", "7"]
  print_diff_line(old, new)
}

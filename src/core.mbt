///|
/// Type aliases for core diff components
using @algorithms {
  type Range,
  type DiffOp,
  type Replace,
  type Capture,
  type Compact,
}

///| Computes the difference between two arrays of `T`.

///|
/// Main entry point for standard diffing logic using Myers algorithm with `Replace` hook.
pub fn[T : Eq] diff(old : Array[T], new : Array[T]) -> Array[DiffOp] {
  let d = Replace::new(Capture::new())
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
/// Computes the difference between two strings, character by character.
pub fn diff_str(old : String, new : String) -> Array[DiffOp] {
  diff(old.to_array(), new.to_array())
}

///|
/// Computes the difference between two arrays of strings, line by line.
pub fn diff_line(old : Array[String], new : Array[String]) -> Array[DiffOp] {
  diff(old, new)
}

///|
/// Computes the diff between two arrays and prints the result in a line-by-line format.
pub fn[T : Eq + Show] print_diff_line(old : Array[T], new : Array[T]) -> Unit {
  let ops = diff(old, new)
  print_diff_ops(old, new, ops)
}

///|
/// Prints a formatted diff to the console based on a list of `DiffOp`.
pub fn[T : Show] print_diff_ops(
  old : Array[T],
  new : Array[T],
  ops : Array[DiffOp],
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
    }
  }
}

///| Computes the difference between two arrays using the `Compact` hook

///|
/// to produce a more readable and concise result.
pub fn[T : Eq] diff_with_compact(
  old : Array[T],
  new : Array[T],
) -> Array[DiffOp] {
  let d = Compact::new(Replace::new(Capture::new()), old, new)
  let _ = @algorithms.Myers::diff(
    d,
    old,
    Range::new(0, old.length()),
    new,
    Range::new(0, new.length()),
  )
  d.into_ops()
}

///|
/// Test basic diff functionality
test "test_diff" {
  let a = [1, 2, 3, 4, 5, 8, 9]
  let b = [1, 2, 0, 4, 5, 6, 7]
  let diffs = diff(a, b)
  inspect(
    diffs,
    content="[Equal(old_index=0, new_index=0, len=2), Replace(old_index=2, old_len=1, new_index=2, new_len=1), Equal(old_index=3, new_index=3, len=2), Replace(old_index=5, old_len=2, new_index=5, new_len=2)]",
  )
}

///|
/// Test line-by-line diff printing
test "test_print_diff_line" {
  let old = ["0", "1", "2", "3", "4", "5"]
  let new = ["9", "1", "2", "5", "6", "7"]
  print_diff_line(old, new)
}

///|
/// Test compact diff functionality
test "test_diff_with_compact" {
  let old = "a b c d".to_array()
  let new = "a b d c".to_array()
  let compact_diffs = diff_with_compact(old, new)
  inspect(
    compact_diffs,
    content="[Equal(old_index=0, new_index=0, len=4), Insert(old_index=4, new_index=4, new_len=2), Equal(old_index=4, new_index=6, len=1), Delete(old_index=5, old_len=2, new_index=7)]",
  )
}

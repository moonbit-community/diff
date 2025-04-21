///|
pub fn common_prefix_len[T : Eq](
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range
) -> Int {
  if old_range.is_empty() || new_range.is_empty() {
    return 0
  }
  let length = @math.minimum(
    old_range.end - old_range.start,
    new_range.end - new_range.start,
  )
  for i in 0..<length {
    if old[old_range.start + i] != new[new_range.start + i] {
      return i
    }
  }
  length
}

///|
test "common_prefix_len" {
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 5]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect!(common_prefix_len(old, old_range, new, new_range), content="5")
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 6]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect!(common_prefix_len(old, old_range, new, new_range), content="4")
}

///|
pub fn common_suffix_len[T : Eq](
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range
) -> Int {
  if old_range.is_empty() || new_range.is_empty() {
    return 0
  }
  let length = @math.minimum(
    old_range.end - old_range.start,
    new_range.end - new_range.start,
  )
  for i in 0..<length {
    if old[old_range.end - i - 1] != new[new_range.end - i - 1] {
      return i
    }
  }
  length
}

///|
test "common_suffix_len" {
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 5]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect!(common_suffix_len(old, old_range, new, new_range), content="5")
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 6]
  let old_range = Range::new(0, 4)
  let new_range = Range::new(0, 4)
  inspect!(common_suffix_len(old, old_range, new, new_range), content="4")
}

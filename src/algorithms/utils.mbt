///| A wrapper around an item in a sequence that includes its original index.

///| Used by the Patience diff algorithm to track unique items.
struct UniqueItem[T] {
  // A reference to the original sequence.
  lookup : Array[T]
  // The original index of the item in the sequence.
  index : Int
}

///| Creates a new `UniqueItem`.
fn[T] UniqueItem::new(lookup : Array[T], index : Int) -> UniqueItem[T] {
  { lookup, index }
}

///| Returns the value of the item.
fn[T] UniqueItem::value(self : UniqueItem[T]) -> T {
  self.lookup[self.index]
}

///| Returns the original index of the item.
fn[T] UniqueItem::original_index(self : UniqueItem[T]) -> Int {
  self.index
}

///| Implements equality for `UniqueItem` based on their values.
impl[T : Eq] Eq for UniqueItem[T] with op_equal(self, other) {
  self.value() == other.value()
}

///| Implements display formatting for `UniqueItem`.
impl[T : Show] Show for UniqueItem[T] with output(self, logger) {
  self.value().output(logger)
}

///| Finds all unique items in a given range of a sequence.

///| An item is considered unique if it appears exactly once.
pub fn[T : Eq + Hash] unique(
  array : Array[T],
  range : Range
) -> Array[UniqueItem[T]] {
  let map : @hashmap.T[T, Int?] = @hashmap.new()
  for i in range {
    match map.get(array[i]) {
      None => map[array[i]] = Some(i)
      Some(Some(_)) => map[array[i]] = None
      _ => ()
    }
  }
  let result = map
    .iter()
    .filter_map(pair => pair.1)
    .map(index => UniqueItem::new(array, index))
    .collect()
  result.sort_by_key(item => item.original_index())
  result
}

///| Calculates the length of the common prefix between two sequences.
pub fn[T : Eq] common_prefix_len(
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

///| A test for the `common_prefix_len` function.
test "common_prefix_len" {
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 5]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect(common_prefix_len(old, old_range, new, new_range), content="5")
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 6]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect(common_prefix_len(old, old_range, new, new_range), content="4")
}

///| Calculates the length of the common suffix between two sequences.
pub fn[T : Eq] common_suffix_len(
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

///| A test for the `common_suffix_len` function.
test "common_suffix_len" {
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 5]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect(common_suffix_len(old, old_range, new, new_range), content="5")
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 6]
  let old_range = Range::new(0, 4)
  let new_range = Range::new(0, 4)
  inspect(common_suffix_len(old, old_range, new, new_range), content="4")
}

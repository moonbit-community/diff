///|
struct UniqueItem[T] {
  lookup : Array[T]
  index : Int
}

///|
fn[T] UniqueItem::new(lookup : Array[T], index : Int) -> UniqueItem[T] {
  { lookup, index }
}

///|
fn[T] UniqueItem::value(self : UniqueItem[T]) -> T {
  self.lookup[self.index]
}

///|
fn[T] UniqueItem::original_index(self : UniqueItem[T]) -> Int {
  self.index
}

///|
impl[T : Eq] Eq for UniqueItem[T] with op_equal(self, other) {
  self.value() == other.value()
}

///|
impl[T : Show] Show for UniqueItem[T] with output(self, logger) {
  self.value().output(logger)
}

///|
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

///|
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

///|
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

///|
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

///|
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

///| Represents a half-open range `[start, end)`.
pub(all) struct Range {
  mut start : Int
  mut end : Int
} derive(Show)

///| Creates a new `Range`.
pub fn Range::new(start : Int, end : Int) -> Range {
  { start, end }
}

///| Checks if the range is empty.
pub fn Range::is_empty(self : Range) -> Bool {
  self.start >= self.end
}

///| Returns the length of the range.
pub fn Range::len(self : Range) -> Int {
  @cmp.maximum(self.end - self.start, 0)
}

///| Returns an iterator over the values in the range.
pub fn Range::iter(self : Range) -> Iter[Int] {
  let arr : Array[Int] = []
  let mut i = self.start
  while i < self.end {
    arr.push(i)
    i += 1
  }
  arr.iter()
}

///| Checks if the range contains a given index.
pub fn Range::contains(self : Range, i : Int) -> Bool {
  i >= self.start && i < self.end
}

///|
pub(all) struct Range {
  mut start : Int
  mut end : Int
} derive(Show)

///|
pub fn Range::new(start : Int, end : Int) -> Range {
  { start, end }
}

///|
pub fn Range::is_empty(self : Range) -> Bool {
  self.start >= self.end
}

///|
pub fn Range::len(self : Range) -> Int {
  @math.maximum(self.end - self.start, 0)
}

///|
pub fn Range::iter(self : Range) -> Iter[Int] {
  let arr : Array[Int] = []
  let mut i = self.start
  while i < self.end {
    arr.push(i)
    i += 1
  }
  arr.iter()
}

///|
pub fn Range::contains(self : Range, i : Int) -> Bool {
  i >= self.start && i < self.end
}

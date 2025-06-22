///|
pub(all) struct Patience[T, D] {
  d : D
  old : Array[T]
  mut old_current : Int
  old_end : Int
  old_indexes : Array[UniqueItem[T]]
  new : Array[T]
  mut new_current : Int
  new_end : Int
  new_indexes : Array[UniqueItem[T]]
}

///|
pub fn[T : Eq + Hash, D : DiffHook] Patience::diff(
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range
) -> Result[Unit, Error] {
  let old_indexes = unique(old, old_range)
  let new_indexes = unique(new, new_range)
  let patience = {
    d,
    old,
    old_current: old_range.start,
    old_end: old_range.end,
    old_indexes,
    new,
    new_current: new_range.start,
    new_end: new_range.end,
    new_indexes,
  }
  let d = Replace::new(patience)
  // LIS of match pairs equivalent to LCS of UniqueItems
  // 先对uniuqe items找到最多的equal
  let _ = Myers::diff(
    d,
    old_indexes,
    Range::new(0, old_indexes.length()),
    new_indexes,
    Range::new(0, new_indexes.length()),
  )
  Ok(())
}

///|
impl[T : Eq, D : DiffHook] DiffHook for Patience[T, D] with equal(
  self,
  old,
  new,
  len
) {
  let mut i = 0
  // 对于每一个equal的unique item pair, 使用Myers计算开头到pair之间的内容
  while i < len {
    let old = old + i
    let new = new + i
    let a0 = self.old_current
    let b0 = self.new_current
    // 跳过开头相同的内容 
    while self.old_current < self.old_indexes[old].original_index() &&
          self.new_current < self.new_indexes[new].original_index() &&
          self.new[self.new_current] == self.old[self.old_current] {
      self.old_current += 1
      self.new_current += 1
    }
    if self.old_current > a0 {
      let _ = self.d.equal(a0, b0, self.old_current - a0)

    }
    // NoFinishHook can merge results into another diffhook, don't need to call finish
    let no_finish_d = NoFinishHook::new(self.d)
    // find diff between current to pair index
    let _ = Myers::diff(
      no_finish_d,
      self.old,
      Range::new(self.old_current, self.old_indexes[old].original_index()),
      self.new,
      Range::new(self.new_current, self.new_indexes[new].original_index()),
    )
    self.old_current = self.old_indexes[old].original_index()
    self.new_current = self.new_indexes[new].original_index()
    i += 1
  }
  Ok(())
}

///|
impl[T : Eq, D : DiffHook] DiffHook for Patience[T, D] with finish(self) {
  // 最后计算剩余的内容
  Myers::diff(
    self.d,
    self.old,
    Range::new(self.old_current, self.old_end),
    self.new,
    Range::new(self.new_current, self.new_end),
  )
}

///|
test "test_patience" {
  let a = [11, 1, 2, 2, 3, 4, 4, 4, 5, 47, 19]
  let b = [10, 1, 2, 2, 8, 9, 4, 4, 7, 47, 18]
  let d = Replace::new(Capture::new())
  let _ = Patience::diff(
    d,
    a,
    Range::new(0, a.length()),
    b,
    Range::new(0, b.length()),
  )
  let ops = d.into_inner().ops()
  inspect(
    ops,
    content="[Replace(old_index=0, old_len=1, new_index=0, new_len=1), Equal(old_index=1, new_index=1, len=3), Replace(old_index=4, old_len=1, new_index=4, new_len=2), Equal(old_index=5, new_index=6, len=2), Replace(old_index=7, old_len=2, new_index=8, new_len=1), Equal(old_index=9, new_index=9, len=1), Replace(old_index=10, old_len=1, new_index=10, new_len=1)]",
  )
}

///|
test "test_patience_2" {
  let a = [1, 2, 3, 4]
  let b = [1, 2, 3]
  let d = Replace::new(Capture::new())
  let _ = Patience::diff(
    d,
    a,
    Range::new(0, a.length()),
    b,
    Range::new(0, b.length()),
  )
  let ops = d.into_inner().ops()
  inspect(
    ops,
    content="[Equal(old_index=0, new_index=0, len=3), Delete(old_index=3, old_len=1, new_index=3)]",
  )
}

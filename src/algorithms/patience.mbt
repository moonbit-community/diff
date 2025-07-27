///| An implementation of the Patience diff algorithm.

///| It is designed to produce more human-readable diffs by finding a

///| longest common subsequence of unique lines.
pub(all) struct Patience[T, D] {
  // The inner diff hook to which operations are reported.
  d : D
  // The old sequence.
  old : Array[T]
  // The current position in the old sequence.
  mut old_current : Int
  // The end position in the old sequence.
  old_end : Int
  // A list of unique items from the old sequence, used for finding the LCS.
  old_indexes : Array[UniqueItem[T]]
  // The new sequence.
  new : Array[T]
  // The current position in the new sequence.
  mut new_current : Int
  // The end position in the new sequence.
  new_end : Int
  // A list of unique items from the new sequence, used for finding the LCS.
  new_indexes : Array[UniqueItem[T]]
}

///| The main entry point for the Patience diff algorithm.

///| It finds unique items, calculates the LCS between them using Myers diff,

///| and then diffs the sections between the matching unique items.
pub fn[T : Eq + Hash, D : DiffHook] Patience::diff(
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
) -> Result[Unit, Error] {
  // First, find all the unique items in both sequences.
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
  // The Longest Increasing Subsequence (LIS) of matching pairs of unique items
  // is equivalent to the Longest Common Subsequence (LCS) of the unique items.
  // We use Myers diff to find this LCS.
  let _ = Myers::diff(
    d,
    old_indexes,
    Range::new(0, old_indexes.length()),
    new_indexes,
    Range::new(0, new_indexes.length()),
  )
  Ok(())
}

///| This hook is called when a sequence of equal unique items is found.

///| These items act as anchors. We then recursively diff the segments

///| between these anchors.
impl[T : Eq, D : DiffHook] DiffHook for Patience[T, D] with equal(
  self,
  old,
  new,
  len,
) {
  let mut i = 0
  // For each pair of equal unique items, recursively diff the content
  // between the last anchor and the current one.
  while i < len {
    let old = old + i
    let new = new + i
    let a0 = self.old_current
    let b0 = self.new_current
    // First, skip any common prefix between the last anchor and the current one.
    while self.old_current < self.old_indexes[old].original_index() &&
          self.new_current < self.new_indexes[new].original_index() &&
          self.new[self.new_current] == self.old[self.old_current] {
      self.old_current += 1
      self.new_current += 1
    }
    if self.old_current > a0 {
      let _ = self.d.equal(a0, b0, self.old_current - a0)

    }
    // Use `NoFinishHook` to prevent the inner `finish` call from being propagated.
    let no_finish_d = NoFinishHook::new(self.d)
    // Diff the region between the last anchor and the current unique item.
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

///| This hook is called when the main diff (on unique items) is finished.

///| We use it to diff the remaining content after the last unique anchor.
impl[T : Eq, D : DiffHook] DiffHook for Patience[T, D] with finish(self) {
  // Diff the remaining content after the last anchor.
  Myers::diff(
    self.d,
    self.old,
    Range::new(self.old_current, self.old_end),
    self.new,
    Range::new(self.new_current, self.new_end),
  )
}

///| A test for the Patience diff algorithm.
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

///| Another test for the Patience diff algorithm.
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

/// ================================================================================
/// PATIENCE DIFF ALGORITHM
/// ================================================================================
///
/// The Patience diff algorithm produces more human-readable diffs by focusing on
/// unique lines as anchor points. It's particularly effective for source code
/// where unique identifiers (function names, variable names) serve as natural
/// boundaries.
///
/// ALGORITHM OVERVIEW:
/// 1. Identify unique lines in both sequences (lines that appear exactly once)
/// 2. Find the Longest Common Subsequence (LCS) of these unique lines
/// 3. Use these matching unique lines as "anchors"
/// 4. Recursively apply diff algorithms between anchors
///
/// KEY INSIGHT: Unique lines are likely to be meaningful boundaries (function
/// definitions, class declarations, etc.) that humans expect to see aligned.
///
/// TIME COMPLEXITY: O(N log N) where N is the number of unique lines
/// SPACE COMPLEXITY: O(N)
///
/// REFERENCE: Bram Cohen's "Patience Diff" algorithm

///|
/// ================================================================================
/// PATIENCE DIFF STRUCTURE
/// ================================================================================
///
/// The Patience diff algorithm implementation that wraps another diff hook
/// to provide enhanced human-readable diffs.
pub(all) struct Patience[T, D] {
  /// Inner diff hook for reporting final operations
  d : D
  /// Reference to the old sequence being compared
  old : Array[T]
  /// Current position in old sequence during processing
  mut old_current : Int
  /// End position in old sequence
  old_end : Int
  /// Array of unique items from old sequence (with original indices)
  old_indexes : Array[UniqueItem[T]]
  /// Reference to the new sequence being compared
  new : Array[T]
  /// Current position in new sequence during processing
  mut new_current : Int
  /// End position in new sequence
  new_end : Int
  /// Array of unique items from new sequence (with original indices)
  new_indexes : Array[UniqueItem[T]]
}

///|
/// ================================================================================
/// MAIN ALGORITHM ENTRY POINT
/// ================================================================================
///
/// Computes the diff using the Patience algorithm
///
/// ALGORITHM STEPS:
/// 1. Extract unique items from both sequences
/// 2. Find LCS of unique items using Myers algorithm
/// 3. Use matching unique items as anchors for recursive diffing
/// 4. Apply Myers algorithm between anchors for detailed differences
pub fn[T : Eq + Hash, D : DiffHook] Patience::diff(
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
) -> Result[Unit, Error] {
  // Step 1: Identify unique items in both sequences
  // These will serve as anchor points for the algorithm
  let old_indexes = unique(old, old_range)
  let new_indexes = unique(new, new_range)

  // Create Patience structure to track state during processing
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

  // Step 2: Use Myers algorithm to find LCS of unique items
  // The LCS of unique items gives us the anchor points
  let d = Replace::new(patience)
  let _ = Myers::diff(
    d,
    old_indexes,
    Range::new(0, old_indexes.length()),
    new_indexes,
    Range::new(0, new_indexes.length()),
  )
  Ok(())
}

/// ================================================================================
/// DIFF HOOK IMPLEMENTATION FOR ANCHOR PROCESSING
/// ================================================================================
///
/// These implementations handle the processing when unique items (anchors)
/// are found to match between sequences.

///|
/// Called when a sequence of matching unique items (anchors) is found
///
/// PROCESSING STRATEGY:
/// 1. Skip any common prefix between last anchor and current anchor
/// 2. Report the common prefix as Equal operations
/// 3. Recursively diff the region between anchors using Myers algorithm
/// 4. Move to the next anchor point
impl[T : Eq, D : DiffHook] DiffHook for Patience[T, D] with equal(
  self,
  old,
  new,
  len,
) {
  let mut i = 0

  // Process each matching pair of unique items (anchors)
  while i < len {
    let old = old + i
    let new = new + i

    // Save starting positions for potential common prefix
    let a0 = self.old_current
    let b0 = self.new_current

    // Step 1: Skip common prefix between anchors
    // This handles cases where there are additional matches between anchors
    while self.old_current < self.old_indexes[old].original_index() &&
          self.new_current < self.new_indexes[new].original_index() &&
          self.new[self.new_current] == self.old[self.old_current] {
      self.old_current += 1
      self.new_current += 1
    }

    // Step 2: Report any common prefix found
    if self.old_current > a0 {
      let _ = self.d.equal(a0, b0, self.old_current - a0)

    }

    // Step 3: Recursively diff the region between anchors
    // Use Myers algorithm for detailed differences between anchor points
    let no_finish_d = NoFinishHook::new(self.d)
    let _ = Myers::diff(
      no_finish_d,
      self.old,
      Range::new(self.old_current, self.old_indexes[old].original_index()),
      self.new,
      Range::new(self.new_current, self.new_indexes[new].original_index()),
    )

    // Step 4: Move to the anchor position
    self.old_current = self.old_indexes[old].original_index()
    self.new_current = self.new_indexes[new].original_index()
    i += 1
  }
  Ok(())
}

///|
/// Called when the LCS of unique items is complete
///
/// PROCESSING STRATEGY:
/// Handle any remaining content after the last anchor point
impl[T : Eq, D : DiffHook] DiffHook for Patience[T, D] with finish(self) {
  // Diff any remaining content after the last anchor
  Myers::diff(
    self.d,
    self.old,
    Range::new(self.old_current, self.old_end),
    self.new,
    Range::new(self.new_current, self.new_end),
  )
}

///|
/// Test Patience algorithm with complex changes including duplicates
/// Expected: Uses unique values (11, 47, 19 vs 10, 47, 18) as anchors
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
/// Test Patience algorithm with simple deletion at the end
/// Expected: Uses unique values as anchors, handles simple deletion
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

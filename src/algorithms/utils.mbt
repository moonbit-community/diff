/// ================================================================================
/// UTILITY ALGORITHMS FOR DIFF COMPUTATION
/// ================================================================================
///
/// This file contains fundamental algorithms used by the diff algorithms
/// including unique item detection, common prefix/suffix calculation,
/// and supporting data structures.

/// ================================================================================
/// UNIQUE ITEM DETECTION ALGORITHM
/// ================================================================================
///
/// Algorithm to find all unique items in a sequence range
///
/// ALGORITHM OVERVIEW:
/// 1. Scan the sequence and count occurrences of each item
/// 2. Filter items that appear exactly once
/// 3. Track original indices for later reference
/// 4. Sort by original position to maintain sequence order
///
/// TIME COMPLEXITY: O(N log N) where N is the sequence length
/// SPACE COMPLEXITY: O(N) for the hash map and result storage
///
/// USED BY: Patience diff algorithm for finding anchor points

///| Wrapper structure that associates an item with its original index
/// Used to track positions after filtering unique items
struct UniqueItem[T] {
  /// Reference to the original array containing the item
  lookup : Array[T]
  /// Original index of this item in the source array
  index : Int
}

///| Creates a new UniqueItem with array reference and original index
fn[T] UniqueItem::new(lookup : Array[T], index : Int) -> UniqueItem[T] {
  { lookup, index }
}

///| Returns the actual value stored at the tracked index
fn[T] UniqueItem::value(self : UniqueItem[T]) -> T {
  self.lookup[self.index]
}

///| Returns the original index in the source array
fn[T] UniqueItem::original_index(self : UniqueItem[T]) -> Int {
  self.index
}

///| Equality comparison based on item values, not indices
impl[T : Eq] Eq for UniqueItem[T] with op_equal(self, other) {
  self.value() == other.value()
}

///| Finds all unique items in a specified range of an array
///
/// ALGORITHM STEPS:
/// 1. Build frequency map: count occurrences of each value
/// 2. Filter unique values: keep only items with count = 1
/// 3. Create tracking objects: wrap unique items with original indices
/// 4. Sort by position: maintain original sequence order
///
/// @param array The source array to scan
/// @param range The range within the array to examine
/// @return Array of unique items with their original indices
pub fn[T : Eq + Hash] unique(
  array : Array[T],
  range : Range
) -> Array[UniqueItem[T]] {
  // Step 1: Build frequency map
  let map : @hashmap.T[T, Int?] = @hashmap.new()
  for i in range {
    match map.get(array[i]) {
      None => map[array[i]] = Some(i) // First occurrence
      Some(Some(_)) => map[array[i]] = None // Duplicate found
      _ => ()
    }
  }

  // Step 2: Extract unique items and create tracking objects
  let result = map
    .iter()
    .filter_map(pair => pair.1) // Keep only unique items (Some(index))
    .map(index => UniqueItem::new(array, index)) // Wrap with tracking info
    .collect()

  // Step 3: Sort by original position to maintain sequence order
  result.sort_by_key(item => item.original_index())
  result
}

/// ================================================================================
/// COMMON PREFIX ALGORITHM
/// ================================================================================
///
/// Algorithm to find the length of the longest common prefix between
/// two sequence ranges
///
/// ALGORITHM OVERVIEW:
/// 1. Determine the maximum possible prefix length (minimum of both ranges)
/// 2. Compare elements sequentially from the start
/// 3. Stop at first mismatch or end of range
///
/// TIME COMPLEXITY: O(min(M,N)) where M,N are range lengths
/// SPACE COMPLEXITY: O(1)
///
/// USED BY: Myers algorithm for finding diagonal edges in edit graph

///| Calculates the length of the common prefix between two sequence ranges
///
/// @param old First sequence array
/// @param old_range Range within the first sequence
/// @param new Second sequence array  
/// @param new_range Range within the second sequence
/// @return Length of the common prefix (0 if no common prefix)
pub fn[T : Eq] common_prefix_len(
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
) -> Int {
  // Handle edge cases: empty ranges
  if old_range.is_empty() || new_range.is_empty() {
    return 0
  }

  // Calculate maximum possible prefix length
  let length = @cmp.minimum(
    old_range.end - old_range.start,
    new_range.end - new_range.start,
  )

  // Sequential comparison from the start
  for i in 0..<length {
    if old[old_range.start + i] != new[new_range.start + i] {
      return i // Found first mismatch
    }
  }
  length // All elements match up to min length
}

/// ================================================================================
/// COMMON SUFFIX ALGORITHM
/// ================================================================================
///
/// Algorithm to find the length of the longest common suffix between
/// two sequence ranges
///
/// ALGORITHM OVERVIEW:
/// 1. Determine the maximum possible suffix length (minimum of both ranges)
/// 2. Compare elements sequentially from the end
/// 3. Stop at first mismatch or start of range
///
/// TIME COMPLEXITY: O(min(M,N)) where M,N are range lengths
/// SPACE COMPLEXITY: O(1)
///
/// USED BY: Myers algorithm for finding diagonal edges in reverse direction

///| Calculates the length of the common suffix between two sequence ranges
///
/// @param old First sequence array
/// @param old_range Range within the first sequence
/// @param new Second sequence array
/// @param new_range Range within the second sequence  
/// @return Length of the common suffix (0 if no common suffix)
pub fn[T : Eq] common_suffix_len(
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
) -> Int {
  // Handle edge cases: empty ranges
  if old_range.is_empty() || new_range.is_empty() {
    return 0
  }

  // Calculate maximum possible suffix length
  let length = @cmp.minimum(
    old_range.end - old_range.start,
    new_range.end - new_range.start,
  )

  // Sequential comparison from the end
  for i in 0..<length {
    if old[old_range.end - i - 1] != new[new_range.end - i - 1] {
      return i // Found first mismatch
    }
  }
  length // All elements match up to min length
}

///| Test common prefix detection with identical sequences
/// Expected: Should return full length when sequences are identical
test "common_prefix_len" {
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 5]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect(common_prefix_len(old, old_range, new, new_range), content="5")

  // Test with partial match
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 6]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect(common_prefix_len(old, old_range, new, new_range), content="4")
}

///| Test common suffix detection with identical sequences
/// Expected: Should return full length when sequences are identical
test "common_suffix_len" {
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 5]
  let old_range = Range::new(0, 5)
  let new_range = Range::new(0, 5)
  inspect(common_suffix_len(old, old_range, new, new_range), content="5")

  // Test with partial match
  let old = [1, 2, 3, 4, 5]
  let new = [1, 2, 3, 4, 6]
  let old_range = Range::new(0, 4)
  let new_range = Range::new(0, 4)
  inspect(common_suffix_len(old, old_range, new, new_range), content="4")
}

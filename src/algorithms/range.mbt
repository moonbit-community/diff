/// ================================================================================
/// RANGE DATA STRUCTURE AND ALGORITHMS
/// ================================================================================
///
/// A fundamental data structure representing half-open ranges [start, end)
/// Used extensively throughout the diff algorithms for sequence indexing
///
/// DESIGN PRINCIPLES:
/// - Half-open ranges [start, end) are mathematically clean and avoid off-by-one errors
/// - Mutable fields allow efficient range manipulation during algorithms
/// - Provides utility methods for common range operations
/// - Integrates seamlessly with array indexing

///| ================================================================================
/// RANGE STRUCTURE
/// ================================================================================
///
/// Represents a contiguous range of indices [start, end) where:
/// - start is inclusive (first index in range)
/// - end is exclusive (one past the last index)
///
/// This half-open interval design allows clean empty ranges (start == end)
/// and simplifies length calculations (end - start)
pub(all) struct Range {
  /// Inclusive start index of the range
  mut start : Int
  /// Exclusive end index of the range
  mut end : Int
} derive(Show)

///| Creates a new Range with specified start and end indices
///
/// @param start Inclusive start index
/// @param end Exclusive end index
/// @return New Range instance
pub fn Range::new(start : Int, end : Int) -> Range {
  { start, end }
}

/// ================================================================================
/// RANGE QUERY ALGORITHMS
/// ================================================================================

///| Checks if the range contains no elements
///
/// ALGORITHM: A range is empty when start >= end
/// This is the mathematical property of half-open intervals
///
/// @return true if range contains no elements, false otherwise
pub fn Range::is_empty(self : Range) -> Bool {
  self.start >= self.end
}

///| Calculates the number of elements in the range
///
/// ALGORITHM: length = max(0, end - start)
/// The max ensures we never return negative length for invalid ranges
///
/// @return Number of elements in the range (0 for empty ranges)
pub fn Range::len(self : Range) -> Int {
  @cmp.maximum(self.end - self.start, 0)
}

///| Checks if a specific index falls within the range
///
/// ALGORITHM: index is in range when start <= index < end
/// This follows the half-open interval definition
///
/// @param i The index to check
/// @return true if index is within range, false otherwise
pub fn Range::contains(self : Range, i : Int) -> Bool {
  i >= self.start && i < self.end
}

///| ================================================================================
/// RANGE ITERATION ALGORITHM
/// ================================================================================
///
/// Creates an iterator over all indices in the range
///
/// ALGORITHM: Generates indices from start to end-1 inclusive
/// This provides a convenient way to iterate over array indices
///
/// @return Iterator yielding all indices in the range
pub fn Range::iter(self : Range) -> Iter[Int] {
  let arr : Array[Int] = []
  let mut i = self.start
  while i < self.end {
    arr.push(i)
    i += 1
  }
  arr.iter()
}

/// ================================================================================
/// RANGE UTILITY ALGORITHMS
/// ================================================================================
///
/// Additional utility methods that could be useful for range manipulation
/// These are not currently used but demonstrate the mathematical properties

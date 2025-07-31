/// ================================================================================
/// MYERS DIFF ALGORITHM
/// ================================================================================
///
/// The Myers diff algorithm is an optimal algorithm for computing the difference
/// between two sequences. It finds the shortest edit script (minimum number of
/// insertions and deletions) to transform one sequence into another.
///
/// ALGORITHM OVERVIEW:
/// 1. The algorithm models the problem as finding the shortest path in an edit graph
/// 2. The edit graph has nodes representing positions (x,y) in the two sequences
/// 3. Horizontal edges represent deletions from the old sequence
/// 4. Vertical edges represent insertions into the new sequence  
/// 5. Diagonal edges represent matches (no change needed)
/// 6. The algorithm uses a greedy approach with divide-and-conquer
///
/// TIME COMPLEXITY: O((M+N)D) where M and N are sequence lengths, D is edit distance
/// SPACE COMPLEXITY: O(M+N)
///
/// REFERENCE: "An O(ND) Difference Algorithm and Its Variations" by Eugene W. Myers

///| The Myers diff algorithm implementation type
pub type Myers

/// ================================================================================
/// V VECTOR - CORE DATA STRUCTURE
/// ================================================================================
///
/// The V vector is a crucial data structure in Myers algorithm. It stores the
/// furthest-reaching x-coordinate for each diagonal k in the edit graph.
///
/// KEY INSIGHT: In the edit graph, diagonals represent lines where x-y = k (constant)
/// Each diagonal k can be reached with a certain number of edits (d). The V vector
/// tracks the maximum x-coordinate reachable on each diagonal with exactly d edits.
///
/// STRUCTURE:
/// - offset: Maps diagonal indices (can be negative) to array indices (must be positive)
/// - v: Array storing the furthest x-coordinate for each diagonal

///| The V vector for tracking furthest-reaching paths in the edit graph
struct V {
  /// Offset to convert diagonal k (can be negative) to array index
  offset : Int
  /// Array storing furthest x-coordinates for each diagonal
  v : Array[Int]
}

///| Creates a new V vector with capacity for diagonals from -max_d to +max_d
pub fn V::new(max_d : Int) -> V {
  { offset: max_d, v: Array::make(max_d * 2, 0) }
}

///| Returns the total capacity of the V vector
pub fn V::len(self : V) -> Int {
  self.v.length()
}

///| Gets the x-coordinate for diagonal k
pub fn V::op_get(self : V, i : Int) -> Int {
  self.v[i + self.offset]
}

///| Sets the x-coordinate for diagonal k
pub fn V::op_set(self : V, i : Int, value : Int) -> Unit {
  self.v[i + self.offset] = value
}

/// ================================================================================
/// UTILITY FUNCTIONS
/// ================================================================================

///| Calculates the maximum possible edit distance needed
/// This bounds the search space for the algorithm
fn max_d(len1 : Int, len2 : Int) -> Int {
  (len1 + len2 + 1) / 2 + 1
}

///| Splits a range into two parts at a given point
/// Used in divide-and-conquer step
fn split_at(range : Range, at : Int) -> (Range, Range) {
  (Range::new(range.start, at), Range::new(at, range.end))
}

///| ================================================================================
/// MAIN ALGORITHM ENTRY POINT
/// ================================================================================
///
/// Computes the diff between two sequences using Myers algorithm
///
/// ALGORITHM STEPS:
/// 1. Initialize data structures (V vectors for forward/backward search)
/// 2. Use divide-and-conquer to recursively find optimal diffs
/// 3. Report results through the provided DiffHook
pub fn[T : Eq, D : DiffHook] Myers::diff(
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
) -> Result[Unit, Error] {
  let max_d = max_d(old_range.len(), new_range.len())
  let vb = V::new(max_d)
  let vf = V::new(max_d)
  let _ = divide_and_conquer(d, old, old_range, new, new_range, vf, vb)
  d.finish()
}

///| ================================================================================
/// MIDDLE SNAKE DETECTION
/// ================================================================================
///
/// The "middle snake" is the key insight of Myers algorithm. It's the point
/// where forward and backward searches meet in the edit graph.
///
/// ALGORITHM:
/// 1. Perform simultaneous forward and backward searches
/// 2. For each edit distance d, explore all possible diagonals k
/// 3. Track the furthest reachable point on each diagonal
/// 4. When forward and backward paths overlap, we've found the middle snake
///
/// The middle snake divides the problem into two smaller subproblems
fn[T : Eq] find_middle_snake(
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
  vf : V, // forward search V vector
  vb : V, // backward search V vector
) -> (Int, Int)? {
  let n = old_range.len()
  let m = new_range.len()

  // Delta represents the difference in sequence lengths
  // This affects where the optimal path must cross
  let delta = n - m
  let odd = (delta & 1) == 1

  // Initialize search boundaries
  vf[1] = 0 // Forward search starts at (0, -1)
  vb[1] = 0 // Backward search starts at (N, M + 1)
  let d_max = max_d(n, m)
  let mut d = 0
  while d < d_max {
    // FORWARD SEARCH: Find furthest reachable points
    let mut k = d
    while k >= -d {
      // Choose the path that reaches furthest
      let mut x = if k == -d || (k != d && vf[k - 1] < vf[k + 1]) {
        vf[k + 1] // Came from diagonal k+1 (insertion)
      } else {
        vf[k - 1] + 1 // Came from diagonal k-1 (deletion)
      }
      let y = x - k // Calculate y from x and diagonal k
      let (x0, y0) = (x, y) // Save starting point of snake

      // Follow diagonal edges (matches) as far as possible
      if x < n && y < m {
        let advance = common_prefix_len(
          old,
          Range::new(old_range.start + x, old_range.end),
          new,
          Range::new(new_range.start + y, new_range.end),
        )
        x += advance
      }
      vf[k] = x

      // Check if forward and backward paths have met
      if odd && (k - delta).abs() <= d - 1 {
        if vf[k] + vb[-(k - delta)] >= n {
          return Some((x0 + old_range.start, y0 + new_range.start))
        }
      }
      k -= 2
    }

    // BACKWARD SEARCH: Similar to forward but in reverse
    let mut k = d
    while k >= -d {
      let mut x = if k == -d || (k != d && vb[k - 1] < vb[k + 1]) {
        vb[k + 1]
      } else {
        vb[k - 1] + 1
      }
      let mut y = x - k

      // Follow diagonal edges (matches) backwards
      if x < n && y < m {
        let advance = common_suffix_len(
          old,
          Range::new(old_range.start, old_range.start + n - x),
          new,
          Range::new(new_range.start, new_range.start + m - y),
        )
        x += advance
        y += advance
      }
      vb[k] = x

      // Check if paths have met
      if not(odd) && (k - delta).abs() <= d {
        if vb[k] + vf[-(k - delta)] >= n {
          return Some((n - x + old_range.start, m - y + new_range.start))
        }
      }
      k -= 2
    }
    d += 1
  }
  None
}

///| ================================================================================
/// DIVIDE-AND-CONQUER STRATEGY
/// ================================================================================
///
/// Recursively applies Myers algorithm to smaller subproblems
///
/// STRATEGY:
/// 1. Strip common prefix and suffix (these are guaranteed matches)
/// 2. Handle base cases (empty sequences)
/// 3. Find middle snake to split problem into two smaller subproblems
/// 4. Recursively solve each subproblem
/// 5. Combine results
fn[T : Eq, D : DiffHook] divide_and_conquer(
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
  vf : V, // forward v
  vb : V, // backward v
) -> Result[Unit, Error] {
  // Step 1: Strip common prefix (matches at the beginning)
  let common_prefix_len = common_prefix_len(old, old_range, new, new_range)
  if common_prefix_len > 0 {
    let _ = d.equal(old_range.start, new_range.start, common_prefix_len)

  }
  old_range.start += common_prefix_len
  new_range.start += common_prefix_len

  // Step 2: Strip common suffix (matches at the end)
  let common_suffix_len = common_suffix_len(old, old_range, new, new_range)
  let common_suffix = (
    old_range.end - common_suffix_len,
    new_range.end - common_suffix_len,
  )
  old_range.end -= common_suffix_len
  new_range.end -= common_suffix_len

  // Step 3: Handle base cases
  if old_range.is_empty() && new_range.is_empty() {
    // Both sequences empty - nothing to do
  } else if new_range.is_empty() {
    // New sequence empty - pure deletion
    let _ = d.delete(old_range.start, old_range.len(), new_range.start)

  } else if old_range.is_empty() {
    // Old sequence empty - pure insertion
    let _ = d.insert(old_range.start, new_range.start, new_range.len())

  } else {
    // Step 4: Recursive case - find middle snake and divide
    match find_middle_snake(old, old_range, new, new_range, vf, vb) {
      Some((x_start, y_start)) => {
        // Split ranges at middle snake
        let (old_a, old_b) = split_at(old_range, x_start)
        let (new_a, new_b) = split_at(new_range, y_start)

        // Recursively solve subproblems
        let _ = divide_and_conquer(d, old, old_a, new, new_a, vf, vb)
        let _ = divide_and_conquer(d, old, old_b, new, new_b, vf, vb)

      }
      None => {
        // Fallback: treat as replace operation
        let _ = d.delete(old_range.start, old_range.len(), new_range.start)
        let _ = d.insert(old_range.start, new_range.start, new_range.len())

      }
    }
  }

  // Step 5: Report common suffix that was stripped earlier
  if common_suffix_len > 0 {
    let _ = d.equal(common_suffix.0, common_suffix.1, common_suffix_len)

  }
  Ok(())
}

///| Test middle snake detection with classic example
/// Expected: middle snake starts at (4,1) in "ABCABBA" vs "CBABAC"
test "test_middle_snake" {
  let a = "ABCABBA".to_array()
  let b = "CBABAC".to_array()
  let max_d = max_d(a.length(), b.length())
  let vf = V::new(max_d)
  let vb = V::new(max_d)
  match
    find_middle_snake(
      a,
      Range::new(0, a.length()),
      b,
      Range::new(0, b.length()),
      vf,
      vb,
    ) {
    Some((x_start, y_start)) => {
      inspect(x_start, content="4")
      inspect(y_start, content="1")
    }
    None => abort("No middle snake found")
  }
}

///| Comprehensive test cases for Myers algorithm
/// Tests various scenarios: single change, multiple changes, insertions, deletions
test "test_diff" {
  // Test 1: Single element change
  let a = [0, 1, 2, 3, 4]
  let b = [0, 1, 2, 9, 4]
  let capture = Capture::new()
  let _ = Myers::diff(
    capture,
    a,
    Range::new(0, a.length()),
    b,
    Range::new(0, b.length()),
  )
  let ops = capture.into_ops()
  inspect(
    ops,
    content="[Equal(old_index=0, new_index=0, len=3), Delete(old_index=3, old_len=1, new_index=4), Insert(old_index=3, new_index=3, new_len=1), Equal(old_index=4, new_index=4, len=1)]",
  )

  // Test 2: Multiple changes with duplicates
  let a = [0, 1, 2, 3, 4, 4, 4, 5]
  let b = [0, 1, 2, 8, 9, 4, 4, 7]
  let capture = Capture::new()
  let _ = Myers::diff(
    capture,
    a,
    Range::new(0, a.length()),
    b,
    Range::new(0, b.length()),
  )
  let ops = capture.into_ops()
  inspect(
    ops,
    content="[Equal(old_index=0, new_index=0, len=3), Delete(old_index=3, old_len=1, new_index=4), Insert(old_index=3, new_index=3, new_len=1), Insert(old_index=4, new_index=4, new_len=1), Equal(old_index=4, new_index=5, len=2), Delete(old_index=6, old_len=2, new_index=7), Insert(old_index=8, new_index=7, new_len=1)]",
  )

  // Test 3: Insertions and deletions
  let a = [0, 1, 3, 4, 5]
  let b = [0, 1, 4, 5, 8, 9]
  let capture = Capture::new()
  let _ = Myers::diff(
    capture,
    a,
    Range::new(0, a.length()),
    b,
    Range::new(0, b.length()),
  )
  let ops = capture.into_ops()
  inspect(
    ops,
    content="[Equal(old_index=0, new_index=0, len=2), Delete(old_index=2, old_len=1, new_index=2), Equal(old_index=3, new_index=2, len=2), Insert(old_index=5, new_index=4, new_len=1), Insert(old_index=5, new_index=5, new_len=1)]",
  )
}

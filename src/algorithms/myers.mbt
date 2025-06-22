///| The Myers diff algorithm.
type Myers

///| The `V` vector for the Myers algorithm.

///| It stores the furthest-reaching x-coordinates for each diagonal `k`.
struct V {
  // The offset used to convert a diagonal `k` (which can be negative)
  // into an array index (which must be non-negative).
  offset : Int
  // The vector storing the x-coordinates.
  v : Array[Int]
}

///| Creates a new `V` vector with a given maximum `d` value.
pub fn V::new(max_d : Int) -> V {
  { offset: max_d, v: Array::make(max_d * 2, 0) }
}

///| Returns the length of the `V` vector.
pub fn V::len(self : V) -> Int {
  self.v.length()
}

///| Gets the x-coordinate for a given diagonal `k`.
pub fn V::op_get(self : V, i : Int) -> Int {
  self.v[i + self.offset]
}

///| Sets the x-coordinate for a given diagonal `k`.
pub fn V::op_set(self : V, i : Int, value : Int) -> Unit {
  self.v[i + self.offset] = value
}

///| Calculates the maximum possible edit distance `d`.
fn max_d(len1 : Int, len2 : Int) -> Int {
  (len1 + len2 + 1) / 2 + 1
}

///| Splits a range into two at a given point.
fn split_at(range : Range, at : Int) -> (Range, Range) {
  (Range::new(range.start, at), Range::new(at, range.end))
}

///| The main entry point for the Myers diff algorithm.

///| It uses a divide-and-conquer strategy to find the diff.
pub fn[T : Eq, D : DiffHook] Myers::diff(
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range
) -> Result[Unit, Error] {
  let max_d = max_d(old_range.len(), new_range.len())
  let vb = V::new(max_d)
  let vf = V::new(max_d)
  let _ = divide_and_conquer(d, old, old_range, new, new_range, vf, vb)
  d.finish()
}

///| Finds the "middle snake" in the edit graph, which is the key to

///| the divide-and-conquer strategy. It searches from both the start

///| and the end of the sequences and finds where the paths meet.

///|

///| Returns the `(x, y)` coordinate of the start of the middle snake.
fn[T : Eq] find_middle_snake(
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
  vf : V, // forward v
  vb : V // backward v
) -> (Int, Int)? {
  let n = old_range.len()
  let m = new_range.len()

  // The difference in length between the two sequences.
  // This is used to check for overlapping paths.
  let delta = n - m
  let odd = (delta & 1) == 1

  // Initialize the `V` vectors for forward and backward searches.
  // The initial point at (0, -1)
  vf[1] = 0
  // The initial point at (N, M + 1)
  vb[1] = 0
  let d_max = max_d(n, m)

  // Iterate up to the maximum possible edit distance.
  let mut d = 0
  while d < d_max {
    // --- Forward search ---
    // Search for the furthest-reaching path in the forward direction.
    let mut k = d // k = x - y
    while k >= -d {
      let mut x = if k == -d || (k != d && vf[k - 1] < vf[k + 1]) {
        vf[k + 1]
      } else {
        vf[k - 1] + 1
      }
      let y = x - k
      let (x0, y0) = (x, y)
      if x < n && y < m {
        // Follow diagonals (matches) as far as possible.
        let advance = common_prefix_len(
          old,
          Range::new(old_range.start + x, old_range.end),
          new,
          Range::new(new_range.start + y, new_range.end),
        )
        x += advance
      }
      vf[k] = x
      // Check if the forward and backward paths have overlapped.
      if odd && (k - delta).abs() <= d - 1 {
        if vf[k] + vb[-(k - delta)] >= n { // The paths have met.
          return Some((x0 + old_range.start, y0 + new_range.start))
        }
      }
      k -= 2
    }

    // --- Backward search ---
    // Search for the furthest-reaching path in the backward direction.
    let mut k = d
    while k >= -d {
      let mut x = if k == -d || (k != d && vb[k - 1] < vb[k + 1]) {
        vb[k + 1]
      } else {
        vb[k - 1] + 1
      }
      let mut y = x - k
      if x < n && y < m {
        // Follow diagonals (matches) as far as possible.
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
      // Check if the forward and backward paths have overlapped.
      if not(odd) && (k - delta).abs() <= d {
        if vb[k] + vf[-(k - delta)] >= n {
          // The paths have met.
          return Some((n - x + old_range.start, m - y + new_range.start))
        }
      }
      k -= 2
    }
    d += 1
  }
  None
}

///| The recursive part of the divide-and-conquer algorithm.
fn[T : Eq, D : DiffHook] divide_and_conquer(
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
  vf : V, // forward v
  vb : V // backward v
) -> Result[Unit, Error] {
  // First, strip any common prefix and report it as `Equal`.
  let common_prefix_len = common_prefix_len(old, old_range, new, new_range)
  if common_prefix_len > 0 {
    let _ = d.equal(old_range.start, new_range.start, common_prefix_len)

  }
  old_range.start += common_prefix_len
  new_range.start += common_prefix_len

  // Then, strip any common suffix and report it as `Equal`.
  let common_suffix_len = common_suffix_len(old, old_range, new, new_range)
  let common_suffix = (
    old_range.end - common_suffix_len,
    new_range.end - common_suffix_len,
  )
  old_range.end -= common_suffix_len
  new_range.end -= common_suffix_len

  // After stripping common parts, check the base cases.
  if old_range.is_empty() && new_range.is_empty() {
    // Both ranges are empty, nothing to do.
  } else if new_range.is_empty() {
    // The new range is empty, so this is a pure deletion.
    let _ = d.delete(old_range.start, old_range.len(), new_range.start)

  } else if old_range.is_empty() {
    // The old range is empty, so this is a pure insertion.
    let _ = d.insert(old_range.start, new_range.start, new_range.len())

  } else {
    // This is the recursive case. Find the middle snake and divide the problem.
    match find_middle_snake(old, old_range, new, new_range, vf, vb) {
      Some((x_start, y_start)) => {
        // Split the ranges at the middle snake.
        let (old_a, old_b) = split_at(old_range, x_start)
        let (new_a, new_b) = split_at(new_range, y_start)
        // Recursively diff the two sub-problems.
        let _ = divide_and_conquer(d, old, old_a, new, new_a, vf, vb)
        let _ = divide_and_conquer(d, old, old_b, new, new_b, vf, vb)

      }
      None => {
        // This should not happen in the standard Myers algorithm unless
        // there's a heuristic or limit that stops it early.
        // As a fallback, report the whole range as a replace.
        let _ = d.delete(old_range.start, old_range.len(), new_range.start)
        let _ = d.insert(old_range.start, new_range.start, new_range.len())

      }
    }
  }

  // Finally, report the common suffix that was stripped earlier.
  if common_suffix_len > 0 {
    let _ = d.equal(common_suffix.0, common_suffix.1, common_suffix_len)

  }
  Ok(())
}

///| A test for the `find_middle_snake` function.
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

///| A test for the main `diff` function with various inputs.
test "test_diff" {
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

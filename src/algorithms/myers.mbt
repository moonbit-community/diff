///|
type Myers

///|
struct V {
  offset : Int
  v : Array[Int]
}

///|
pub fn V::new(max_d : Int) -> V {
  { offset: max_d, v: Array::make(max_d * 2, 0) }
}

///|
pub fn V::len(self : V) -> Int {
  self.v.length()
}

///|
pub fn V::op_get(self : V, i : Int) -> Int {
  self.v[i + self.offset]
}

///|
pub fn V::op_set(self : V, i : Int, value : Int) -> Unit {
  self.v[i + self.offset] = value
}

///|
fn max_d(len1 : Int, len2 : Int) -> Int {
  (len1 + len2 + 1) / 2 + 1
}

///|
fn split_at(range : Range, at : Int) -> (Range, Range) {
  (Range::new(range.start, at), Range::new(at, range.end))
}

///|
pub fn Myers::diff[T : Eq, D : DiffHook](
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

///|
/// return the start position of snake
fn find_middle_snake[T : Eq](
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
  vf : V, // forward v
  vb : V // backward v
) -> (Int, Int)? {
  let n = old_range.len()
  let m = new_range.len()

  // optimal edit script length is odd or even 
  // as `delta` is odd or even 
  let delta = n - m
  let odd = (delta & 1) == 1

  // The initial point at (0, -1)
  vf[1] = 0
  // The initial point at (N, M + 1)
  vb[1] = 0
  let d_max = max_d(n, m)

  // assert (vf.len() >= d_max)
  // assert (vb.len() >= d_max)

  let mut d = 0
  while d < d_max {

    // forward
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
        let advance = common_prefix_len(
          old,
          Range::new(old_range.start + x, old_range.end),
          new,
          Range::new(new_range.start + y, new_range.end),
        )
        x += advance
      }
      vf[k] = x
      if odd && (k - delta).abs() <= d - 1 {
        if vf[k] + vb[-(k - delta)] >= n { // 判断是否相遇
          return Some((x0 + old_range.start, y0 + new_range.start))
        }
      }
      k -= 2
    }

    //Backward 

    let mut k = d
    while k >= -d {
      let mut x = if k == -d || (k != d && vb[k - 1] < vb[k + 1]) {
        vb[k + 1]
      } else {
        vb[k - 1] + 1
      }
      let mut y = x - k
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

///|
fn divide_and_conquer[T : Eq, D : DiffHook](
  d : D,
  old : Array[T],
  old_range : Range,
  new : Array[T],
  new_range : Range,
  vf : V, // forward v
  vb : V // backward v
) -> Result[Unit, Error] {
  let common_prefix_len = common_prefix_len(old, old_range, new, new_range)
  if common_prefix_len > 0 {
    let _ = d.equal(old_range.start, new_range.start, common_prefix_len)

  }
  old_range.start += common_prefix_len
  new_range.start += common_prefix_len
  let common_suffix_len = common_suffix_len(old, old_range, new, new_range)
  let common_suffix = (
    old_range.end - common_suffix_len,
    new_range.end - common_suffix_len,
  )

  old_range.end -= common_suffix_len
  new_range.end -= common_suffix_len
  if old_range.is_empty() && new_range.is_empty() {
    // do nothing
  } else if new_range.is_empty() {
    let _ = d.delete(old_range.start, old_range.len(), new_range.start)

  } else if old_range.is_empty() {
    let _ = d.insert(old_range.start, new_range.start, new_range.len())

  } else {
    // find_middle_snake
    match find_middle_snake(old, old_range, new, new_range, vf, vb) {
      Some((x_start, y_start)) => {
        let (old_a, old_b) = split_at(old_range, x_start)
        let (new_a, new_b) = split_at(new_range, y_start)
        let _ = divide_and_conquer(d, old, old_a, new, new_a, vf, vb)
        let _ = divide_and_conquer(d, old, old_b, new, new_b, vf, vb)

      }
      None => {
        let _ = d.delete(old_range.start, old_range.len(), new_range.start)
        let _ = d.insert(old_range.start, new_range.start, new_range.len())

      }
    }
  }

  if common_suffix_len > 0 {
    let _ = d.equal(common_suffix.0, common_suffix.1, common_suffix_len)
  }
  Ok(())
}

///|
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
      inspect!(x_start, content="4")
      inspect!(y_start, content="1")
    }
    None => abort("No middle snake found")
  }
}

///|
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
  println(ops)
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
  println(ops)
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
  println(ops)
}

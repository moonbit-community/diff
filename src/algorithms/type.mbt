///|
pub(all) enum DiffOp {
  Equal(old_index~ : Int, new_index~ : Int, len~ : Int)
  Delete(old_index~ : Int, old_len~ : Int, new_index~ : Int)
  Insert(old_index~ : Int, new_index~ : Int, new_len~ : Int)
  Replace(old_index~ : Int, old_len~ : Int, new_index~ : Int, new_len~ : Int)
  Finish
} derive(Eq, Show, Hash, Compare)

import java.util.ArrayList;
import java.util.List;

final class SortedList<A extends Comparable<A>> {
  private ArrayList<A> _list;

  /** Immediately assure that we sort the given list. */
  public SortedList(List<A> list) {
    _list = new ArrayList<>(list); _list.sort(null);
  }

  public List<A> get() {
    // We know this is safe, but Java doesn't because of type erasure.
    return (List<A>)_list.clone();
  }
}

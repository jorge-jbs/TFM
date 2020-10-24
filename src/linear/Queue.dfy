include "../../src/linear/ListSeq.dfy"

class Queue<A> {
  var list: List<A>;
  var last: Node?<A>;

  predicate Valid()
    reads this, list, list.spine
  {
    list.Valid() && (last != null ==> (last in list.Repr() && last.next == null))
  }

  function Repr(): set<object>
    reads this, list, list.spine
  {
    list.Repr()
  }

  function Model(): seq<A>
    reads this, list, list.spine
    requires Valid()
  {
    list.Model()
  }

  constructor()
    ensures Valid()
  {
    list := new List();
    last := null;
  }

  // O(1)
  method PushFront(x: A)
    modifies list
    requires Valid()
    ensures Valid()
    ensures Model() == [x] + old(Model())
    ensures Repr() > old(Repr())
    ensures fresh(Repr() - old(Repr()))
  {
    list.Push(x);
  }

  // O(1)
  method PopFront() returns (x: A)
    modifies this, list
    requires Valid()
    requires Model() != []
    ensures Valid()
    ensures [x] + Model() == old(Model())
    ensures Repr() < old(Repr())
  /*
  {
    if list.head == last {
      last := null;
    }
    x := list.Pop();
    if list.head != last {
      assert Valid();
    }
  }
  */

  // O(1)
  method PushBack(x: A)
    modifies list
    requires Valid()
    ensures Valid()
    ensures Model() == old(Model()) + [x]
    ensures Repr() > old(Repr())
    ensures fresh(Repr() - old(Repr()))

  // O(n)
  method PopBack(x: A)
    modifies this, list
    requires Valid()
    requires Model() != []
    ensures Valid()
    ensures Model() + [x] == old(Model())
    ensures Repr() < old(Repr())
}

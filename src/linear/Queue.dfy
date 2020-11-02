include "../../src/linear/ListSeq.dfy"

class Queue<A> {
  var list: List<A>;
  var last: Node?<A>;

  predicate Valid()
    reads this, list, list.spine
  {
    && list.Valid()
    && (if last == null then
        list.head == null
      else
        last in list.Repr() && last.next == null
      )
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
    modifies this, list
    requires Valid()
    ensures Valid()
    ensures Model() == [x] + old(Model())
    ensures Repr() > old(Repr())
    ensures fresh(Repr() - old(Repr()))
  {
    var ohead := list.head;
    list.Push(x);
    if ohead == null {
      last := list.head;
    }
  }

  // O(1)
  method PopFront() returns (x: A)
    modifies this, list
    requires Valid()
    requires Model() != []
    ensures Valid()
    ensures [x] + Model() == old(Model())
    ensures Repr() < old(Repr())
  {
    if list.head == last {
      last := null;
    }
    x := list.Pop();
  }

  // O(1)
  method PushBack(x: A)
    modifies this, last, list
    requires Valid()
    ensures Valid()
    // ensures Model() == old(Model()) + [x]
    // ensures Repr() > old(Repr())
    // ensures fresh(Repr() - old(Repr()))
  {
    if last == null {
      assert Model() == [];
      list.Push(x);
      last := list.head;
    } else {
      list.Insert(last, x);
      last := last.next;
      assert last != null;
      assert Valid();
    }
  }

  // O(n)
  method PopBack() returns (x: A)
    modifies this, list, list.Repr()
    requires Valid()
    requires Model() != []
    ensures Valid()
    // ensures Model() + [x] == old(Model())
    // ensures Repr() < old(Repr())
  {
    if list.head == last {
      x := list.head.data;
      list.head := null;
      /*GHOST*/ list.spine := [];
      last := null;
    } else {
      var prev := list.FindPrev(last);
      list.RemoveNext(prev);
      last := prev;
      x := prev.data;
    }
  }
}

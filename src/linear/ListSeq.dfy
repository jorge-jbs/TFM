include "../../src/Utils.dfy"

class Node<A> {
  var data: A;
  var next: Node?<A>;

  constructor(data: A, next: Node?<A>)
    ensures this.data == data
    ensures this.next == next
  {
    this.data := data;
    this.next := next;
  }

  predicate IsPrevOf(n: Node<A>)
    reads this
  {
    next == n
  }
}

class List<A> {
  var head: Node?<A>;
  var spine: seq<Node<A>>;

  function Repr(): set<object>
    reads this, spine
  {
    set x | x in spine
  }

  predicate Valid()
    reads this, spine
  {
    && (forall i | 0 <= i < |spine|-1 :: spine[i].IsPrevOf(spine[i+1]))
    && (if head == null then
        spine == []
      else
        spine != [] && spine[0] == head && spine[|spine|-1].next == null
      )
  }

  lemma HeadInSpine()
    requires Valid()
    ensures head != null ==> head in spine
  {
  }

  lemma DistinctSpineAux(n: nat)
    decreases |spine| - n
    requires Valid()
    requires 0 <= n <= |spine|
    ensures forall i, j | n <= i < j < |spine| :: spine[i] != spine[j]
  {
    if n == |spine| {
      assert spine[n..] == [];
    } else {
      DistinctSpineAux(n+1);
      assert forall i, j | n+1 <= i < j < |spine| :: spine[i] != spine[j];
      if exists x :: x in spine[n+1..] && spine[n] == x {
        var x: Node<A>; x :| x in spine[n+1..] && spine[n] == x;
        assert x.next == spine[n+1];
        assert exists i | n+1 <= i < |spine| :: spine[i] == x;
        var i: nat; i :| n+1 <= i < |spine| && spine[i] == x;
        assert spine[i].next == spine[n+1];
        assert i+1 < |spine|;
        assert spine[i].next == spine[i+1];
        assert n <= i;
        assert n < i+1;
        assert false;
      }
      assert forall x | x in spine[n+1..] :: spine[n] != x;
      assert forall i, j | n <= i < j < |spine| :: spine[i] != spine[j];
    }
  }

  lemma DistinctSpine()
    requires Valid()
    ensures forall i, j | 0 <= i < j < |spine| :: spine[i] != spine[j]
  {
    DistinctSpineAux(0);
  }

  lemma HeadNotInTail()
    requires Valid()
    requires head != null
    ensures head !in spine[1..]
  {
    DistinctSpine();
  }

  lemma NextNullImpliesLast(n: Node<A>)
    requires Valid()
    requires n in spine
    requires n.next == null
    ensures spine[|spine|-1] == n
  {
    if spine[|spine|-1] != n {
      var i :| 0 <= i < |spine| && spine[i] == n;
      assert i != |spine|-1;
      assert spine[i].IsPrevOf(spine[i+1]);
      assert spine[i+1] == null;
      assert spine[i+1] != null;
      assert false;
    }
  }

  static function ModelAux(xs: seq<Node<A>>): seq<A>
    reads set x | x in xs :: x`data
  {
    if xs == [] then
      []
    else
      assert xs[0] in xs;
      assert forall x | x in xs[1..] :: x in xs;
      [xs[0].data] + ModelAux(xs[1..])
  }

  lemma ModelAuxCommutesConcat(xs: seq<Node<A>>, ys: seq<Node<A>>)
    ensures ModelAux(xs + ys) == ModelAux(xs) + ModelAux(ys)
  {
    if xs == [] {
      calc == {
        ModelAux(xs + ys);
        ModelAux([] + ys);
        { assert [] + ys == ys; }
        ModelAux(ys);
        [] + ModelAux(ys);
        ModelAux([]) + ModelAux(ys);
      }
    } else {
      assert xs == [xs[0]] + xs[1..];
      assert (xs + ys)[1..] == xs[1..] + ys;
      calc == {
        ModelAux(xs + ys);
        [xs[0].data] + ModelAux(xs[1..] + ys);
        { ModelAuxCommutesConcat(xs[1..], ys); }
        [xs[0].data] + ModelAux(xs[1..]) + ModelAux(ys);
        ModelAux(xs) + ModelAux(ys);
      }
    }
  }

  function Model(): seq<A>
    reads this, spine
    requires Valid()
  {
    ModelAux(spine)
  }

  constructor()
    ensures Valid()
    ensures Model() == []
    ensures fresh(Repr())
  {
    head := null;
    spine := [];
  }

  method Copy(other: List<A>)
    modifies this
    requires other.Valid()
    ensures Valid()
    ensures Model() == other.Model()
    ensures Repr() == other.Repr()
  {
    head := other.head;
    spine := other.spine;
  }

  method Pop() returns (res: A)
    modifies this
    requires Valid()
    requires Model() != []
    ensures Valid()
    ensures [res] + Model() == old(Model())
    ensures Repr() < old(Repr())
  {
    res := head.data;
    if head.next == null {  // Ghost code to prove `Valid()`
      if |spine| != 1 {
        assert |spine| >= 2;
        assert spine[0].next == spine[1];
        assert false;
      } else {
        assert spine == [head];
      }
      assert spine == [head];
    }
    HeadNotInTail();
    head := head.next;
    spine := spine[1..];
    if head == null {  // Ghost code to prove `Valid()`
      assert spine == [];
    }
    assert old(spine[0]) !in Repr();
    assert old(spine[0]) in old(Repr());
    assert Repr() < old(Repr());
  }

  method Push(x: A)
    modifies this
    requires Valid()
    ensures Valid()
    ensures Model() == [x] + old(Model())
    ensures Repr() > old(Repr())
    ensures fresh(Repr() - old(Repr()))
  {
    head := new Node(x, head);
    spine := [head] + spine;
    assert head !in old(Repr());
  }

  method Append(other: List<A>)
    modifies this, Repr()
    requires Valid()
    requires other.Valid()
    // needed so that we don't build a cyclic list:
    requires Repr() !! other.Repr()
    ensures Valid()
    ensures Model() == old(Model()) + other.Model()
    ensures Repr() == old(Repr()) + other.Repr()
  {
    if head == null {
      head := other.head;
      spine := other.spine;
    } else {
      var last := head;
      ghost var i := 0;
      while last.next != null
        decreases |spine| - i
        invariant last != null
        invariant 0 <= i < |spine|
        invariant spine[i] == last
      {
        last := last.next;
        i := i + 1;
      }
      NextNullImpliesLast(last);
      last.next := other.head;
      spine := spine + other.spine;
      ModelAuxCommutesConcat(old(spine), other.spine);
    }
  }

  method PopPush(other: List<A>)
    modifies this, other
    requires head != null
    requires Valid()
    requires other.Valid()
    requires Repr() !! other.Repr()
    ensures Repr() !! other.Repr()
    ensures Valid()
    ensures other.Valid()
    ensures old(Repr()) > Repr()
    ensures old(other.Repr()) < other.Repr()
    ensures Seq.Rev(old(Model())) + old(other.Model())
      == Seq.Rev(Model()) + other.Model()
  {
    var x := Pop();
    other.Push(x);
  }

  method Reverse()
    modifies this
    requires Valid()
    ensures Valid()
    ensures Model() == Seq.Rev(old(Model()))
  {
    var aux := new List();
    aux.head := head;
    aux.spine := spine;
    head := null;
    spine := [];
    while aux.head != null
      decreases aux.Repr()
      invariant Valid()
      invariant aux.Valid()
      invariant Seq.Rev(old(Model())) == Seq.Rev(aux.Model()) + Model()
      invariant Repr() !! aux.Repr();
    {
      aux.PopPush(this);
    }
  }

  method Insert(mid: Node<A>, x: A)
    modifies this, mid
    requires Valid()
    requires mid in Repr()
    ensures Valid()
  {
    DistinctSpine();
    var n := new Node(x, mid.next);
    mid.next := n;
    var i :| 0 <= i < |spine| && spine[i] == mid;
    spine := spine[..i+1] + [n] + spine[i+1..];
  }
}

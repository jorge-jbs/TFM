include "../../../src/Utils.dfy"
include "../../../src/linear/interface/Stack.dfy"

lemma Allocated(s: set<object>)
  ensures forall x | x in s :: allocated(x)
{}

lemma {:verify true} lemma1(v: array<int>, i: int)
  requires forall i | 0 <= i < v.Length - 1 :: abs(v[i]) <= abs(v[i+1])
  requires 0 <= i <= v.Length
  ensures forall j, k | 0 <= j < k < i :: abs(v[j]) <= abs(v[k])
{
  if i == 0 {
  } else if i == 1 {
  } else if i == 2 {
  } else {
    lemma1(v, i-1);
    assert abs(v[i-2]) <= abs(v[i-1]);
  }
}

method {:verify false} Reverse(st: Stack)
  modifies st, st.Repr()
  requires st.Valid()
  ensures st.Valid()
  ensures st.Model() == Seq.Rev(old(st.Model()))
  ensures forall x | x in st.Repr() - old(st.Repr()) :: fresh(x)

  requires forall x | x in st.Repr() :: allocated(x)
  ensures forall x | x in st.Repr() :: allocated(x)
{}

method {:verify true} split(v: array<int>, neg: Stack, pos: Stack)
  modifies pos, pos.Repr(), neg, neg.Repr()

  requires v !in neg.Repr() && v !in pos.Repr()
  ensures v !in neg.Repr() && v !in pos.Repr()
  // ensures v[..] == old(v[..])

  requires neg != pos
  requires neg !in pos.Repr()
  requires pos !in neg.Repr()
  requires pos.Repr() !! neg.Repr()
  requires neg.Valid()
  requires pos.Valid()
  requires neg.Empty()
  requires pos.Empty()

  requires forall i | 0 <= i < v.Length - 1 :: abs(v[i]) <= abs(v[i+1])

  ensures neg != pos
  ensures pos.Valid()
  ensures neg.Valid()
  ensures pos.Repr() !! neg.Repr()

  ensures forall x | x in neg.Repr() - old(neg.Repr()) :: fresh(x)
  ensures forall x | x in neg.Model() :: x < 0
  ensures forall i | 0 <= i < |neg.Model()| - 1 :: abs(neg.Model()[i]) >= abs(neg.Model()[i+1])

  ensures forall x | x in pos.Repr() - old(pos.Repr()) :: fresh(x)
  ensures forall x | x in pos.Model() :: x >= 0
  ensures forall i | 0 <= i < |pos.Model()| - 1 :: abs(pos.Model()[i]) >= abs(pos.Model()[i+1])

  ensures Seq.MElems(neg.Model()) + Seq.MElems(pos.Model()) == Seq.MElems(v[..])

  requires forall x | x in neg.Repr() :: allocated(x)
  requires forall x | x in pos.Repr() :: allocated(x)
  ensures forall x | x in neg.Repr() :: allocated(x)
  ensures forall x | x in pos.Repr() :: allocated(x)
{
  var i := 0;
  while i < v.Length
    invariant i <= v.Length

    invariant forall i | 0 <= i < v.Length - 1 :: abs(v[i]) <= abs(v[i+1])

    invariant forall x | x in neg.Repr() - old(neg.Repr()) :: fresh(x)
    invariant forall x | x in pos.Repr() - old(pos.Repr()) :: fresh(x)
    invariant neg != pos
    invariant neg !in pos.Repr()
    invariant pos !in neg.Repr()
    invariant neg.Repr() !! pos.Repr()
    invariant neg.Valid()
    invariant pos.Valid()

    invariant forall x | x in neg.Model() :: x < 0
    invariant forall i | 0 <= i < |neg.Model()| - 1 :: abs(neg.Model()[i]) >= abs(neg.Model()[i+1])

    invariant forall x | x in pos.Model() :: x >= 0
    invariant forall i | 0 <= i < |pos.Model()| - 1 :: abs(pos.Model()[i]) >= abs(pos.Model()[i+1])

    invariant Seq.MElems(neg.Model()) + Seq.MElems(pos.Model())
      == Seq.MElems(v[..i])

    invariant forall x | x in neg.Repr() :: allocated(x)
    invariant forall x | x in pos.Repr() :: allocated(x)
  {
    lemma1(v, i+1);
    assert forall j | 0 <= j < i :: abs(v[j]) <= abs(v[i]);
    if v[i] < 0 {
      if |neg.Model()| > 0 {
        assert neg.Model()[0] in Seq.MElems(neg.Model());
        assert neg.Model()[0] in Seq.MElems(neg.Model()) + Seq.MElems(pos.Model());
        assert neg.Model()[0] in Seq.MElems(v[..i]);
        assert neg.Model()[0] in v[..i];
        assert abs(v[i]) >= abs(neg.Model()[0]);
      }
      neg.Push(v[i]);
    } else {
      if |pos.Model()| > 0 {
        assert pos.Model()[0] in Seq.MElems(pos.Model());
        assert pos.Model()[0] in Seq.MElems(neg.Model()) + Seq.MElems(pos.Model());
        assert pos.Model()[0] in Seq.MElems(v[..i]);
        assert pos.Model()[0] in v[..i];
        assert abs(v[i]) >= abs(pos.Model()[0]);
      }
      pos.Push(v[i]);
    }
    i := i + 1;
  }
  assert v[..i] == v[..];
}

method {:verify true} FillFromStack(r: array<int>, i: nat, st: Stack) returns (l: nat)
  modifies r, st, st.Repr()
  requires st.Valid()
  // we have to say that r is not equal to st even though they are not of the same type:
  requires {r} !! {st} + st.Repr()
  requires i + |st.Model()| <= r.Length
  ensures st.Valid()
  ensures st.Empty()
  ensures forall x | x in st.Repr() - old(st.Repr()) :: fresh(x)
  ensures forall x | x in st.Repr() :: allocated(x)
  ensures r[..i] == old(r[..i])
  ensures r[i..i+old(|st.Model()|)] == old(st.Model())
  ensures r[i+old(|st.Model()|)..] == old(r[i+|st.Model()|..])
  // ensures Seq.MElems(r[i..i+old(|st.Model()|)]) == Seq.MElems(old(st.Model()))
  ensures l == i + old(|st.Model()|)

  requires forall x | x in st.Repr() :: allocated(x)
  ensures forall x | x in st.Repr() :: allocated(x)
{
  l := 0;
  while !st.Empty()
    decreases |st.Model()|

    invariant st.Valid()
    invariant {r} !! {st} + st.Repr()
    invariant forall x | x in st.Repr() - old(st.Repr()) :: fresh(x)
    invariant forall x | x in st.Repr() :: allocated(x)

    invariant 0 <= l <= old(|st.Model()|)
    invariant l == old(|st.Model()|) - |st.Model()|

    invariant st.Model() == old(st.Model()[l..])
    invariant r[..i] == old(r[..i])
    invariant r[i..i+l] == old(st.Model()[..l])
    invariant r[i+old(|st.Model()|)..] == old(r[i+|st.Model()|..])
  {
    var x := st.Pop();
    r[i+l] := x;
    l := l + 1;
  }
  l := l + i;
}

lemma LastLemma(neg: seq<int>, pos: seq<int>, s: seq<int>)
  requires forall x | x in neg :: x < 0
  requires forall i | 0 <= i < |neg|-1 :: abs(neg[i]) >= abs(neg[i+1])

  requires forall x | x in pos :: x >= 0
  requires forall i | 0 <= i < |pos|-1 :: abs(pos[i]) >= abs(pos[i+1])

  requires neg + Seq.Rev(pos) == s

  ensures forall i | 0 <= i < |s|-1 :: s[i] <= s[i+1]
{
  assert forall x | x in neg :: x < 0 && abs(x) == -x;
  assert forall i | 0 <= i < |neg|-1 :: neg[i] <= neg[i+1];
  ghost var rpos := Seq.Rev(pos);
  Seq.ElemsRev(pos);
  assert forall x | x in pos :: x >= 0 && abs(x) == x;
  assert forall x | x in rpos :: x in pos && x >= 0;
  assert forall i | 0 <= i < |pos|-1 :: pos[i] >= pos[i+1];
  Seq.LeRev(pos);
  assert forall i | 0 <= i < |rpos|-1 :: rpos[i] <= rpos[i+1];
  ghost var i := |neg|-1;
  if 0 <= i < |s|-1 {
    assert s[i] in neg && s[i] < 0;
    assert s[i+1] in rpos && s[i+1] >= 0;
    assert s[i] <= s[i+1];
  } else {
    assert s == neg || s == rpos;
  }
}

method {:verify true} reordenandoLaCola(neg: Stack, pos: Stack, v: array<int>) returns (r: array<int>)
  modifies neg, neg.Repr()
  modifies pos, pos.Repr()
  modifies v
  requires {v} !! {neg} + neg.Repr()
  requires {v} !! {pos} + pos.Repr()
  requires {pos} + pos.Repr() !! {neg} + neg.Repr()
  requires forall i | 0 <= i < v.Length - 1 :: abs(v[i]) <= abs(v[i+1])
  requires neg.Valid() && neg.Empty()
  requires pos.Valid() && pos.Empty()
  requires forall x | x in neg.Repr() :: allocated(x)
  requires forall x | x in pos.Repr() :: allocated(x)

  // These are all true but I'm not sure if we need them
  //ensures {v} !! {neg} + neg.Repr()
  //ensures {v} !! {pos} + pos.Repr()
  //ensures {r} !! {neg} + neg.Repr()
  //ensures {r} !! {pos} + pos.Repr()
  //ensures r != v
  //ensures {pos} + pos.Repr() !! {neg} + neg.Repr()

  ensures v.Length == r.Length
  ensures Array.melems(v) == Array.melems(r)
  ensures forall i | 0 <= i < r.Length - 1 :: r[i] <= r[i+1]
{
  split(v, neg, pos);
  assert Seq.MElems(neg.Model()) + Seq.MElems(pos.Model()) == Seq.MElems(v[..]);
  calc == {
    |neg.Model()| + |pos.Model()|;
    |Seq.MElems(neg.Model())| + |Seq.MElems(pos.Model())|;
    |Seq.MElems(neg.Model()) + Seq.MElems(pos.Model())|;
    |Seq.MElems(v[..])|;
    |v[..]|;
    v.Length;
  }
  var i := 0;
  r := new int[v.Length];
  ghost var onegmodel := neg.Model();
  ghost var oposmodel := pos.Model();
  i := FillFromStack(r, i, neg);
  var j := i;
  Reverse(pos);
  i := FillFromStack(r, i, pos);
  LastLemma(onegmodel, oposmodel, r[..]);
  calc == {
    Seq.MElems(r[..]);
    Seq.MElems(onegmodel) + Seq.MElems(Seq.Rev(oposmodel));
    { Seq.MElemsRev(oposmodel); }
    Seq.MElems(onegmodel) + Seq.MElems(oposmodel);
    Seq.MElems(v[..]);
  }
}

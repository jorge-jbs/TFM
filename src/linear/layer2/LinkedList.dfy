include "../../../src/Utils.dfy"
include "../layer1/List.dfy"

trait LinkedList extends List {

  method Begin() returns (it: ListIterator)
    modifies this, Repr()
    requires Valid()
    requires forall x | x in Repr()::allocated(x)
    ensures Valid()
    ensures Model() == old(Model())

    ensures forall x {:trigger x in Repr(), x in old(Repr())}| x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures fresh(it)
    ensures Iterators() == {it} + old(Iterators())
    ensures it.Valid()
    ensures it.Index() == 0
    ensures it.Parent() == this
    ensures forall it | it in old(Iterators()) && old(it.Valid()) ::
      it.Valid() && it.Index() == old(it.Index())

  function method Front(): int
    reads this, Repr()
    requires Valid()
    requires Model() != []
    ensures Valid()
    ensures Front() == Model()[0]

  method PushFront(x: int)
    modifies this, Repr()
    requires Valid()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() == [x] + old(Model())

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures Iterators() == old(Iterators())
    ensures forall it | it in Iterators() && old(it.Valid()) ::
      it.Valid() && it.Index() == old(it.Index()) + 1

  method PopFront() returns (x: int)
    modifies this, Repr()
    requires Valid()
    requires Model() != []
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures [x] + Model() == old(Model())

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures Iterators() == old(Iterators())
    ensures forall it | it in Iterators() && old(it.Valid()) && old(it.Index()) != 0 ::
      it.Valid() && it.Index() + 1 == old(it.Index())

  function method Back(): int
    reads this, Repr()
    requires Valid()
    requires Model() != []
    ensures Valid()
    ensures Back() == Model()[|Model()|-1]

  method PushBack(x: int)
    modifies this, Repr()
    requires Valid()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() == old(Model()) + [x]

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures Iterators() == old(Iterators())
    ensures forall it | it in Iterators() && old(it.Valid()) ::
      && it.Valid()
      && if old(it.Index()) == old(|Model()|) then
          it.Index() == 1 + old(it.Index())
        else
          it.Index()== old(it.Index())

  method PopBack() returns (x: int)
    modifies this, Repr()
    requires Valid()
    requires Model() != []
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() + [x] == old(Model())

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures Iterators() == old(Iterators())
    ensures
      forall it | it in Iterators() && old(it.Valid()) && old(it.Index()) != old(|Model()|-1) ::
        it.Valid()
        && if old(it.Index()) == old(|Model()|) then
            it.Index() + 1 == old(it.Index())
          else
            it.Index() == old(it.Index())

  // Insertion of x before mid, newt points to x
  method Insert(mid: ListIterator, x: int) returns (newt: ListIterator)
    modifies this, Repr()
    requires Valid()
    requires mid.Valid()
    requires mid in Iterators()
    requires mid.Parent() == this
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() == Seq.Insert(x, old(Model()), old(mid.Index()))

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures fresh(newt)
    ensures Iterators() == {newt} + old(Iterators())
    ensures newt.Valid()
    ensures newt.Parent() == this
    ensures newt.Index() == old(mid.Index())

    ensures forall it | it in old(Iterators()) && old(it.Valid()) ::
      it.Valid() &&
      if old(it.Index()) < old(mid.Index())  then
        it.Index() == old(it.Index())
      else
        it.Index() == old(it.Index()) + 1

  // Deletion of mid, next points to the next element (or past-the-end)
  method Erase(mid: ListIterator) returns (next: ListIterator)
    modifies this, Repr()
    requires Valid()
    requires mid.Valid()
    requires mid.Parent() == this
    requires mid.HasNext()
    requires mid in Iterators()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() == Seq.Remove(old(Model()), old(mid.Index()))

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures fresh(next)
    ensures Iterators() == {next} + old(Iterators())
    ensures next.Valid()
    ensures next.Parent() == this
    ensures next.Index()==old(mid.Index())
    ensures forall it |
       && it in old(Iterators())
       && old(it.Valid())
       && old(it.Index()) != old(mid.Index()) ::
         it.Valid() &&
         if old(it.Index()) < old(mid.Index())  then
           it.Index() == old(it.Index())
         else
           it.Index() == old(it.Index()) - 1
}

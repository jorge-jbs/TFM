include "../../../src/tree/layer1/UnorderedSet.dfy"


function isSortedSeq(xs:seq<int>):bool
{forall i,j::0<=i<j<|xs| ==> xs[i]<xs[j]}

function Pick(s: set<int>): int
  requires s != {}
{
  var x :| x in s; x
}

function seq2Set (xs:seq<int>):set<int>
{set x | x in xs::x}

function set2Seq(s:set<int>):seq<int>
decreases s
{
  if s == {} then []
  else 
    var y := Pick(s);
    [y] + set2Seq(s - {y})
    
}

lemma sizesSet2Seq(s:set<int>)
ensures |set2Seq(s)|==|s|
{}

lemma  sizesSeq2Set(xs:seq<int>)
requires forall i,j|0<=i<j<|xs|::xs[i]!=xs[j]
ensures |seq2Set(xs)|==|xs|
{if (xs==[]) {}
 else {sizesSeq2Set(xs[1..]);
       assert xs==[xs[0]]+xs[1..];
       assert seq2Set(xs)=={xs[0]}+seq2Set(xs[1..]);
       assert |seq2Set(xs)|==1+|seq2Set(xs[1..])|;}
}

lemma idem(s:set<int>)
ensures seq2Set(set2Seq(s)) == s 
{  if s != {} {
    var y := Pick(s);
    assert seq2Set([y] + set2Seq(s - {y})) == seq2Set([y]) + seq2Set(set2Seq(s - {y}));
  }
}

function sort(xs:seq<int>):seq<int>
ensures seq2Set(xs)==seq2Set(sort(xs)) && isSortedSeq(sort(xs))
ensures |xs|==|sort(xs)|

function set2SortedSeq(s:set<int>):seq<int>
ensures set2SortedSeq(s)==sort(set2Seq(s))
{sort(set2Seq(s))
}

lemma sortedSeq(s:set<int>)
ensures isSortedSeq(set2SortedSeq(s)) && seq2Set(set2SortedSeq(s))==s
ensures |set2SortedSeq(s)|==|s|
{idem(s);sizesSet2Seq(s);}




function {:induction s} minimum(s:set<int>):int
requires s != {}
//ensures forall x | x in s :: minimum(s)<=x
{ 
  var x :| x in s;
  if (s-{x}=={}) then x
  else if (x < minimum(s-{x})) then x
  else minimum(s-{x})

}

lemma lmin(s:set<int>,x:int)
requires s!={} && x in s
ensures x>=minimum(s)
{
  var y:| y in s;
  if (s-{y} == {}){assert s=={y};assert x==y;}
  else if (minimum(s-{y})==minimum(s)){}
  else{}
}


lemma lminimum(s:set<int>)
requires s != {}
ensures minimum(s) in s && forall x | x in s :: minimum(s) <= x
{forall x | x in s
 ensures minimum(s) <= x {lmin(s,x);}}


function {:induction s} maximum(s:set<int>):int
requires s != {}
//ensures forall x | x in s :: maximum(s)>=x
{ 
  var x :| x in s;
  if (s-{x}=={}) then x
  else if (x > maximum(s-{x})) then x
  else maximum(s-{x})

}

lemma lmax(s:set<int>,x:int)
requires s!={} && x in s
ensures x<=maximum(s)
{
  var y:| y in s;
  if (s-{y} == {}){assert s=={y};assert x==y;}
  else if (maximum(s-{y})==maximum(s)){}
  else{}
}


lemma lmaximum(s:set<int>)
requires s != {}
ensures maximum(s) in s && forall x | x in s :: maximum(s) >= x
{forall x | x in s
 ensures maximum(s) >= x {lmax(s,x);}}


function smaller(s:set<int>,x:int):set<int>
ensures forall z | z in smaller(s,x) :: z < x
{set z | z in s && z < x}

function elemth(s:set<int>,k:int):int
requires 0<=k<|s|
//ensures elemth(s,k) in s && |smaller(s,elemth(s,k))|==k
{
  var minim:=minimum(s);
  if (k==0) then minim
  else elemth(s-{minim},k-1)
}

lemma {:induction s,k} lelemth(s:set<int>,k:int)
requires 0<=k<|s|
ensures elemth(s,k) in s && |smaller(s,elemth(s,k))|==k
{ lminimum(s);
  if (k==0) { }
  else {
    lelemth(s-{minimum(s)},k-1);
    assert elemth(s,k) in s;
    calc =={
      |smaller(s,elemth(s,k))|;
      |set z | z in s && z < elemth(s,k)|;{assert k>0;}
      |set z | z in s && z < elemth(s-{minimum(s)},k-1)|;
      {assert s==(s-{minimum(s)})+{minimum(s)};
      assert minimum(s)<elemth(s-{minimum(s)},k-1);
      assert (set z | z in s && z < elemth(s-{minimum(s)},k-1))==(set z | z in s-{minimum(s)} && z < elemth(s-{minimum(s)},k-1)) + {minimum(s)};
      }
      |(set z | z in s-{minimum(s)} && z < elemth(s-{minimum(s)},k-1)) + {minimum(s)}|;
      |(set z | z in s-{minimum(s)} && z < elemth(s-{minimum(s)},k-1)) + {minimum(s)}|;

    }
  }
}


trait OrderedSetIterator extends UnorderedSetIterator{
  
  //Here "traversed" means those smaller than the element
  //it does not mean if they have been traversed or not
  //They are the |Traversed()| smaller elements of the set
  //Peek is uniquely determined from the parent set and the size of traversed, so Traversed is enough

  
  function Traversed():set<int>
    reads this, Parent(), Parent().Repr()
    requires Valid()
    requires Parent().Valid() 
    ensures Traversed()<=Parent().Model()
    ensures forall x,y | x in Traversed() && y in Parent().Model()-Traversed() :: x<y

  function method Peek(): int
    reads this, Parent(), Parent().Repr()
    requires Valid()
    requires Parent().Valid()
    requires HasNext()
    ensures Peek() in Parent().Model() && Peek() !in Traversed()
    ensures Peek()==elemth(Parent().Model(),|Traversed()|)
    ensures forall x | x in Traversed() :: x<Peek()
    ensures forall x | x in Parent().Model()-Traversed() :: Peek()<x

  function method Index(): int
    reads this, Parent(), Parent().Repr()
    requires Valid()
    requires Parent().Valid()
    ensures HasNext() ==> Index()==|Traversed()|==|smaller(Parent().Model(),Peek())|
    ensures !HasNext() ==> Index()==|Parent().Model()|
  

  method Next() returns (x: int)
    modifies this
    requires Valid()
    requires Parent().Valid()
    requires HasNext()
    requires allocated(Parent())
    requires forall it | it in Parent().Repr() :: allocated(it)
    ensures Parent().Valid()
    ensures Valid()
    ensures old(Parent()) == Parent()
    ensures old(Parent().Model()) == Parent().Model()

    ensures forall x {:trigger x in Parent().Repr(), x in old(Parent().Repr())} | x in Parent().Repr() - old(Parent().Repr()) :: fresh(x)
    ensures fresh(Parent().Repr()-old(Parent().Repr()))
    ensures forall x | x in Parent().Repr() :: allocated(x)

    ensures Parent().Iterators() == old(Parent().Iterators())
    ensures x==old(Peek()) && Traversed() == {old(Peek())}+old(Traversed()) 
    ensures |Traversed()|==1+|old(Traversed())|

    ensures forall it | it in Parent().Iterators() && old(it.Valid()) ::
      it.Valid() && (it != this ==> it.Traversed() == old(it.Traversed()) && (it.HasNext() ==> it.Peek()==old(it.Peek())))

  function method HasPrev(): bool//igual que HasNext
    reads this, Parent(), Parent().Repr()
    requires Valid()
    requires Parent().Valid()
    ensures HasPrev()  <==> Traversed() < Parent().Model() && |Traversed()| < |Parent().Model()|
    //|Traversed()| < |Parent().Model()| es necesario para poder verificar con cota |s.Model()|-|it.Traversed()|
    ensures !HasPrev() ==> Traversed() == Parent().Model() && |Traversed()| == |Parent().Model()|
  

  method Prev() returns (x: int)
    modifies this
    requires Valid()
    requires Parent().Valid()
    requires HasNext() 
    requires allocated(Parent())
    requires forall it | it in Parent().Repr() :: allocated(it)
    ensures Parent().Valid()
    ensures Valid()
    ensures old(Parent()) == Parent()
    ensures old(Parent().Model()) == Parent().Model()

    ensures forall x {:trigger x in Parent().Repr(), x in old(Parent().Repr())} | x in Parent().Repr() - old(Parent().Repr()) :: fresh(x)
    ensures fresh(Parent().Repr()-old(Parent().Repr()))
    ensures forall x | x in Parent().Repr() :: allocated(x)

    ensures Parent().Iterators() == old(Parent().Iterators())
    ensures x==old(Peek())  
    ensures old(Traversed())=={} ==> Traversed()==Parent().Model()
    ensures old(Traversed())!={} ==> Traversed()==old(Traversed())-{maximum(old(Traversed()))}
    ensures forall it | it in Parent().Iterators() && old(it.Valid()) ::
      it.Valid() && (it != this ==> it.Traversed() == old(it.Traversed()) && (it.HasNext() ==> it.Peek()==old(it.Peek())))

  method Copy() returns (it: UnorderedSetIterator)
    modifies Parent(), Parent().Repr()
    requires Valid()
    requires Parent().Valid()
    requires allocated(Parent())
    requires forall it | it in Parent().Iterators() :: allocated(it)
    ensures fresh(it)
    ensures Valid()
    ensures Parent() == old(Parent())
    ensures Parent().Valid()
    ensures Parent().Model() == old(Parent().Model())

    ensures forall x {:trigger x in Parent().Repr(), x in old(Parent().Repr())} | x in Parent().Repr() - old(Parent().Repr()) :: fresh(x)
    ensures fresh(Parent().Repr()-old(Parent().Repr()))
    ensures forall x | x in Parent().Repr() :: allocated(x)
    
    ensures it is OrderedSetIterator
    ensures it.Valid()
    ensures Parent().Iterators() == {it} + old(Parent().Iterators())
    ensures Parent() == it.Parent()

    ensures Traversed() == it.Traversed() 
    ensures forall it | it in old(Parent().Iterators()) && old(it.Valid()) ::
      it.Valid() && it.Traversed() == old(it.Traversed()) && (it.HasNext() ==> it.Peek()==old(it.Peek()))

  
}

trait OrderedSet extends UnorderedSet{
  
   //Novelties respect UnorderedSet
   // Last iterator method 
   // Find knows the traversed elements
   // Insert knows the traversed elements
   // Those methods that return iterators do return OrderedSetIterator
   // Methods receiving iterators may be called with OrderedSetIterator
   // The rest remains the same 

  function Iterators(): set<UnorderedSetIterator>
    reads this, Repr()
    requires Valid()
    ensures forall it | it in Iterators() :: it in Repr() && it.Parent() == this
    ensures forall it | it in Iterators() :: it is OrderedSetIterator

  method First() returns (it: UnorderedSetIterator)
    modifies this, Repr()
    requires Valid()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() == old(Model())

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures it is OrderedSetIterator
    ensures fresh(it)
    ensures Iterators() == {it} + old(Iterators())
    ensures it.Valid()
    ensures it.Parent() == this
    ensures it.Traversed()=={} 
    ensures Model()!={} ==> it.HasNext() && it.Peek()==elemth(Model(),0)
    ensures forall it | it in old(Iterators()) && old(it.Valid()) ::
      it.Valid() && it.Traversed() == old(it.Traversed()) && (it.HasNext() ==> it.Peek()==old(it.Peek()))


  method Last() returns (it: OrderedSetIterator)//iterator to the last element
    modifies this, Repr()
    requires Valid()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() == old(Model())

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures fresh(it)
    ensures Iterators() == {it} + old(Iterators())
    ensures it.Valid()
    ensures it.Parent() == this
    ensures Model()!={} ==> it.HasNext() && it.Traversed()==Model()-{elemth(Model(),|Model()|-1)} && it.Peek()==elemth(Model(),|Model()|-1)
    ensures Model()=={} ==> it.Traversed()=={}
    ensures forall it | it in old(Iterators()) && old(it.Valid()) ::
      it.Valid() && it.Traversed() == old(it.Traversed()) && (it.HasNext() ==> it.Peek()==old(it.Peek()))


  method find(x:int) returns (newt:UnorderedSetIterator )
    modifies this, Repr()
    requires Valid()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid() 
    ensures Model()==old(Model())
    ensures newt is OrderedSetIterator
    ensures fresh(newt) 
    ensures newt.Valid() && newt.Parent()==this
    ensures x in Model() ==> newt.HasNext() && newt.Traversed()==smaller(Model(),x) && newt.Peek()==x
    ensures x !in Model() ==> newt.Traversed()==Model()

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    ensures Iterators() == {newt}+old(Iterators())

  method insert(mid: UnorderedSetIterator, x: int) returns (newt:UnorderedSetIterator)
    modifies this, Repr()
    requires Valid()
    requires mid.Valid() 
    //mid just a hint, it is inserted where corresponds
    //efficiently or not if it respects order
    requires mid.Parent() == this
    requires mid in Iterators()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model() == old(Model()) + {x}

    
    ensures newt is OrderedSetIterator
    ensures fresh(newt)
    ensures Iterators() == {newt}+old(Iterators())
    ensures newt.Valid() && newt.Parent()==this
    ensures newt.HasNext() && newt.Traversed()==smaller(Model(),x) && newt.Peek()==x
    
    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

    //points either to the inserted elemento or to the already existing one

  method erase(mid:UnorderedSetIterator) returns (next: UnorderedSetIterator)
    modifies this, Repr()
    requires Valid()
    requires mid.Valid()
    requires mid.Parent() == this
    requires mid.HasNext()
    requires mid in Iterators()
    requires forall x | x in Repr() :: allocated(x)
    ensures Valid()
    ensures Model()== old(Model())-{old(mid.Peek())}
    
    ensures next is OrderedSetIterator
    ensures fresh(next)
    ensures Iterators() == {next}+old(Iterators())
    ensures next.Valid() && next.Parent()==this 
    ensures next.Traversed()==old(mid.Traversed())  && (next.HasNext() ==> next.Peek()==elemth(Model(),|next.Traversed()|))

    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

}



method {:verify true} try(s:OrderedSet)
modifies s, s.Repr()
requires s.Valid() && s.Empty()
requires forall x | x in s.Repr() :: allocated(x)
ensures s.Valid()
ensures forall x {:trigger x in s.Repr(), x in old(s.Repr())} | x in s.Repr() - old(s.Repr()) :: fresh(x)
ensures fresh(s.Repr()-old(s.Repr()))
ensures forall x | x in s.Repr() :: allocated(x)
{

 
 s.add(2); s.add(7); s.add(0); s.add(1);s.add(10);
 assert s.Model()=={0,1,2,7,10};

 var b:=s.contains(10);
 assert b;

 /*var it : OrderedSetIterator :=s.First(); var cont:=0;
  while (it.HasNext())
  //decreases |s.Model()|-|it.Traversed()|
  decreases |s.Model()|-it.Index()
  invariant it.Valid() && it.Parent()==s
  invariant s.Valid() && s.Model()=={0,1,2,7,10}
  invariant  forall x {:trigger x in s.Repr(), x in old(s.Repr())} | x in s.Repr() - old(s.Repr()) :: fresh(x)
  invariant fresh(s.Repr()-old(s.Repr()))
  invariant forall x | x in s.Repr() :: allocated(x)
    {var aux:=it.Next();
     if (aux%2==0) {cont:=cont+1;} 
    } 
*/
   assert s.Model()=={0,1,2,7,10};
  var it2 :=s.find(2) ;
  assert it2 is OrderedSetIterator;
  assert s is OrderedSet;
  assert 2 in s.Model();
  assert it2.Peek()==2;
  assert it2.Peek()!=5;
  assert (it2 as OrderedSetIterator).Traversed()=={0,1};//OO(
  assert it2.Index()==2;
 it2:=s.find(7); 
  assert it2.Traversed()=={0,1,2};
  assert it2.Index()==3;  
  var aux:=it2.Next();
  assert aux==7;assert it2.Index()==4;
  
  var it3:OrderedSetIterator:=s.find(7);
  it3:=s.insert(it3,5);//efficient
  assert it3.Traversed()=={0,1,2};
  assert it3.Index()==3;
  it3:=s.insert(it3,12);
    assert it3.Traversed()=={0,1,2,5,7,10};
  assert it3.Index()==6;
  //assert maximum(it3.Traversed())==10;
  var z:=it3.Prev();

  var it4:=s.Last();
  z:=it4.Prev();
  z:=it4.Prev();

  assert z==10;
  z:=it4.Prev();
  z:=it4.Prev();
  z:=it4.Prev();
  z:=it4.Prev();
  z:=it4.Prev();
  z:=it4.Prev();
  assert !it4.HasPrev();

}
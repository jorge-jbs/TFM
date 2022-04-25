include "../../src/Order.dfy"

datatype tree<A> = Empty | Node(left: tree<A>, data: A, right: tree<A>)

function method {:verify false} Leaf<A>(d: A): tree<A>
{
  Node(Empty, d, Empty)
}

function method {:verify false} elems<A>(t: tree<A>): set<A>
  ensures t.Empty? ==> elems(t) == {}
  ensures !t.Empty? ==> elems(t) == elems(t.left) + {t.data} + elems(t.right)
{
  match t {
    case Empty => {}
    case Node(l, x, r) => elems(l) + {x} + elems(r)
  }
}

function method {:verify false} melems<A>(t: tree<A>): multiset<A>
{
  match t {
    case Empty => multiset{}
    case Node(l, x, r) => melems(l) + multiset{x} + melems(r)
  }
}

function method {:verify false} fmap<A, B>(t: tree<A>, f: A -> B): tree<B>
{
  match t {
    case Empty() => Empty()
    case Node(l, x, r) => Node(fmap(l, f), f(x), fmap(r, f))
  }
}

function method {:verify false} preorder<A>(t: tree<A>): seq<A>
{
  match t {
    case Empty => []
    case Node(l, x, r) => [x] + preorder(l) + preorder(r)
  }
}

function method {:verify false} inorder<A>(t: tree<A>): seq<A>
{
  match t {
    case Empty => []
    case Node(l, x, r) => inorder(l) + [x] + inorder(r)
  }
}

function method {:verify false} revinorder<A>(t: tree<A>): seq<A>
{
  match t {
    case Empty => []
    case Node(l, x, r) => revinorder(r) + [x] + revinorder(l)
  }
}

function method {:verify false} postorder<A>(t: tree<A>): seq<A>
{
  match t {
    case Empty => []
    case Node(l, x, r) => postorder(l) + postorder(r) + [x]
  }
}

function method {:verify false} size<A>(t: tree<A>): nat
{
  |preorder(t)|
}

function method {:verify false} max(x: int, y: int): int
{
  if x < y then
    y
  else
    x
}

function method {:verify false} depth<A>(t: tree<A>): nat
{
  match t {
    case Empty => 0
    case Node(l, x, r) => max(depth(l), depth(r)) + 1
  }
}

datatype Color = Red | Black

type K = int
type V = int

class TNode {
  var key: K;
  var value: V;
  var left: TNode?;
  var right: TNode?;

  var color: Color;

  constructor(l: TNode?, k: K, v: V, r: TNode?)
    ensures left == l
    ensures key == k
    ensures value == v
    ensures right == r
  {
    key := k;
    value := v;
    left := l;
    right := r;
  }

  constructor Leaf(k: K, v: V)
  {
    key := k;
    value := v;
    left := null;
    right := null;
  }
}

class Tree {
  var root: TNode?;
  ghost var skeleton: tree<TNode>;

  function Repr(): set<object>
    reads this
  {
    elems(skeleton)
  }

  static predicate ValidRec(node: TNode?, sk: tree<TNode>)
    reads set x | x in elems(sk) :: x`left
    reads set x | x in elems(sk) :: x`right
  {
    match sk {
      case Empty => node == null
      case Node(l, x, r) =>
        && x == node
        && x !in elems(l)
        && x !in elems(r)
        && elems(l) !! elems(r)
        && ValidRec(node.left, l)
        && ValidRec(node.right, r)
    }
  }

  predicate Valid()
    reads this, Repr()
  {
    ValidRec(root, skeleton)
  }

  static function MapModelRec(sk: tree<TNode>): map<K, V>
    reads set x | x in elems(sk) :: x`key
    reads set x | x in elems(sk) :: x`value
    ensures forall n | n in elems(sk) :: n.key in MapModelRec(sk)
    ensures sk.Empty? ==> MapModelRec(sk) == map[]
    ensures !sk.Empty? ==> MapModelRec(sk) == (MapModelRec(sk.left)+MapModelRec(sk.right))[sk.data.key:=sk.data.value]
  {
    match sk {
      case Empty() => map[]
      case Node(l, n, r) => (MapModelRec(l) + MapModelRec(r))[n.key := n.value]
    }
  }

  function MapModel(): map<K, V>
    reads this, elems(skeleton)
    requires Valid()
  {
    MapModelRec(skeleton)
  }

  constructor()
    ensures Valid()
    ensures fresh(Repr())
    ensures MapModel() == map[]
  {
    root := null;
    skeleton := Empty;
  }

  predicate SearchTree()
    reads this, Repr()
    requires Valid()
  {
    SearchTreeRec(skeleton)
  }

  static predicate SearchTreeRec(sk: tree<TNode>)
    reads set x | x in elems(sk) :: x`key
  {
    match sk {
      case Empty() => true
      case Node(l, n, r) =>
        && (forall m | m in elems(l) :: m.key < n.key)
        && (forall m | m in elems(r) :: n.key < m.key)
        && SearchTreeRec(l)
        && SearchTreeRec(r)
    }
  }

  lemma {:verify false} ModelRelationWithSkeleton(k: K, v: V)
    requires Valid()
    requires SearchTree()
    ensures k in MapModel() && MapModel()[k] == v <==> exists n | n in elems(skeleton) :: n.key == k && n.value == v
  {
    if k in MapModel() && MapModel()[k] == v {
      ModelRelationWithSkeletonRecR(root, skeleton, k, v);
    }
    if exists n | n in elems(skeleton) :: n.key == k && n.value == v {
      ModelRelationWithSkeletonRecL(root, skeleton, k, v);
    }
  }

  static lemma {:verify false} ModelRelationWithSkeletonRecR(node: TNode?, sk: tree<TNode>, k: K, v: V)
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    requires k in MapModelRec(sk)
    requires MapModelRec(sk)[k] == v
    ensures (exists n | n in elems(sk) :: n.key == k && n.value == v)
  {}

  static lemma {:verify false} ModelRelationWithSkeletonRecL(node: TNode?, sk: tree<TNode>, k: K, v: V)
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    requires (exists n | n in elems(sk) :: n.key == k && n.value == v)
    ensures k in MapModelRec(sk)
    ensures MapModelRec(sk)[k] == v
  {
    match sk {
      case Empty => {}
      case Node(l, n, r) => {
        if n.key == k {
        } else if k < n.key {
          assert k in MapModelRec(l);

          assert forall m | m in elems(r) :: n.key != m.key;
          if k in MapModelRec(r) {
            ModelRelationWithSkeletonKeyRecR(n.right, r, k);
            assert false;
          }
          assert k !in MapModelRec(r);

          assert MapModelRec(sk)[k] == v;
        } else if n.key < k {
        } else {
          assert false;
        }
      }
    }
  }

  lemma {:verify false} ModelRelationWithSkeletonKey(k: K)
    requires Valid()
    requires SearchTree()
    ensures k in MapModel() <==> exists n | n in elems(skeleton) :: n.key == k
  {
    ModelRelationWithSkeletonKeyRec(root, skeleton, k);
  }

 static lemma {:verify false} ModelRelationWithSkeletonKeyRec(node: TNode?, sk: tree<TNode>,k: K)
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    ensures k in MapModelRec(sk) <==> (exists n | n in elems(sk) :: n.key == k)
  {
    if k in MapModelRec(sk) {
      ModelRelationWithSkeletonKeyRecR(node, sk, k);
    }
    if exists n | n in elems(sk) :: n.key == k {
      ModelRelationWithSkeletonKeyRecL(node, sk, k);
    }
  }

  static lemma {:verify false} ModelRelationWithSkeletonKeyRecR(node: TNode?, sk: tree<TNode>, k: K)
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    requires k in MapModelRec(sk)
    ensures (exists n | n in elems(sk) :: n.key == k)
  {}

  static lemma {:verify false} ContraModelRelationWithSkeletonKeyRecR(node: TNode?, sk: tree<TNode>, k: K)
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    requires forall m | m in elems(sk) :: k != m.key;
    ensures k !in MapModelRec(sk)
  {
      if k in MapModelRec(sk) {
        ModelRelationWithSkeletonKeyRecR(node, sk, k);
        assert false;
      }
      assert k !in MapModelRec(sk);
  }

  static lemma {:verify false} ModelRelationWithSkeletonKeyRecL(node: TNode?, sk: tree<TNode>, k: K)
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    requires (exists n | n in elems(sk) :: n.key == k)
    ensures k in MapModelRec(sk)
  {
    match sk {
      case Empty => {}
      case Node(l, n, r) => {}
    }
  }

  function method {:verify false} isEmpty(): bool
    reads this, Repr()
    requires Valid()
    ensures isEmpty() <==> MapModel() == map[]
  { root==null }

  function method {:verify false} Size():nat
    reads this, Repr()
    requires Valid()
    ensures Size() == |MapModel()|
  //TO  DO:añadir tamaño

  static method {:verify false} GetRec(n: TNode, ghost sk: tree<TNode>, k: K) returns (v: V)
    requires ValidRec(n, sk)
    requires SearchTreeRec(sk)
    //requires exists n | n in elems(sk) :: n.key == k
    requires k in MapModelRec(sk)

    ensures ValidRec(n, sk)
    ensures SearchTreeRec(sk)
    ensures exists n | n in elems(sk) :: n.key == k && n.value == v
    ensures MapModelRec(sk)==old(MapModelRec(sk))
    ensures MapModelRec(sk)[k]==v

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(sk), x in old(elems(sk))} | x in elems(sk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(sk)-old(elems(sk)))
    ensures forall x | x in elems(sk) :: allocated(x)

  static method {:verify false} SearchRec(n: TNode, ghost sk: tree<TNode>, k: K) returns (b:bool, ghost z:TNode)
    requires ValidRec(n, sk)
    requires SearchTreeRec(sk)
    ensures ValidRec(n, sk)
    ensures SearchTreeRec(sk)
    ensures b == exists n | n in elems(sk) :: n.key == k
    ensures b ==> z in elems(sk) && z.key==k

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(sk), x in old(elems(sk))} | x in elems(sk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(sk)-old(elems(sk)))
    ensures forall x | x in elems(sk) :: allocated(x)

  static method {:verify false} FindRec(node: TNode?, ghost sk: tree<TNode>, k: K) returns (found: TNode?)
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)

    ensures ValidRec(node, sk)
    ensures SearchTreeRec(sk)
    //ensures MapModelRec(sk) == old(MapModelRec(sk))
    ensures found != null ==> found.key == k

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(sk), x in old(elems(sk))} | x in elems(sk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(sk)-old(elems(sk)))
    ensures forall x | x in elems(sk) :: allocated(x)
  {
    if node == null {
      found := null;
    } else {
      if k == node.key {
        found := node;
      } else if node.key < k {
        found := FindRec(node.right, sk.right, k);
      } else if k < node.key {
        found := FindRec(node.left, sk.left, k);
      } else {
        assert false;
      }
    }
  }

  method {:verify true} Find(k: K) returns (found: TNode?)
    requires Valid()
    requires SearchTree()

    //ensures Valid()
    //ensures SearchTree()
    //ensures MapModel() == old(MapModel())
    //ensures found != null ==> found.key == k

    requires forall x | x in Repr() :: allocated(x)
    //ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    //ensures fresh(Repr()-old(Repr()))
    //ensures forall x | x in Repr() :: allocated(x)
  {
    //found := FindRec(root, skeleton, k);
  }

  method {:verify false} Search(k: K) returns (b:bool)
    requires Valid()
    requires SearchTree()
    ensures Valid()
    ensures SearchTree()
    ensures b == (k in MapModel())

    requires forall x | x in Repr() :: allocated(x)
    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() :: allocated(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)

  method {:verify false} Get(k: K) returns (v: V)
    requires Valid()
    requires SearchTree()
    requires k in MapModel()
    ensures Valid()
    ensures SearchTree()
    ensures k in MapModel()
    ensures MapModel()[k] == v

    requires forall x | x in Repr() :: allocated(x)
    ensures forall x | x in Repr() :: allocated(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)
  {
    assert Repr() == elems(skeleton);
    v := GetRec(root, skeleton, k);
  }

static lemma {:verify false}  pushUpMapL(ml:map<K,V>, mr:map<K,V>, k:K, v:V)
  requires k !in mr
  ensures ml[k:=v]+mr == (ml+mr)[k:=v]
{}

static lemma {:verify false}  pushUpMapR(ml:map<K,V>, mr:map<K,V>, k:K, v:V)
  ensures (ml+mr)[k:=v]==ml+mr[k:=v]
{}

static lemma {:verify false}  pushUpMapD(ml:map<K,V>, mr:map<K,V>, k:K)
  requires k !in mr
  ensures ml-{k}+mr == (ml+mr)-{k}
{}

static lemma {:verify false}  pushUpMapDR(ml:map<K,V>, mr:map<K,V>, k:K)
  requires k !in ml
  ensures ml+(mr-{k}) == (ml+mr)-{k}
{}

static lemma {:verify false}  deletion(m:map<K,V>, m':map<K,V>, k:K,v:V)
  requires m==m'[k:=v] && k !in m'
  ensures m-{k}==m'
{}

static lemma {:verify false} idem(m:map<K,V>,k:K,v:V)
  requires k in m && m[k]==v
  ensures (m-{k})[k:=v]==m
{}

static lemma {:verify false} idem2(m:map<K,V>,k:K,v:V)
  requires k !in m
  ensures (m[k:=v])-{k}==m
{}

static lemma {:verify false} keysSearchTree(sk:tree<TNode>,k:K)
  requires SearchTreeRec(sk)  && sk !=Empty()
  ensures (set n | n in elems(sk)::n.key) == MapModelRec(sk).Keys
  ensures sk.data.key !in MapModelRec(sk.left) && sk.data.key !in MapModelRec(sk.right)
  ensures MapModelRec(sk.left).Keys !! MapModelRec(sk.right).Keys
  ensures MapModelRec(sk).Keys==MapModelRec(sk.left).Keys+MapModelRec(sk.right).Keys+{sk.data.key}
  ensures  k < sk.data.key ==> k !in MapModelRec(sk.right)
  ensures  k > sk.data.key ==> k !in MapModelRec(sk.left)
{}

static lemma {:verify false} keysSearchTreeP(sk:tree<TNode>)
  requires SearchTreeRec(sk)  && sk !=Empty()
  ensures (set n | n in elems(sk)::n.key) == MapModelRec(sk).Keys
  ensures sk.data.key !in MapModelRec(sk.left) && sk.data.key !in MapModelRec(sk.right)
  ensures MapModelRec(sk.left).Keys !! MapModelRec(sk.right).Keys
  ensures MapModelRec(sk).Keys==MapModelRec(sk.left).Keys+MapModelRec(sk.right).Keys+{sk.data.key}
{}

static lemma {:verify false} oldNewMapModelRecL(newSk:tree<TNode>, moSk:map<K,V>,mskL:map<K,V>,mskR:map<K,V>,node:TNode,k:K,v:V)
  requires ValidRec(node,newSk) && SearchTreeRec(newSk)
  requires newSk!=Empty
  requires MapModelRec(newSk.left)==mskL[k:=v]
  requires MapModelRec(newSk.right)==mskR
  requires node.key !in mskL && node.key !in mskR && node.key !=k && k !in mskR
  requires moSk==(mskL+mskR)[node.key:=node.value]
  ensures MapModelRec(newSk)==moSk[k:=v]
{
  calc == {
    MapModelRec(newSk);
    (MapModelRec(newSk.left)+MapModelRec(newSk.right))[node.key:=node.value];
    (mskL[k:=v]+mskR)[node.key:=node.value];
    { pushUpMapR(mskL[k:=v],mskR,node.key,node.value);}
    mskL[k:=v]+mskR[node.key:=node.value];
    {
      assert k !in mskR[node.key:=node.value];
      pushUpMapL(mskL,mskR[node.key:=node.value],k,v);
    }
    ((mskL+mskR)[node.key:=node.value])[k:=v];
    moSk[k:=v];
  }
}

static lemma {:verify false} oldNewMapModelRecR(newSk:tree<TNode>, moSk:map<K,V>,mskL:map<K,V>,mskR:map<K,V>,node:TNode,k:K,v:V)
  requires ValidRec(node,newSk) && SearchTreeRec(newSk)
  requires newSk!=Empty
  requires MapModelRec(newSk.left)==mskL
  requires MapModelRec(newSk.right)==mskR[k:=v]
  requires node.key !in mskL && node.key !in mskR && node.key !=k
  requires moSk==(mskL+mskR)[node.key:=node.value]
  ensures MapModelRec(newSk)==moSk[k:=v]
{
  calc == {
    MapModelRec(newSk);
    (MapModelRec(newSk.left)+MapModelRec(newSk.right))[node.key:=node.value];
    (mskL+mskR[k:=v])[node.key:=node.value];
    { pushUpMapR(mskL[k:=v],mskR,node.key,node.value); }
    mskL+mskR[k:=v][node.key:=node.value];
    { assert k != node.key; }
    mskL+mskR[node.key:=node.value][k:=v];
    { pushUpMapR(mskL,mskR[node.key:=node.value],k,v); }
    ((mskL+mskR)[node.key:=node.value])[k:=v];
    moSk[k:=v];
  }
}

 static method {:verify false} InsertRec(node: TNode?, ghost sk: tree<TNode>, k: K, v: V) returns (newNode: TNode, ghost newSk: tree<TNode>, ghost insertedNode:TNode)
    modifies set x | x in elems(sk) :: x`left
    modifies set x | x in elems(sk) :: x`right
    modifies set x | x in elems(sk) :: x`value
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)

    ensures ValidRec(newNode, newSk)
    ensures SearchTreeRec(newSk)
    ensures MapModelRec(newSk)==old(MapModelRec(sk))[k:=v]

    ensures elems(newSk) == elems(sk)+{insertedNode}
    ensures insertedNode.key == k && insertedNode.value == v
    ensures forall n | n in elems(sk) && old(n.key) != k ::
      n.key == old(n.key) && n.value == old(n.value)

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(newSk), x in old(elems(newSk))} | x in elems(newSk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(newSk)-old(elems(sk)))
    ensures forall x | x in elems(newSk) :: allocated(x)
  {
    if node == null {
      newNode := new TNode(null, k, v, null);
      newSk := Node(Empty, newNode, Empty);
      insertedNode:=newNode;
    } else {
       assert sk.data==node;
      newNode := node;
      if k == node.key {
        node.value := v;
        newSk := sk;
        insertedNode:=node;
      } else if node.key < k {
        ghost var newSkRight;
        node.right, newSkRight, insertedNode := InsertRec(node.right, sk.right, k, v);
        newSk := Node(sk.left, node, newSkRight);
      } else if k < node.key {
        ghost var oMMRight:=MapModelRec(sk.right);
        ghost var oMMLeft:=MapModelRec(sk.left);
        ghost var oMM:=MapModelRec(sk);
        keysSearchTree(sk,k);
        ghost var newSkLeft;
        node.left, newSkLeft,insertedNode := InsertRec(node.left, sk.left, k, v);
        newSk := Node(newSkLeft, node, sk.right);

        assert node.key!=k;
        assert node.key==old(node.key) && node.value==old(node.value);
        assert node.key !in oMMLeft && node.key !in oMMRight && node.key !=k;

        assert newSk.left==newSkLeft && newSk.right==sk.right && newSk.data==node;
        assert MapModelRec(newSk.left)==oMMLeft[k:=v];
        assert MapModelRec(newSk.right)==oMMRight;
        assert oMM==(oMMLeft+oMMRight)[node.key:=node.value];
        oldNewMapModelRecL(newSk,old(MapModelRec(sk)),oMMLeft,oMMRight,node,k,v);
      } else {
        assert false;
      }
    }
  }

  method {:verify false} Insert(k: K, v: V)
    modifies this, Repr()
    requires Valid()
    requires SearchTree()
    ensures Valid()
    ensures SearchTree()
    ensures MapModel() == old(MapModel())[k := v]

    requires forall x | x in Repr() :: allocated(x)
    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)
  {
    ghost var z;
    root, skeleton, z := InsertRec(root, skeleton, k, v);
  }

static lemma {:verify false} oldNewMapModelRecRemoveL(newSk:tree<TNode>, moSk:map<K,V>,mskL:map<K,V>,mskR:map<K,V>,node:TNode,k:K)
  requires ValidRec(node,newSk) && SearchTreeRec(newSk)
  requires newSk!=Empty
  requires MapModelRec(newSk.left)==mskL-{k}
  requires MapModelRec(newSk.right)==mskR
  requires node.key !in mskL && node.key !in mskR && node.key !=k && k !in mskR
  requires moSk==(mskL+mskR)[node.key:=node.value]
ensures MapModelRec(newSk)==moSk-{k}
{
  calc == {
    MapModelRec(newSk);
    (MapModelRec(newSk.left)+MapModelRec(newSk.right))[node.key:=node.value];
    (mskL-{k}+mskR)[node.key:=node.value];
    { assert node.key !in mskR;
    pushUpMapR(mskL-{k},mskR,node.key,node.value);}
    mskL-{k}+mskR[node.key:=node.value];
    { assert k !in mskR[node.key:=node.value];
    pushUpMapD(mskL,mskR[node.key:=node.value],k);}
    ((mskL+mskR)[node.key:=node.value])-{k};
    moSk-{k};
  }
}

static lemma {:verify false} oldNewMapModelRecRemoveR(newSk:tree<TNode>, moSk:map<K,V>,mskL:map<K,V>,mskR:map<K,V>,node:TNode,k:K)
  requires ValidRec(node,newSk) && SearchTreeRec(newSk)
  requires newSk!=Empty
  requires MapModelRec(newSk.left)==mskL
  requires MapModelRec(newSk.right)==mskR-{k}
  requires node.key !in mskL && node.key !in mskR && node.key !=k && k !in mskL
  requires moSk==(mskL+mskR)[node.key:=node.value]
  ensures MapModelRec(newSk)==moSk-{k}
{
  calc == {
    MapModelRec(newSk);
    (MapModelRec(newSk.left)+MapModelRec(newSk.right))[node.key:=node.value];
    (mskL+(mskR-{k}))[node.key:=node.value];
    { assert k !in mskL;
    pushUpMapDR(mskL,mskR,k);}
    ((mskL+mskR)-{k})[node.key:=node.value];
    { assert node.key!=k; }
    ((mskL+mskR)[node.key:=node.value])-{k};
    moSk-{k};
  }
}

static lemma {:verify false} oldNewMapModelRecRemoveRMin(newSk:tree<TNode>, moSk:map<K,V>,mskL:map<K,V>,mskR:map<K,V>,node:TNode,newNode:TNode)
  requires ValidRec(newNode,newSk) && SearchTreeRec(newSk)
  requires newSk!=Empty
  requires MapModelRec(newSk.left)==mskL
  requires MapModelRec(newSk.right)==mskR-{newNode.key}
  requires node.key !in mskL && node.key !in mskR
  requires newNode.key in mskR && mskR[newNode.key]==newNode.value
  requires moSk==(mskL+mskR)[node.key:=node.value]
  ensures MapModelRec(newSk)==moSk-{node.key}
{
  calc == {
    MapModelRec(newSk);
    (MapModelRec(newSk.left)+MapModelRec(newSk.right))[newNode.key:=newNode.value];
    (mskL+(mskR-{newNode.key}))[newNode.key:=newNode.value];
    { pushUpMapR(mskL,mskR-{newNode.key},newNode.key,newNode.value); }
    mskL+(mskR-{newNode.key})[newNode.key:=newNode.value];
    {idem(mskR,newNode.key,newNode.value);}
    mskL+mskR;
    { idem2(mskL+mskR,node.key,node.value); }
    ((mskL+mskR)[node.key:=node.value])-{node.key};
    moSk-{node.key};
  }
}

  static method {:verify false} RemoveMinRec(node: TNode, ghost sk: tree<TNode>) returns (newNode: TNode?, ghost newSk: tree<TNode>, removedNode: TNode)
    modifies set x | x in elems(sk) :: x`left

    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    ensures ValidRec(newNode, newSk)
    ensures SearchTreeRec(newSk)

    ensures removedNode in elems(sk)
    ensures removedNode !in elems(newSk)
    ensures removedNode.key == old(removedNode.key)
    ensures removedNode.value == old(removedNode.value)
    ensures elems(newSk) + {removedNode} == elems(sk)

    ensures removedNode.key in old(MapModelRec(sk))
    ensures old(MapModelRec(sk))[removedNode.key] == removedNode.value
    ensures MapModelRec(newSk) == old(MapModelRec(sk)) - {removedNode.key}

    ensures forall n | n in elems(sk) :: n.key==old(n.key) && n.value==old(n.value)
    ensures forall n | n in elems(sk) && n.key != removedNode.key :: removedNode.key < n.key

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(sk), x in old(elems(sk))} | x in elems(sk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(sk)-old(elems(sk)))
    ensures forall x | x in elems(sk) :: allocated(x)
  {
    keysSearchTreeP(sk);

    if node.left == null {
      ghost var oMMRight:=MapModelRec(sk.right);
      ghost var oMM:=MapModelRec(sk);
      deletion(oMM, oMMRight, node.key, node.value);

      newNode := node.right;
      newSk := sk.right;
      removedNode := node;
    } else {
      ghost var oMMRight := MapModelRec(sk.right);
      ghost var oMMLeft := MapModelRec(sk.left);
      ghost var oMM := MapModelRec(sk);

      ghost var newSkLeft;
      node.left, newSkLeft, removedNode := RemoveMinRec(node.left, sk.left);

      newNode:=node;
      newSk := Node(newSkLeft, newNode, sk.right);

      oldNewMapModelRecRemoveL(newSk,oMM,oMMLeft,oMMRight,node,removedNode.key);
    }
  }

  static method {:verify false} RemoveRec(node: TNode?, ghost sk: tree<TNode>, k: K) returns (newNode: TNode?, ghost newSk: tree<TNode>, ghost removedNode: TNode?)
    modifies set x | x in elems(sk) :: x`left
    modifies set x | x in elems(sk) :: x`right
    requires ValidRec(node, sk)
    requires SearchTreeRec(sk)
    ensures ValidRec(newNode, newSk)
    ensures SearchTreeRec(newSk)

    ensures forall n | n in elems(sk) ::
      n.key == old(n.key) && n.value == old(n.value)
    ensures elems(newSk) == elems(sk) - {removedNode}
    ensures k !in old(MapModelRec(sk)) <==> removedNode==null
    ensures removedNode != null ==> removedNode in elems(sk) && removedNode !in elems(newSk) && removedNode.key == k
    ensures MapModelRec(newSk)==old(MapModelRec(sk))-{k}

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(sk), x in old(elems(sk))} | x in elems(sk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(sk)-old(elems(sk)))
    ensures forall x | x in elems(sk) :: allocated(x)
  {
    ModelRelationWithSkeletonKeyRec(node,sk,k);

    if node == null {
      newNode := node;
      newSk := sk;
      removedNode := null;
      assert MapModelRec(newSk)==old(MapModelRec(sk))-{k};
    } else {
      ghost var oMMRight:=MapModelRec(sk.right);
      ghost var oMMLeft:=MapModelRec(sk.left);
      ghost var oMM:=MapModelRec(sk);
      keysSearchTreeP(sk);
      assert node.key !in oMMLeft && node.key !in oMMRight;

      if node.key < k {
        ghost var newSkRight;
        node.right, newSkRight, removedNode := RemoveRec(node.right, sk.right, k);
        newNode := node;
        newSk := Node(sk.left, node, newSkRight);

        assert MapModelRec(newSkRight)==oMMRight-{k};
        oldNewMapModelRecRemoveR(newSk,oMM,oMMLeft,oMMRight,node,k);
        assert MapModelRec(newSk)==old(MapModelRec(sk))-{k};
      } else if k < node.key {
        newNode := node;
        ghost var newSkLeft;
        node.left, newSkLeft, removedNode := RemoveRec(node.left, sk.left, k);
        newSk := Node(newSkLeft, node, sk.right);

        assert MapModelRec(newSkLeft)==oMMLeft-{k};
        oldNewMapModelRecRemoveL(newSk,oMM,oMMLeft,oMMRight,node,k);
        assert MapModelRec(newSk)==old(MapModelRec(sk))-{k};
      } else {
        assert k == node.key;
        if node.right == null {
          newNode := node.left;
          newSk := sk.left;
          removedNode := node;

          assert oMM==oMMLeft[node.key:=node.value] && node.key !in oMMLeft;
          deletion(oMM,oMMLeft,node.key,node.value);
          assert MapModelRec(newSk)==old(MapModelRec(sk))-{k};
        } else if node.left == null {
          newNode := node.right;
          newSk := sk.right;
          removedNode := node;

          assert oMM==oMMRight[node.key:=node.value] && node.key !in oMMRight;
          deletion(oMM,oMMRight,node.key,node.value);
          assert MapModelRec(newSk)==old(MapModelRec(sk))-{k};
        } else {
          removedNode := node;
          ghost var newSkRight;
          var newRight;
          newRight, newSkRight, newNode := RemoveMinRec(node.right, sk.right);

          assert MapModelRec(newSkRight)==oMMRight-{newNode.key};
          assert newNode.key in oMMRight && oMMRight[newNode.key]==newNode.value;

          newNode.left := node.left;
          newNode.right := newRight;
          newSk := Node(sk.left, newNode, newSkRight);

          oldNewMapModelRecRemoveRMin(newSk,oMM,oMMLeft,oMMRight,node,newNode);
          assert MapModelRec(newSk)==old(MapModelRec(sk))-{k};
        }
      }
    }
  }

  method {:verify false} Remove(k: K)
    modifies this, Repr()
    requires Valid()
    requires SearchTree()
    ensures Valid()
    ensures SearchTree()
    ensures MapModel()==old(MapModel())-{k}

    requires forall x | x in Repr() :: allocated(x)
    ensures forall x {:trigger x in Repr(), x in old(Repr())} | x in Repr() - old(Repr()) :: fresh(x)
    ensures fresh(Repr()-old(Repr()))
    ensures forall x | x in Repr() :: allocated(x)
  {
    ghost var removedNode;
    root, skeleton, removedNode := RemoveRec(root, skeleton, k);
  }

  static function BlackHeight(sk: tree<TNode>): nat
    reads set x | x in elems(sk) :: x`color
  {
    match sk {
      case Empty() => 0
      case Node(l, n, r) =>
        if n.color.Black? then
          1 + max(BlackHeight(l), BlackHeight(r))
        else
          max(BlackHeight(l), BlackHeight(r))
    }
  }

  static predicate RedBlackTreeRec(sk: tree<TNode>)
    reads set x | x in elems(sk) :: x`key
    reads set x | x in elems(sk) :: x`color
  {
    match sk {
      case Empty() => true
      case Node(l, n, r) =>
        // Red links lean left:
        && (!r.Empty? ==> r.data.color.Black?)
        // No node has two red links connected to it:
        && (!l.Empty? && l.data.color.Red? && !l.left.Empty? ==> l.left.data.color.Black?)
        // && (n.color.Red? && !l.Empty? ==> l.data.color.Black?)
        // Perfect black balance:
        && BlackHeight(l) == BlackHeight(r)

        && RedBlackTreeRec(l)
        && RedBlackTreeRec(r)
    }
  }

  predicate RedBlackTree()
    reads this, Repr()
    requires Valid()
  {
    && SearchTree()
    && (root != null ==> root.color.Black?)
    && RedBlackTreeRec(skeleton)
  }

  static method {:verify false} RotateLeft(node: TNode, ghost sk: tree<TNode>) returns (newNode: TNode, ghost newSk: tree<TNode>)
    modifies set x | x in elems(sk) :: x`left
    modifies set x | x in elems(sk) :: x`right
    modifies set x | x in elems(sk) :: x`color
    requires ValidRec(node, sk)
    // requires node.left != null ==> node.left.color.Black?
    requires node.right != null
    requires node.right.color.Red?
    requires SearchTreeRec(sk)
    requires RedBlackTreeRec(sk.left)
    requires RedBlackTreeRec(sk.right)
    requires BlackHeight(sk.left) == BlackHeight(sk.right)

    ensures ValidRec(newNode, newSk)
    ensures SearchTreeRec(newSk)
    ensures BlackHeight(newSk) == old(BlackHeight(sk))
    // ensures RedBlackTreeRec(newSk)
    // ensures old(node.left != null && node.left.color.Black?) ==> RedBlackTreeRec(newSk)
    ensures
      old((node.left != null ==> node.left.color.Black?)
        && (node.right.left != null ==> node.right.left.color.Black?)
        && (node.right.right != null ==> node.right.right.color.Black?))
      ==> RedBlackTreeRec(newSk)

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(sk), x in old(elems(sk))} | x in elems(sk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(sk)-old(elems(sk)))
    ensures forall x | x in elems(sk) :: allocated(x)
  {
    newNode := node.right;
    node.right := newNode.left;
    newNode.left := node;
    newNode.color := node.color;
    node.color := Red;
    newSk := Node(Node(sk.left, node, sk.right.left), newNode, sk.right.right);
  }
  
  method {:verify false} RotateRight(node: TNode, ghost sk: tree<TNode>) returns (newNode: TNode, ghost newSk: tree<TNode>)
    modifies set x | x in elems(sk) :: x`left
    modifies set x | x in elems(sk) :: x`right
    modifies set x | x in elems(sk) :: x`color
    requires ValidRec(node, sk)
    // requires node.right != null ==> node.right.color.Black?
    requires node.left != null
    requires node.left.color.Red?
    requires SearchTreeRec(sk)
    requires RedBlackTreeRec(sk.left)
    requires RedBlackTreeRec(sk.right)
    requires BlackHeight(sk.left) == BlackHeight(sk.right)

    ensures ValidRec(newNode, newSk)
    ensures SearchTreeRec(newSk)
    ensures BlackHeight(newSk) == old(BlackHeight(sk))
    ensures RedBlackTreeRec(newSk.left)
    ensures old(node.right != null ==> node.right.color.Black?) ==> RedBlackTreeRec(newSk.right)
    
    /*
    ensures
      old(
        && node.color.Black?
        && (node.right != null ==> node.right.color.Black?)
        && (node.left.right != null ==> node.left.right.color.Black?)
        && node.left.left != null
        && (node.left.left.left != null ==> node.left.left.left.color.Black?)
        && (node.left.left.right != null ==> node.left.left.right.color.Black?)
      ) ==> (
        && node.color.Black?
        && node.left != null && node.left.color.Red?
        && (node.left.left != null ==> node.left.left.color.Black?)
        && (node.left.right != null ==> node.left.right.color.Black?)
        && node.right != null && node.right.color.Red?
        && (node.right.left != null ==> node.right.left.color.Black?)
        && (node.right.right != null ==> node.right.right.color.Black?)
      )
    */

    requires forall x | x in elems(sk) :: allocated(x)
    ensures forall x {:trigger x in elems(sk), x in old(elems(sk))} | x in elems(sk) - old(elems(sk)) :: fresh(x)
    ensures fresh(elems(sk)-old(elems(sk)))
    ensures forall x | x in elems(sk) :: allocated(x)
  {
    newNode := node.left;
    node.left := newNode.right;
    newNode.right := node;
    newNode.color := node.color;
    node.color := Red;
    newSk := Node(sk.left.left, newNode, Node(sk.left.right, node, sk.right));
  }
}
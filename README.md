# ib_gib

Infinite logic takes some getting used to, and this won't make sense and will seem like garbledy-gook to you. Say or do what you will, but remember...

Don't Panic.

## before diving in...why give a s**t about this library?

I mean...I don't even have the guts to spell out the word "shit"?! Oh wait...
yes, I do but not arbitrarily. And my answer to anyone reading this?

I don't friggin know. Ridiculously quick run down of me and ib:

* Me
  * Back in the day, used to be "smart", 800 math sat, 36 math act, 5th place
    state math tournament, 5 Physics C, 4 Physics B, 5 Calc AB, 0 homework,
  * Number 1 in the world on silly Xbox Live Brain Challenge game.
  * Started college as a sophomore, ended college as a sophomore.
  * Never could stomach philosophy, but I ate up books like Chaos; Virus of the Mind; Goedel, Escher, Bach; Relativity Visualized; Brian Green books; Lee Smolin books; etc.
  * So yes, layman, but doesn't matter. I can follow the math but disagree with
    fundamental approaches in all of these and other types of axiomatic systems.
  * Slowly and painfully developed ibGib's living logic over almost 20 years.
  * So no credibility...just me and my logic.
* You
  * Would require an actual obsession to understand.
  * Would have to concede some of the assumptions of axiomatic systems.
  * Would require an open mind.
* ibGib
  * The only accurate statement that describes ibGib is ibGib.
  * Originally born from an [acronym](https://github.com/ibgib/ibgib/wiki/acronym) 15-ish years ago: i believe God is being.
  * Is built around the idea that eschews "theorem proving" as it is currently
    conceived.
  * Embraces thinking of logic in terms of itself (ibGib) as "the" fundamental
    "unit" of existence, with itself as its only "axiom", which is a more
    precise statement than would be immediately apparent.

I figure this probably sounds like a bunch of bs, which is why I don't usually
talk or write about it. But I'm cooped up in my house because I freak out now
when I go out, and I'm growing weary and so am looking for others looking for
a fundamentally new (and old) approach to logic. So, you can read more on my
[wiki](https://github.com/ibgib/ibgib/wiki) that I'm starting. Or if you want
to take a more active approach, either through discussion or actual code
contribution, hit me up by ([creating a new issue](https://github.com/ibgib/ibgib/issues)).

And now, on to actual code...

## things, ids, transforms, ib, gib, and ib_gib - oh my

ib_gib is about Life, the Universe, and Everything. As such, we are putting a
spin on UUIDs, and unifying that concept with every other concept in existence,
now, then, and in the times coming.

Think of what Goedel did for Goedelian numbers. He turned his code (formulas, proofs) into data (symbol) and then created meta-theorems and meta-proofs using
infinite recursion. Well, we're going to do something similar with id's and what
they associate to. We're going to take the concept of an id and split it into
multiple parts: ib, gib, and ib_gib.

The combination of these things (these ib, these gib, these ib_gib, etc.) are
like Goedelian numbers. But when we consider infinitely long "numbers", the
"counting out" process of the actual numbers themselves takes an infinite amount
of time. "Incompleteness" is about when you try to do this without being
infinitely careful.

So, even if this kind of logic makes you bristle, at the very least these
concepts may be pretty different. But for now, you can think of ib, gib, and ib_gib in the following terms: id, hash, and history. And these "identify" a
"Thing", whether that thing is a "string class" or an entire "meta-program that
creates other programs".

## ib_gib bootstrap

For now, let's jump into some pseudo-data/code: our ("the") bootstrap process.

#### root
First, let's look at the "base" or "root" Thing. This is an implied Thing, which
is to say that it doesn't get stored in a database.

```
Root Thing:
  ib:     ib
  gib:    gib
  ib_gib: []
  data:   ibGib
```

This is the "all Thing" or "infinite Thing". More precisely, ibGib. That is a statement...it is "the" meta-statement actually. But let us use the term "root
Thing", or just root. The root, being infinite, "contains" all other infinities.
If you'd prefer, you can think of it as having the "potential of containing all
infinities", but in the end, it doesn't really matter how you want to summarize
it in a concise, written/spoken statement to begin with. ibGib. But I digress.
Let's consider some actual equivalent instances of this, to show you what I mean
and to get away from the abstract wackiness:

The above root is "equivalent" to...
```
ib:     ib
gib:    gib
ib_gib: [ib_gib]
data:   ibGib
```
And to this...
```
ib:     ib
gib:    gib
ib_gib: [ib_gib, ib_gib]
data:   ibGib
```
And so on. So when we take the root and "apply" it to itself, we get this
infinite history of ib_gib's. So the "history" (ib_gib) of the root is both
"the" zero set and the infinite set. (NB We aren't even appending any cool math
subscripts like ib_gib_0, ib_gib_1...ib_gib_n, because these are actually the
"same" thing(s).) And the "data" that we have is just "ibGib", because it also
represents all possible data: empty, non-empty, sensical, non-sensical,
whatever.

But we won't seem to get much out of the system if we don't give it "something"
more immediately meaningful to us. So let's strap our boots so that we can pull
ourselves up by them (meta bootstrapping humor). So let's pretend that in one of these iterations, we get that more meaningful something: "fork".

#### fork

```
Base fork transform (implied):
  ib:     ib
  gib:    fork
  ib_gib: [ib_gib]
  data:   ibGib
```

Hey, that looks much better...But what is a fork?

Well, when we are "applying" one Thing to another Thing, we can think of this as
applying a transform. A fork is a type of transform which as we will see will
give us a meaningful behavior that is basically like "forking" in a VCS
repository. Indeed, much vocabulary is taken from version control, because we
are primarily dealing with snapshots and transformations in time. But let's
keep rolling...

Here is one possible consequence of the fork applied to itself:
```
Instance fork transform (Base fork applied to itself):
  ib:     uuid1here
  gib:    fork
  ib_gib: ["ib_gib", "ib_fork"]
  data: {src: "ib_gib", dest: "uuid2here"}
```

Here we have several interesting things happening (still "arbitrarily" picking
from our infinite bag of things that we could do):

1. the ib_gib "history" shows that we applied the root, which we'll call the
   "identity" transform. Then we applied the ib_fork.
     * The "ib_fork" means that we would find this information in our thing
       database by the composite key: ib="ib", gib="fork".
2. We've gotten a uuid1here for our ib value.
     * For convenience purposes, we will calculate this as a hash of the gib
       value ("fork") and the ib_gib history ("[ib_gib, "ib_fork"]).
3. We've added some data.   
     * Magic. (j/k)

Transforms are all about linking two Things from our infinite bag of infinities
together. In a fork's case, these are considered two "different" things, and
in fact, a "fork" is how we "new up" a "new" instance of a thing.

When we create the fork instance data, called the "fork transform", we would
create the data and then hash it to get the ib field. So with fork transforms,
the ib field acts as the id **and** the hash. We do this as an implementation
convenience, more than for any conceptual reason (I think).

Now, when we go to "express" this transform, meaning when we apply it in some
context, it will take the source, in this case our implied ib_gib, and create
a "new" thing as follows:

```
Instance "created" by expressing fork transform:
  ib:     uuid2here
  gib:    uuid3_hash_of_this_ib_gib_and_ib
  ib_gib: ["ib_gib", "uuid1here_fork"]
  data:   ibGib
```

So in this case, the ib field acts as the Thing's id, with the gib field acting
like a version history, similar to a git commit hash associated to each commit.
Notice that our ib_gib "history" has only "ib_gib" and "uuid1here_fork", and
it does NOT include the fork base's "ib_fork". When we go to apply the
"uuid1here_fork" fork transform, the fork base history is already included in
the transform itself.

But notice that we don't have any data. How do we want to store data in this
Thing? And what did I mean by "express" and "apply it in some context"?

First the data, then we'll get to the expression.

#### mut8

Let's describe what we want to get out of a mut8 transform. We want to apply
the mut8 transform and have it give us the "same" Thing but with different data.

So we would want something like this for an instance of a mut8 transform:

```
Desired mut8 transform, maybe:
  ib:     some-mut8-uuid-and-or-hash
  gib:    mut8
  ib_gib: [ib_gib, ib_mut8]
  data:   {prop1: value1, prop2: value2, etc.}
```

So here is a possible transform of some Thing:

```
Some A:
  ib:     A-id
  gib:    a-hash-abc
  ib_gib: ["ib_gib", "create-a_fork"]
  data: ibGib
```

transforms to "same" thing A but with different (intrinsic) data...

```
Some A:
  ib:     A-id
  gib:    a-hash-def
  ib_gib: ["ib_gib", "create-a_fork", "some-mut8-uuid-and-or-hash_mut8"]
  data: {prop1: value1, prop2: value2, etc.}
```

So, we can basically think of a mut8 transform as being the "same" as a fork
transform, but with two very important distinctions:

1. The mut8 transform preserves the Thing's ib. This equates to being the "same"
   Thing before and after the transform.  
2. The mut8 transform changes the "intrinsic" data of the Thing.  

_(NB mut8 does not change any database records. All database stuff is immutable.
The mutation comes when expressing the Thing.)_

Now remember, we only arbitrarily chose the effects of the fork and paired it
with the result. We can justify this because we are choosing from the vastness
of infinity, which as it turns out, just so happens to have the exact behavior
that we want - or at least think we want. It also has a bunch of behavior that
we're pretty sure we don't want, but that's okay.

And so, just as with the fork, we are "arbitrarily" choosing this mutation
transformation. The main goal is that we have some Thing identified by a
"composite key" of ib and gib, and this Thing has an ib_gib that keeps track of
all other ib_gib that it has come into contact with. For now, we're just
thinking of those other ib_gib in terms of the transforms.

#### huh? wth?

Yeah, it's all pretty abstract right now. Suck it up. I'm talking to myself
anyway, and not just in an abstract, infinitely recursive universe way either.
Btw, if you've made it here, go ahead and send me an email at ibgib@ibgib.com -
unless it's me reading this, in which case I don't need to send myself any more
emails...to...myself. Moving on...

#### things

So, a "Thing", which I keep capitalizing and haphazardly surrounding with
double quotes, is just that...some "Thing" that exists. It could be a concept,
a class, an instance, a type, a prototype, a business model, a transform...
Whatever you want it to be.

I think of it as ib_gib, but for most people (as if anyone will read this), I
would think that it's easier to come to terms with ib_gib at first as some
concrete-ish Thing. "Object" is overloaded, so is "function"...just found out
recently there is a "concept" oriented programming paradigm. Well, maybe there's
a Thing paradigm but I don't know about it. Anyway, like I said, it's syntactic
sugar for a more abstract concept called ib_gib, which is more like a
"fundamental unit of life" or similar, but that gets pretty heavy Doc.

We'll do a hello world, and you'll get a little better idea. But first...

#### expressions

Now just in case we weren't having enough fun, here comes the funnerest part:
expressions. So the concept of a Thing is some abstract notion that as we've
already seen is "created" via a "fork" of some other Thing at a particular point
in time of that other Thing's existence, and it "changes" via applied mutations.

An expression is very close to the concept of a Thing, except that it lives
as code executed by a program most likely in memory, whereas the Thing itself
lives as the output of that expression. So, you can think of the "Thing" that
lives in the database(s) and the Thing that lives in the expression as two
projections of the "same" Thing. Of course you don't have to.

Practically speaking, an expression is basically the execution context of
mostly Transform Things. The expression will interpret the contact between two
Thing data and then produce some other Thing. This may even be consistent
between expression engines. But it doesn't have to be.

As a slight digression, I state that this creates a very interesting dichotomy
of a Thing's existence in the database(s): The same Thing can have multiple
"paths" of expression in the database(s). I don't see this as a necessarily
desirable side-effect, but it basically is conceivable and thus, it will happen.
I don't really know the implications, other than saying that two Thing
expression paths can exist for the same ib field, but not the same ib_gib
(unique composite key).

Anyway, where were we...oh yes, practically speaking. The expression is the
actual code that will "replay" ib_gib histories, as well as generate new paths.

#### Hello World

Now with that minor introduction out of the way, let's jump into some quick
code! (wah wah wah...)

Seriously, if you want to see a hello world, check out my readme for the brand
spankin' new incarnation of ibGib.

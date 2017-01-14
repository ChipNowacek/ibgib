function getSpan() {
  let iTag = `<i class="fa fa-info-circle" aria-hidden="true"></i>`;
  
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #CFA1C8; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_Info = `

## Info ${getSpan()}

This command will show you detailed nerdy gibblies of the ibGib.

### :baby: :baby_bottle:

Don't look at this! :see_no_evil:

### :eyeglasses: :point_up:

* This is currently a hack that shows the JSON for the given ibGib's current
  state.
* Every ibGib's state is an immutable JSON object comprising \`ib\`, \`gib\`, 
    \`data\`, and \`rel8ns\` fields.
  * The \`ib\` field is _like_ a name but only accepts plain letters, numbers,
    spaces and underscores.
    * :soon: I will implement a "name" or "title" ability to tag them with 
      more expressive titles, labels, etc.
    * :construction: I'm considering the ability to mut8 an \`ib\` field, but
      for right now the only way is to fork it with a new \`ib\`.
  * The \`gib\` field on all user-generated ibGib is a SHA-256 hash of the \`ib\`,
    \`data\`, and \`rel8ns\` fields.
    * The \`gib\` field on some built-in ibGib is just \`gib\`.
    * The \`gib\` field on some built-in ibGib is "stamped" with an "ibGib"
      prefix & suffix.
  * The \`data\` field contains internal information to the ibGib.
    * Internal data is actually still ibGib, but at some point the value of 
      acknowledging the \`ib\` and \`gib\` aspects seemed to be less valuable.
      * For example, the letter "a" could be represented by \`a^gib\` with 
        rel8ns to other letters, etc. This may be a valid thing to do, but I 
        don't have a use case for it immediately. 
      * With this in mind, all ibGib and data boil down to a name (the
        \`ib^gib\`) and its \`rel8ns\` - but we use \`data\` for convenience.
  * The \`rel8ns\` field keeps track of other ibGib via rel8n names and their
    corresponding list of \`ib^gib\`.
    * For example, you could have a rel8n of "member" and then have a list
      of member ibGib that are members of the ibGib.
  * The \`ib\` and \`gib\` fields together combine to form an \`ib^gib\`
    location that is unique to that ibGib in space and time.
    * These act analogously to "reference pointers" in local programming models,
      but instead of a local addressable space it is a "universal" sized 
      address space (limited to the size of SHA-256 hashes).
    * One of the core tenets of ibGib's code is that reference pointers are 
      cheap, data content and files are expensive.
      * This is similar to why cells in body contain _copies_ of the DNA
        (pointers) that are then _expressed in time_ into proteins (the flesh
        acts as a caching mechanism): The DNA molecules are "cheap", but the 
        "proteins" (and ensuing biological beings) are "expensive".
* Looking at the Root info is pretty enlightening.
  * Its \`ib\` field is "ib", and its \`gib\` field is "gib".
  * It has no intrinsic \`data\`, only \`rel8ns\`.
  * It is its own past, identity, dna, and ancestor.

### :sunglasses: :sunrise:

> Jesus answered,  
> &nbsp;&nbsp; 'It is written:  
> &nbsp;&nbsp; "Worship the Lord your God  
> &nbsp;&nbsp; and serve Him only."'  
>
> Luke 4:8

> And so I tell you,  
> &nbsp;&nbsp; every kind of sin and slander can be forgiven,  
> &nbsp;&nbsp; but blasphemy against the Spirit will not be forgiven.  
> Anyone who speaks a word against the Son of Man will be forgiven,  
> &nbsp;&nbsp; but anyone who speaks against the Holy Spirit  
> &nbsp;&nbsp; will not be forgiven,  
> &nbsp;&nbsp; either in this age or in the age to come.  
>
> Matthew 12:31-32

The Lord your God is truth. Since Christ is the way and the truth and the life,
when you worship him, you are worshipping the truth. And the opposite is also
true: _When you worship truth, you worship Christ._ When you serve the truth,
then you are serving Christ. You are forgiven if this isn't what you call it, 
since Jesus even says if you speak a word against the Son of Man, you will be 
forgiven - but not against the Holy Spirit. Speaking against Jesus the man will
be forgiven, since if you continue to acknowledge truth, then you will 
eventually understand what the Son of Man was doing. But denying truth will
only bring you to destruction - not because you didn't like what some guy was 
saying, but because you did not accept the truth that gives life.

---
`;

export { huhText_Cmd_Info };

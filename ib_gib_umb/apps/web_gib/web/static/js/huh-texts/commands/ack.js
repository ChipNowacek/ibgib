function getSpan() {
  // let iTag = `<i class="fa fa-question" aria-hidden="true"></i>`;
  
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #C7FF4F; border-radius: 15px">✓</span>`;
}

function getSpan_Add() {
  let iTag = `<i class="fa fa-plus" aria-hidden="true"></i>`;
  
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #C7FF4F; border-radius: 15px">${iTag}</span>`;
}


var huhText_Cmd_Ack = `

## Ack ${getSpan()}

This command will acknowledge someone else's ibGib to be rel8d directly to your
own.

### :baby: :baby_bottle:

If you like someone's comment or pic, use this to acknowledge and accept it.

### :eyeglasses: :point_up:

* Acknowledge does not necessarily mean that you like it or agree with it.
  * :construction::soon: I'm working on more expressive interactions between
    adjuncts and their targets. Stay tuned...
* From the "Add" (${getSpan_Add()}) command help:
  * If someone else owns the target ibGib, then adding to it will create one
    rel8n going from the "adjunct" to the target.
  * If you own the target ibGib, then adding to it will create 2 rel8ns:
    * 1 rel8n from the added "adjunct" ibGib to the target.
    * 1 rel8n going from the target to the adjunct.
  * It's called adjunct because...
    * Adjunct captures the essence of what the rel8n is until it is 
      acknowledged and rel8d directly.
    * Plus come on...it's a fun word: adjunct. It's fun just to say it.

### :sunglasses: :sunrise:

> So let us acknowledge the Lord;  
> &nbsp;&nbsp; let us press on to acknowledge him.  
> As surely as the sun rises,  
> &nbsp;&nbsp; he will appear;  
> he will come to us   
> &nbsp;&nbsp; like the winter rains,  
> &nbsp;&nbsp; like the spring rains  
> &nbsp;&nbsp; that water the earth.  
>
> Hosea 6:3

Just acknowledging others' ibGib is important. When you acknowledge them,
you're saying that you don't necessarily agree or disagree with what they've
posted, but that you've seen it and accepted it as their contribution.

All of existence up to any point in time is a culmination of all prior
existence. When you acknowledge the Lord, you're giving credit to all of those 
previous contributions of others before you and alongside you.

When you _press on_ to acknowledge him under good conditions, then the honor
you give lends itself to you to continue to develop those good conditions. When 
you press on to acknowledge him under adverse conditions, then you do yourself
and others benefit in your faith and understanding that said adverse conditions 
are only temporary. They shall be overcome as surely as the sun rises. :sunrise:

---
`;

export { huhText_Cmd_Ack };

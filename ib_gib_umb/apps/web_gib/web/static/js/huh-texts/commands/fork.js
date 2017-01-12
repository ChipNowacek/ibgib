function getSpan() {
  let iTag = `<i class="fa fa-eye" aria-hidden="true">`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #61B9FF; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_View = `

## Command: View ${getSpan()}

Views an ibGib in more detail. 

### :baby: :baby_bottle:

With pics, this will show it fullscreen. If it's a comment, then it will load
it up in the comment viewer.

### :eyeglasses: :point_up:

* In general, if we have an ibGib then we can have a rendering strategy.
  * Right now, this strategy is simply coded for pics and comments.
  * In the future, this will enable more dynamic viewing of ibGib.

### :sunglasses: :sunrise:

> 

---
`;

export { huhText_Cmd_View };

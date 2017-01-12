function getSpan() {
  let iTag_q = `<i class="fa fa-question" aria-hidden="true"></i>`;
  let iTag_x = `<i class="fa fa-exclamation" aria-hidden="true"></i>`;
  
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #EBFF0F; border-radius: 15px">${iTag_q}${iTag_x}${iTag_q}</span>`;
}

var huhText_Cmd_Huh = `

## Huh? ${getSpan()}

This command will do its best to give you a little help.

### :baby: :baby_bottle:

Goochie Goochie Goo! :smile:

### :eyeglasses: :point_up:


### :sunglasses: :sunrise:

Help is already on the way. If you need any help from me, drop me a line :fishing_pole_and_fish: at 
ibgib@ibgib.com :email:, <a href="https://github.com/ibgib/ibgib/issues" target="_blank">create an issue on our GitHub repo</a>, or <a href="https://twitter.com/ibgib" target="_blank">tweet at me</a>. :smiley:

_(:construction: I'm working on ibGib messaging so you can contact me directly within ibGib itself :hushed:)_

---
`;

export { huhText_Cmd_Huh };

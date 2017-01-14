function getSpan() {
  let iTag = `<i class="fa fa-link" aria-hidden="true"></i>`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #61B9FF; border-radius: 15px">${iTag}</span>`;
}

function getSpan_ExternalLink() {
  let iTag = `<i class="fa fa-external-link" aria-hidden="true"></i>`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #C7FF4F; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_Link = `

## Link ${getSpan()}

This command will add a hyperlink to any URL.

### :baby: :baby_bottle:

Adds a square with a link to other stuff outside of ibGib. 

### :eyeglasses: :point_up:

* Links are intended for external URLs (non-www.ibgib.com links), but will work
  for any URL.
* They're great for giving source attribution to websites and resources 
  outside of ibGib.
* All hyperlinks will be linkified, but on some browsers you may need to
  long-press the ibGib and use the "External Link" command
  (${getSpan_ExternalLink()}).

### :sunglasses: :sunrise:

> He defends the cause of the fatherless and the widow,  
> &nbsp;&nbsp; and loves the foreigner residing among you,  
> &nbsp;&nbsp; giving them food and clothing.  
> And you are to love those who are foreigners,  
> &nbsp;&nbsp; for you yourselves were foreigners  
> &nbsp;&nbsp; in the land of Egypt.  
>
> Deuteronomy 10:18-19

Gotta love the foreign links too! :smile:

---
`;

export { huhText_Cmd_Link };

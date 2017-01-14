function getSpan() {
  let iTag = `<i class="fa fa-external-link" aria-hidden="true"></i>`;
  
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #C7FF4F; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_ExternalLink = `

## Open External Link ${getSpan()}

This command will open a link in a new tab/window.

### :baby: :baby_bottle:

Use this to open up a link to other sites on the web.

### :eyeglasses: :point_up:

* External links are great for giving credit to outside sources on the internet.

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

export { huhText_Cmd_ExternalLink };

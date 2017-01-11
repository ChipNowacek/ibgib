function getSpan() {
  let iTag = `<i class="fa fa-comment-o" aria-hidden="true"></i>`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #61B9FF; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_Comment = `

## Comment ${getSpan()}

This command will add a comment (or any text really) to an ibGib.

### :baby: :baby_bottle:

Adds a square with words and stuff in it.

### :eyeglasses: :grey_question:

* You can use comments as...
  * Remarks
  * Notes
  * Instructions
  * Documents
  * <a href="https://markdown-it.github.io/">Markdown texts</a>
  * Code snippets
  * and more...
* The max length of a comment is 4096.

### :sunglasses: :sunrise:

> And so we say with confidence:  
> &nbsp;&nbsp; 'The Lord is my helper, '  
> &nbsp;&nbsp; 'I will not be afraid.'  
> &nbsp;&nbsp; 'What can mere mortals do to me?'
>
> Hebrews 13:6

Speak with confidence with the Lord as your helper!

---
`;

export { huhText_Cmd_Comment };

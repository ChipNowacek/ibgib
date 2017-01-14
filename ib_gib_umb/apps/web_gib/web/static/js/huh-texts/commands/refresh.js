function getSpan() {
  let iTag = `<i class="fa fa-refresh" aria-hidden="true"></i>`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #C7FF4F; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_Refresh = `

## Refresh ${getSpan()}

This command will look for any more up-to-date versions of an ibGib.

### :baby: :baby_bottle:

Use this to get the latest version if you're not seeing it automatically. 

### :eyeglasses: :point_up:

* Each forked ibGib has its own timeline. 
  * Refresh will get the most recent ibGib state in a given timeline.
  * It is possible to have branching timelines in ibGib, which for now I'm just
    ignoring. 
    * :soon: In the future, any branching timelines will automatically 
      resolved.
* The first ibGib in a timeline is called the "temporal junction point", thusly
  named from a line in Back to the Future II.
  * Any additions to an ibGib's timeline get broadcasted to all devices actively
    viewing any live ibGib via its temporal junction point.

### :sunglasses: :sunrise:

> Marty McFly:  
> &nbsp;&nbsp; That's right, Doc. November 12, 1955.  
>
> Doc Brown:  
> &nbsp;&nbsp; Unbelievable, that old Biff could have chosen that particular date. It could mean that that point in time inherently contains some sort of cosmic significance. Almost as if it were the temporal junction point for the entire space-time continuum. On the other hand, it could just be an amazing coincidence.  
>
> <a href="http://www.imdb.com/title/tt0096874/quotes?item=qt0426637" target="_blank">Back to the Future II</a>

Time travel exists, and then some. 

---
`;

export { huhText_Cmd_Refresh };

function getSpan() {
  let iTag = `<i class="fa fa-picture-o" aria-hidden="true"></i>`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #61B9FF; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_Pic = `

## Pic ${getSpan()}

This command will add a pic to an ibGib. You must first be identified by an 
email address in order to upload pics.

### :baby: :baby_bottle:

Adds a circle with a picture in it. 

Gotta login in order to do this! :love_letter: In order to login, click on the
background, then click on the green circle, then click on the white circle to
start the login.

### :eyeglasses: :point_up:

* Pic ibGib contain data about the image, including...
  * Filename & extension
  * Binary id (hash of image binary)
  * Thumbnail information
  * Content/type.
* Picture binaries are hashed (SHA-256) and stored by their hash.
  * This prevents duplication of files.
  * This combats tampering of photos after being uploaded.
  * This does NOT determine if a photo has been doctored or not before being 
    uploaded.

### :sunglasses: :sunrise:

> But whoever lives by the truth  
> &nbsp;&nbsp; comes into the light,  
> &nbsp;&nbsp; so that it may be seen plainly  
> &nbsp;&nbsp; that what they have done  
> &nbsp;&nbsp; has been done  
> &nbsp;&nbsp; in the sight of God.
>
> John 3:21

Pics are a great way to _help_ bring what we see into the light. But they are 
not a replacement for the light itself, nor for the truth which comes into it.

---
`;

export { huhText_Cmd_Pic };

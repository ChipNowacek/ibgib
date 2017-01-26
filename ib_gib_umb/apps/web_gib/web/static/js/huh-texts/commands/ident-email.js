function getSpan() {
  let iTag = `<i class="fa fa-sign-in" aria-hidden="true"></i>`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #FFFFFF; border-radius: 15px">${iTag}</span>`;
}

function getSpan_Root() {
  let iTag = `<i class="fa fa-circle-o" aria-hidden="true"></i>`;
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #76963e; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_IdentEmail = `

## Identify ${getSpan()}

This command will identify you in ibGib with an email address. 

**_This email address will be publicly visible. Please do not use ibGib if you
wish your email address to remain private. Thank You!_** :smiley:

### :baby: :baby_bottle:

For starters, just think of this as your login. 

To begin this process, click anywhere on the background to bring up the Root
green circle (${getSpan_Root()}). Click on it and then click the white
"Identify" command (${getSpan()}). Enter your email address and we'll send you
a link where you can complete your identification. 

_Hint: The "security pin" is optional. If you choose to use it, just enter a
random short pin - NOT a complicated, known password. Choose a different pin
any time you log in. To log out, clear your cookies for our site
only. Otherwise, you would log out for all of your other sites._

When you receive the email, be sure to open the link in the same browser.

**If you're on a public computer, be sure to use incognito tabs. When
you get the email, manually copy & paste the link into the same browser with a
new incognito tab.**

:construction::construction: We're currently working on
<a href="https://github.com/ibgib/ibgib/issues/35" target="_blank">improved identity management</a>.
:construction::construction:

### :eyeglasses: :point_up:

* You can identify yourself with multiple email addresses. 
  * You can do this with as many email addresses as you want, depending on how
    security-conscious you are.
  * If you are signed in with multiple email addresses, any query you run will
    query for any of those identities.
  * Every time you add an email address, you increase the level of required
    identification when mut8ing or rel8ing that ibGib to other ibGib. 
* The security pin is optional.
  * This adds a little bit of security when identifying yourself by 
    your email. 
  * This is not a "password". It's just a one-time pin that you enter before
    we send you the email. Then when you click on the link, you'll enter it
    again. After that, it disappears forever. 
* You must open the link in the _same_ browser in which you started the 
  identification process. 
  * For example...
    * You can't click identify on your phone and then open the email link on
      your laptop. 
    * You can't click identify in a Firefox browser and then open the email link
      in Chrome.
* ibGib identification is designed as an extensible "claims-based" architecture.
  * Currently, we have "email" as the only claim, and you can layer multiple
    emails.
  * In the future, we can have any number of claims: Biometric, OAuth, SMS,
    AI, etc. 
  * It's designed so that it keeps track of what claims were made when any and
    all data is created (not just what "user" did what). 
    * This is to increase the ability for future analytics to determine more 
      readily the veracity of/confidence in any ibGib.

### :sunglasses: :sunrise:

> The city does not need the sun or the moon to shine on it,  
> &nbsp;&nbsp; for the glory of God gives it Light,  
> &nbsp;&nbsp; and the Lamb is its lamp.  
> The nations will walk by its Light,  
> &nbsp;&nbsp; and the kings of the earth will bring their splendor into it.  
> On no day will its gates ever be shut,  
> &nbsp;&nbsp; for there will be no night there.  
>
> Revelation 21:23-25

Right now, almost every website that you visit or do business with records 
information about what you do to improve their services - this makes sense.
They want to get better, and you want them to get better to provide better
services. This is _great_. Smart people are working very hard to make things
smarter for your benefit.

But people still want privacy. This is understandable. We don't want to give 
away information for bad people to take advantage of. But _hiding_ in the dark
is no longer an acceptable solution. We now have the ability to _share 
information_ to an extent that was previously impossible. Sharing information is
living in the Light, and we can use this Light to protect ourselves. The better
we can analyze _real_ data, the better we can protect each other. This is 
_exactly_ analogous to walking together in daylight versus walking alone at
night. 

So ibGib is taking a different approach to security than other cloud services.
Our goal is to get as much information into the Light as possible to enable us
to share and analyze data more effectively. Medical research, social research, 
product research - the list goes on and on. Who watches the watchers? We all do,
because we all have the information available. This is the ultimate in 
transparency. And so, with ibGib our focus is not on encryption, rather it is
on authentication and integrity: Authentic identity and data integrity. We are
building our entire system, from the ground up, with this approach in mind.

In ibGib, every single ibGib is like a biological cell snapshot with its 
own DNA. Each and every cell has this DNA, which includes both a hash of the
cell's information, as well as its owning identities. And it keeps track of 
the evolution of these cells at every stage of development keeping a complete
audit history of its existence. So _everything_ that ibGib knows about is in
the Light where _everyone_ can see it.

This is a key tenet of the Bible: bring that which is evil and shameful into
the Light so that it may turn into good. This is what the entire book is working
towards - the new heaven on earth - _which is in the Light of God_. What do you 
think that this means? Do you think the Light of God is a literal high-beam
spotlight? It's information - real, authentic information.  The kind of 
information that survives scrutiny and _exposure to us, The People_. It's the 
enduring Word that will _never_ pass away. It's the
ability for us to function entirely within the Light with self-control and
without censorship. Don't be afraid, and have confidence that the Lord is your
helper - the Truth is your helper. In the future, all will be brought into the
Light.

ibGib is not the Word - it _is_ a tool for us to grow ears to hear Him.

---
`;

export { huhText_Cmd_IdentEmail };

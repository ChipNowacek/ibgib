function getSpan() {
  let iTag = `<i class="fa fa-search" aria-hidden="true"></i>`;
  
  return `<span style="padding: 5px; width: 70px; font-family: FontAwesome; background-color: #C7FF4F; border-radius: 15px">${iTag}</span>`;
}

var huhText_Cmd_Query = `

## Query ${getSpan()}

This command will execute a query to search for ibGib.

### :baby: :baby_bottle:

This is your search button.

### :eyeglasses: :point_up:

* Right now, querying is a little unwieldy since you have to remember if you're
  looking for an \`ib\` or some text in a comment or what.
  * :soon: I will streamline this interface to be much much smarter.
* Running a query is two basic steps:
  1. It creates an ibGib containing the query information.
  2. It executes the query and creates a query result ibGib that contains the
     result of the query.
* Query results are strictly composed of rel8ns to \`ib^gib\` pointers.
* You can navigate to the query itself from the query results ibGib via its
  "query" rel8n.
* :soon: I'm in the process of thinking <a href="https://github.com/ibgib/ibgib/issues/132" target="_blank">how to do paging of query results</a>,
  so if you do a query that returns a huge number of results, all those ibGib
  won't slow your browser down to a screeching halt.
* :soon: In the future, queries will be executed like farming crops. 
  * There will be seasons for various types of queries that maximize the 
    temporal appropriateness of the query.
  * Query results will be harvested as the crops.

### :sunglasses: :sunrise:

> Or do you show contempt  
> &nbsp;&nbsp; for the riches of his kindness,  
> &nbsp;&nbsp; forbearance and patience,  
> &nbsp;&nbsp; not realizing that God's kindness  
> &nbsp;&nbsp; is intended to lead you to repentance?  
>
> Romans 2:4

The more you can let someone figure out his/her own way to do something, the 
more powerful their ability will be. With an infinite amount of time, the 
power to overcome death, and an infinite amount of kindness, forbearance and
patience, God lets us become as great as he is, leading us to repentance.

The example of God's "inability" to control the Israelites is _the_ example of 
how micro-management via inanimate commandments of stone does not lead to life.
If God cannot come up with the "right set of laws" to do this, how could we?
Rather, the _holy_ spirit, which takes into account all of God's greatness, is
what gives life.

---
`;

export { huhText_Cmd_Query };

# Query & Filter Notes
## These were my notes and some code from the thingGib incarnation.

------------------------------------------------------------------------------
Creates the transforms needed for a new Filter Thing.
Each filter has a type, which describes what kind of filtering action. These
can be 'regex', 'exact' (literal equals), etc. See param for valid values.

Each filter targets a "property". This can be directly on a Thing/Transform
(e.g. isAbstract, ancestorId, etc.).

Or, the target can be another Thing that has been merged. This would require
a targetMap. For example, say you have a "HelloWorld" Thing (name=HelloWorld)
and you have merged a "text" instance with it with content = "Hello World Yo!".
You could filter on this content, even though it's not a direct property on the
HelloWorld thing. To do so, the target would be 'text.content'. But without a
targetMap, we wouldn't know how to interpret the "text" part of this. So the
targetMap for this would be 'name.prop'. Now the engine knows to look for
merged Thing(s) with name='text', and on any of those Thing(s) it will look for
the property='content'. We could also get at it via id. If we use targetMap as
'id.prop', and a target of 'ABC12345.content', then it would look for merged
Thing(s) with id='ABC12345'.

If the targetType is 'transform', then the filter will be used before a transform
is applied, thus keeping the transform from having any effect whatsoever on an
expression. If the targetType is 'thing', then the Thing would still exist in
an expression but would be marked as filtered.

I plan on using this for both filtering queries by ownerId, which would
target transforms before they are applied, as well as with "temporary"
filters for use in showing/hiding existing information.

@param type 'regex', 'exact', 'contain', 'gt', 'lt'
@param target e.g. 'isAbstract', 'name', 'createdOn', etc.
@param targetType 'transform', 'thing'
@param targetMap e.g. 'name.prop', 'id.prop', 'name.name.prop', etc.
@param mergeTargetId The id of the Thing (e.g. query) to apply the filter to.
@param xformIds expects 4-8 (calls NewProperty method)

@see {IFilterContent} for the filter content's shape

@todo Implement a compound filter mechanism.
Probably create another Filter Thing, named e.g. "CompoundFilter". Somehow must
be able to merge with other filters with logical and/or-ing, as well as order
of operations. This gets pretty complicated, so for now I'm just sticking
with "simple" (hah!) filters.
------------------------------------------------------------------------------

createTransforms_NewFilter({
  spaceId,
  type,
  target,
  targetType,
  targetMap = null,
  include = null,
  exclude = null,
  mergeTargetId = null,
  active = true,
  filterName = null,
  filterId = null,
  transactionId = null,
  ownerId = null,
  xformIds = []
}: {
  spaceId: string,
  type: string,
  target: string,
  targetType: string,
  targetMap?: string,
  include?: string,
  exclude?: string,
  mergeTargetId?: string,
  active?: boolean,
  filterName?: string,
  filterId?: string,
  transactionId?: string,
  ownerId?: string,
  xformIds?: string[]
}): ThingTransform[] {
  let logContext = `TransformFactory.newFilter`;
  this.helper.logFuncStart(logContext);

  let result: ThingTransform[] = [];
  try {
      var baseTimestamp = Date.now();
      transactionId = transactionId ? transactionId : this.helper.generateUUID();
      ownerId = ownerId ? ownerId : this.helper.currentUserId;

      filterName = filterName ? filterName : `${type}:${target}`;
      filterId = filterId ? filterId : this.helper.generateUUID();

      let ancestorId = '';

      switch (type) {
          case 'regex':
              ancestorId = ReservedIds.THNG_regexfilter;
              break;
          case 'exact':
              ancestorId = ReservedIds.THNG_exactfilter;
              break;
          case 'contain':
              ancestorId = ReservedIds.THNG_containfilter;
              break;
          case 'gt':
              ancestorId = ReservedIds.THNG_greaterthanfilter;
              break;
          case 'lt':
              ancestorId = ReservedIds.THNG_lessthanfilter;
              break;
          default:
              this.helper.log(`[createTransforms_NewFilter] Unknown filter type: (${type}). Using exact filter. `, 'error', 5);
              ancestorId = ReservedIds.THNG_exactfilter;
              break;
      }

      // Build the filter's content.
      let filterContent: FilterContent = {
          target: target,
          targetType: targetType
      };
      if (targetMap) {
          filterContent.targetMap = targetMap;
      }
      if (include) {
          filterContent.include = include;
      }
      if (exclude) {
          filterContent.exclude = exclude;
      }
      if (!active) {
          filterContent.deactivated = true;
      }

      let contentJson = JSON.stringify(filterContent);

      if (contentJson.length > 5120) {
          this.helper.log(`[createTransforms_NewFilter] Filter over 5 kB. ownerId: (${ownerId}). Actual size (bytes): ${contentJson.length}`, 'warn', 3);
      }

      if (contentJson.length > 1024000) {
          let errorMsg = `[createTransforms_NewFilter] Filter over 1 MB? ownerId: (${ownerId}). Actual size (bytes): ${contentJson.length}`;
          this.helper.log(errorMsg, 'error', 3);
          throw new Error(errorMsg);
      }

      // Create the filter's transforms.
      var xforms_CreateFilter =
          this.newProperty({
              propName: filterName,
              propSpaceId: spaceId,
              containerId: mergeTargetId,
              ancestorId: ancestorId,
              content: contentJson,
              isText: true,
              isAbstract: false,
              transactionId: transactionId,
              ownerId: ownerId,
              propId: filterId,
              xformIds: this.getTransformIds(/*start*/0,/*count*/8, xformIds)
          });
      result.push.apply(result, xforms_CreateFilter);

      // uncomment this if we add more xforms to this method.
      // as it is, we only have the one xforms array that is already sequentialized.
      // this.sequentializeTransforms(result);

  } catch (errFunc) {
      this.helper.logError(`errFunc`, errFunc, logContext);
      throw errFunc;
  }

  this.helper.logFuncComplete(logContext);

  return result;
}
------------------------------------------------------------------------------

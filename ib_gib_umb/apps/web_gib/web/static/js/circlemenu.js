export class CircleMenu {
  constructor() {
    this.mainMenuId = "#ib-main-circular-menu";
    this.mainMenuElement = $(this.mainMenuId).get()[0];
    this.mainMenuCircularMenuElement = $(this.mainMenuId).children(".ib-circular-menu")[0];
    this.mainMenuCircularMenuLinksElement =
      $(this.mainMenuId).children(".ib-circular-menu").children()[0];
    this.mainMenuCircularMenuButton =
      $(this.mainMenuId).children(".ib-circular-menu").children()[1];

    this.mainMenuCircularMenuButton.id = "ib-main-circular-menu";
    $("#ib-main-circular-menu").on("click", e => { this.hide(); })

    $( document ).on("click", e => { this.handleClick(e); });

    this.initMenuLinks();

    this.updateIbGibElements();
  }

  getCenterPos(element) {
    let rect = element.getBoundingClientRect();
    return {
      x: (rect.right + rect.left)/2,
      y: (rect.bottom + rect.top)/2
    };
  }

  /**
   * Gets the min distance between each of the corners of the element, the
   * center, and the midpoints of each rect's edge.
   * E.g., checks each & to point X. In this case the min distance will be
   * from the right center vertex.
   * &---&---&
   * ---------
   * &---&---&----------------------X
   * ---------
   * &---&---&
   */
  getMinDistance(element, point) {
    let rect = element.getBoundingClientRect();
    let center = this.getCenterPos(element);

    let rectEdges = [
      {v: {x: rect.left, y: rect.top}, w: {x: rect.right, y: rect.top}},
      {v: {x: rect.left, y: rect.top}, w: {x: rect.left, y: rect.bottom}},
      {v: {x: rect.right, y: rect.top}, w: {x: rect.right, y: rect.bottom}},
      {v: {x: rect.left, y: rect.bottom}, w: {x: rect.right, y: rect.bottom}},
    ]

    return rectEdges.reduce((shortestSoFar, edge) => {
      let dist = this.distToSegment(point, edge.v, edge.w);
      return shortestSoFar && shortestSoFar < dist ? shortestSoFar : dist;
    }, null);
  }

  /**
   * Squares `x`
   * @see `distToSegment`
   */
  sqr(x) { return x * x }
  /**
   * Length squared of line segment
   * @see `distToSegment`
   */
  dist2(v, w) { return this.sqr(v.x - w.x) + this.sqr(v.y - w.y) }
  /**
   * Distance squared from point `p` to line segment with endpoints `v` and `w`.
   * @see `distToSegment`
   */
  distToSegmentSquared(p, v, w) {
   var l2 = this.dist2(v, w);
   if l2 === 0 return this.dist2(p, v);
   var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
   t = Math.max(0, Math.min(1, t));
   return this.dist2(p, { x: v.x + t * (w.x - v.x),
                          y: v.y + t * (w.y - v.y) });
  }
  /**
   * Shortest distance between point and line segment.
   * Thanks SO! http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
   * @param p is the point
   * @param v is line segment endpoint 1
   * @param w is line segment endpoint 2
   */
  distToSegment(p, v, w) {
    return Math.sqrt(this.distToSegmentSquared(p, v, w));
  }

  handleClick(e) {
    if (!e.target.classList.contains("ib-circular-menuable")) {
      // debugger;
      if (this.visible) {
        this.hide();
      }

      return;
    }
    this.updateIbGibElements();

    let clickPos = { x: e.clientX, y: e.clientY };
    // this.updateIbGibElements();
    let nearestInfo = this.getNearestIbGib(clickPos);

    if (!this.visible || (nearestInfo.nearestElement !== this.activeIbGibElement)) {
      // We're are either clicking with no menu currently showing, or we're
      // clicking on a different nearby ibGib element
      this.hide();

      const minDistance = 100; // Minimum distance to trigger menu
      if (nearestInfo && nearestInfo.distance < minDistance) {
        console.log(`distance: ${nearestInfo.distance}`);
        this.show(nearestInfo.nearestElement);
      } else {
        console.log("No nearby ibGib available.");
      }

    } else {
      // The menu is currently visible and we're click
      this.hide();
    }
  }

  show(ibGibElement) {
    if (ibGibElement) {
      this.activeIbGibElement = ibGibElement;
      this.activeIbGibElement.classList.add('ib-gib-element-active');

      this.mainMenuElement.classList.remove('ib-hidden');

      let elementPos = this.getCenterPos(ibGibElement);
      console.log(`elementPos: ${JSON.stringify(elementPos)}`);

      this.repositionMainMenu(elementPos);

      this.mainMenuCircularMenuLinksElement.classList.add('open')

      this.visible = true;
    }
  }

  /**
   * Gets the nearest ibGib element to the `clickPos` and the distance to that
   * element.
   * @returns {nearestElement: element, distance: dist}
   */
  getNearestIbGib(clickPos) {
    if (this.ibGibElements && this.ibGibElements.length > 0) {
      return this.ibGibElements.reduce((nearestSoFar, element) => {
        let dist = this.getMinDistance(element, clickPos);
        return nearestSoFar && nearestSoFar.distance < dist ? nearestSoFar : {nearestElement: element, distance: dist};
      }, null);
    } else {
      console.warn('Why are there no ibGibElements?');
      return null;
    }
  }

  hide() {
    if (this.activeIbGibElement) {
      this.activeIbGibElement.classList.remove('ib-gib-element-active');
      this.activeIbGibElement = null;
    }

    this.mainMenuElement.classList.add('ib-hidden');

    this.mainMenuCircularMenuLinksElement.classList.remove('open')

    this.visible = false;
  }

  updateIbGibElements() {
    this.ibGibElements = $(".ib-gib-element").get();
  }

  /**
   * `centerPos` is the desired center of the menu, {x: X, y: Y}
   */
  repositionMainMenu(centerPos) {
    let menuRect = this.mainMenuCircularMenuElement.getBoundingClientRect();
    let width = menuRect.right - menuRect.left;
    let height = menuRect.bottom - menuRect.top;
    let left = Math.abs(centerPos.x - Math.trunc((1/2)*width));
    let top = Math.abs(centerPos.y - Math.trunc((1/2)*height));

    this.mainMenuCircularMenuElement.style.left = `${left}px`;
    this.mainMenuCircularMenuElement.style.top = `${top}px`;

    console.log(`mainMenuElement pos: ${left}, ${top}`);
  }

  initMenuLinks() {
    const menuRadius = 70;
    const A = 50;
    // const B = 60;

    let divMenuLinks = this.mainMenuCircularMenuLinksElement;
    //  = [].filter.call(m.children, child => child.tagName === 'DIV')[0];
    let menuButton = this.mainMenuCircularMenuButton;
    // let menuButton = [].filter.call(m.children, child => child.tagName === 'A')[0];
    let links = [].filter.call(divMenuLinks.children, child => child.tagName === 'A');
    let linkCount = links.length;
    for (var i = 0; i < linkCount; i++) {
      let link = links[i];
      link.style.left = (A - menuRadius*Math.cos(-0.5 * Math.PI - 2*(1/linkCount)*i*Math.PI)).toFixed(4) + "%";
      link.style.top = (A + menuRadius*Math.sin(-0.5 * Math.PI - 2*(1/linkCount)*i*Math.PI)).toFixed(4) + "%";
    }
  }

}

export default CircleMenu;

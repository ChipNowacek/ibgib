export class GraphBase {
  constructor(graphDiv) {
    if (new.target === GraphBase) {
      throw new TypeError("Cannot construct GraphBase instances directly");
    }

    let t = this;

    t.graphDiv = graphDiv;
    t.rect = t.graphDiv.getBoundingClientRect();
    t.width = t.graphDiv.scrollWidth;
    t.height = t.graphDiv.scrollHeight;
    t.center = {x: t.width / 2, y: t.height / 2};
  }

  init() {
    throw new TypeError("init must be implemented.");
  }

  add(d) {
    throw new TypeError("add must be implemented.");
  }

  remove(d) {
    throw new TypeError("remove must be implemented.");
  }

  refresh(full) {
    throw new TypeError("refresh must be implemented");
  }

  destroy() {
    // Does nothing by default
  }
}

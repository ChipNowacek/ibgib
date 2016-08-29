import * as PIXI from "pixi.js";

export class IbScape {
  constructor(canvasDiv) {
    this.init(canvasDiv);
    window.onresize = () => {
      const debounceMs = 250;

      if (this.resizeTimer) { clearTimeout(this.resizeTimer); }

      this.resizeTimer = setTimeout(() => {

        console.log("resized yo");
        this.destroyStuff();
        this.init(canvasDiv);

      }, debounceMs);
    };
  }

  init(canvasDiv) {
    this.canvasDiv = canvasDiv;
    let width = canvasDiv.clientWidth;
    let height = canvasDiv.clientHeight;


        // You can use either `new PIXI.WebGLRenderer`, `new PIXI.CanvasRenderer`, or `PIXI.autoDetectRenderer`
    // which will try to choose the best renderer for the environment you are in.
    let renderer = new PIXI.CanvasRenderer(width, height);
    this.renderer = renderer;

    // The renderer will create a canvas element for you that you can then insert into the DOM.
    canvasDiv.appendChild(renderer.view);

    // You need to create a root container that will hold the scene you want to draw.
    let stage = new PIXI.Container();
    this.stage = stage;

    // Declare a global variable for our sprite so that the animate function can access it.
    let bunny = null;

    // load the texture we need
    let t = this;
    PIXI.loader.reset();
    PIXI.loader.add('bunny', 'images/bunny.png').load(function (loader, resources) {
        // This creates a texture from a 'bunny.png' image.
        bunny = new PIXI.Sprite(resources.bunny.texture);

        // Setup the position and scale of the bunny
        bunny.position.x = width / 2;
        bunny.position.y = height / 2;
        bunny.anchor.x = 0.5;
        bunny.anchor.y = 0.5;

        bunny.scale.x = 1;
        bunny.scale.y = 1;
        t.bunny = bunny;


        // Add the bunny to the scene we are building.
        stage.addChild(bunny);
        stage.interactive = true;
        stage.on('mousewheel', e => {
          stage.scale.x += 0.1;
          stage.scale.y += 0.1;
        });

        // kick off the animation loop (defined below)
        t.animate();
    });

    canvasDiv.addEventListener('wheel', e => {
      if (e.deltaY < 0) {
        this.stage.scale.x *= 1.1;
        this.stage.scale.y *= 1.1;
      } else {
        this.stage.scale.x *= 0.9;
        this.stage.scale.y *= 0.9;
      }
    });


    let y = height/4;
    let radius = 4;
    let diam = 2 * radius;
    let count = 5000;
    let buffer = 15;
    let xBlock = Math.trunc(width / (2*radius + buffer));
    let yBlock = Math.trunc(height / (2*radius + buffer));

    let texture = this.generateIbGibTexture(radius);

    this.ibGibs = [];
    for (let i = 0; i < count; i++) {
      let x = (i % xBlock) * (diam + buffer);
      let y = Math.trunc(i / xBlock) * (diam + buffer);
      this.ibGibs.push(this.addIb(texture, "ib^gib", x, y, radius));
    }
  }

  generateIbGibTexture(radius) {
    let graphics = new PIXI.Graphics();
    let color = 0x76963e;
    graphics.lineStyle(2, color);
    graphics.drawCircle(0, 0, radius); // drawCircle(x, y, radius)
    graphics.endFill();

    let texture = graphics.generateCanvasTexture();

    return texture;
  }

  addIb(texture, ibGib, x, y, radius) {
    let sprite = new PIXI.Sprite(texture);
    // sprite.interactive = true;
    sprite.anchor.set(0.5, 0.5);
    sprite.x = x;
    sprite.y = y;

    let zoomedInScale = 15;

    this.stage.addChild(sprite);

    sprite.interactive = true;
    sprite.
      on('click', (e) => {
        console.log(`x,y: ${e.target.x}, ${e.target.y}`);
      }).
      on('mouseover', e => {
        e.target.scale.x = zoomedInScale;
        e.target.scale.y = zoomedInScale;
      }).
      on('mouseout', e => {
        e.target.scale.x = 1;
        e.target.scale.y = 1;
      }).
      on('wheel', e => {
        console.log('mouse wheel')
        this.stage.scale.x += 0.1;
        this.stage.scale.y += 0.1;
      });


    return sprite;
  }

  destroyStuff() {
    this.requestCancel = true;

    this.bunny.destroy(true);
    delete(this.bunny);

    this.stage.destroy(true);
    delete(this.stage);

    this.renderer.destroy(true);
    delete(this.renderer);
  }

  animate() {
      // start the timer for the next animation loop
      requestAnimationFrame(() => {
        if (!this.requestCancel) {
          this.animate();
        } else {
          this.requestCancel = false;
        }
      });

      if (this.bunny) {
        // each frame we spin the bunny around a bit
        this.bunny.rotation += 0.01;

        // this is the main render call that makes pixi draw your container and its children.
        this.renderer.render(this.stage);
      } else {
        setTimeout(() => {
          this.renderer.render(this.stage);
        }, 1000);
      }
  }

}

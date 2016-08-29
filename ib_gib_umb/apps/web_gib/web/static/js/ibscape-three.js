import * as THREE from "three";

export class IbScape {
  constructor(canvasDiv) {
    this.canvasDiv = canvasDiv;

    this.init(canvasDiv);
  }

  init(canvasDiv) {
    this.scene = new THREE.Scene();

    let width = canvasDiv.clientWidth;
    let height = canvasDiv.clientHeight;

    this.camera = new THREE.PerspectiveCamera( 75, width / height, 0.1, 10000 );
    // this.camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );
    // this.camera.position.z = 1000;

    let scale = 1;

    let boxSize = 1 * scale;
    let boxColor = 0x00ff00;
    let geometry = new THREE.BoxGeometry( boxSize, boxSize, boxSize );
    let material = new THREE.MeshBasicMaterial( { color: boxColor, wireframe: true } );
    // this.material = new THREE.MeshBasicMaterial( { color: boxColor, wireframe: true } );

    this.mesh = new THREE.Mesh( geometry, material );
    this.scene.add( this.mesh );

    this.camera.position.z = 5 * scale;

    this.renderer = new THREE.WebGLRenderer();
    // this.renderer.setSize( window.innerWidth, window.innerHeight );
    this.renderer.setSize( width, height );

    canvasDiv.appendChild( this.renderer.domElement );
  }

  destroyStuff() {

  }

  animate() {

    requestAnimationFrame( () => this.animate() );

    this.mesh.rotation.x += 0.01;
    this.mesh.rotation.y += 0.02;

    this.renderer.render( this.scene, this.camera );

  }
}

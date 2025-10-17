/**
 * Pattern Linear Tool - Fusion 360 Style
 * Crea array lineari di oggetti (righe e colonne)
 *
 * @module PatternLinearTool
 * @author Box Designer CAD Engine
 */

export class PatternLinearTool {
  /**
   * Costruttore Pattern Linear Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'pattern_linear';
    this.cursor = 'crosshair';

    // Oggetti selezionati per pattern
    this.selectedObjects = [];

    // Parametri pattern
    this.countX = 3; // Numero copie in X
    this.countY = 3; // Numero copie in Y
    this.spacingX = 50; // Spaziatura X in mm
    this.spacingY = 50; // Spaziatura Y in mm

    // Punti per definire direzione e spaziatura
    this.basePoint = null;
    this.directionPoint = null;

    // Preview
    this.previewObjects = [];
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.selectedObjects = [];
    this.basePoint = null;
    this.directionPoint = null;
    this.previewObjects = [];
    this.cad.setStatus('PATTERN LINEAR: Seleziona oggetti (Enter per confermare)');
  }

  /**
   * Imposta parametri pattern
   * @param {number} countX - Numero copie direzione X
   * @param {number} countY - Numero copie direzione Y
   * @param {number} spacingX - Spaziatura X in mm
   * @param {number} spacingY - Spaziatura Y in mm
   */
  setPatternParams(countX, countY, spacingX, spacingY) {
    this.countX = Math.max(1, Math.floor(countX));
    this.countY = Math.max(1, Math.floor(countY));
    this.spacingX = Math.abs(spacingX);
    this.spacingY = Math.abs(spacingY);
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Fase 1: Selezione oggetti
    if (!this.basePoint) {
      const object = this.cad.getObjectAt(point);

      if (object && !this.selectedObjects.includes(object)) {
        this.selectedObjects.push(object);
        this.cad.setStatus(`PATTERN: ${this.selectedObjects.length} oggetti selezionati (Enter per confermare)`);
        this.cad.render();
      }
      return;
    }

    // Fase 2: Punto direzione (conferma pattern)
    if (this.basePoint && !this.directionPoint) {
      this.directionPoint = point;
      this.executePattern();
    }
  }

  /**
   * Handler tasto Enter - conferma selezione e crea pattern
   */
  onKeyPress(key) {
    if (key === 'Enter' && this.selectedObjects.length > 0 && !this.basePoint) {
      // Usa parametri default
      this.basePoint = { x: 0, y: 0 }; // Dummy, usa spacingX/Y
      this.directionPoint = { x: this.spacingX, y: this.spacingY };
      this.executePattern();
    }
  }

  /**
   * Mouse move handler - preview
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    if (this.basePoint && !this.directionPoint && this.selectedObjects.length > 0) {
      // Preview pattern con spaziatura dinamica
      const dx = point.x - this.basePoint.x;
      const dy = point.y - this.basePoint.y;

      this.generatePatternPreview(dx, dy);
      this.cad.render();
    }
  }

  /**
   * Esegue il pattern lineare
   */
  executePattern() {
    if (this.selectedObjects.length === 0) return;

    const dx = this.directionPoint ? (this.directionPoint.x - this.basePoint.x) : this.spacingX;
    const dy = this.directionPoint ? (this.directionPoint.y - this.basePoint.y) : this.spacingY;

    const createdObjects = [];

    // Crea pattern
    for (let row = 0; row < this.countY; row++) {
      for (let col = 0; col < this.countX; col++) {
        // Salta prima posizione (originali)
        if (row === 0 && col === 0) continue;

        const offsetX = col * dx;
        const offsetY = row * dy;

        for (const obj of this.selectedObjects) {
          const copied = this.translateObject(obj, offsetX, offsetY);
          if (copied) {
            this.cad.addObject(copied);
            createdObjects.push(copied);
          }
        }
      }
    }

    this.cad.saveHistory();
    this.cad.render();

    const totalObjects = this.countX * this.countY * this.selectedObjects.length;
    this.cad.setStatus(`PATTERN: Creati ${createdObjects.length} oggetti (${this.countX}×${this.countY} grid)`);

    // Reset
    this.selectedObjects = [];
    this.basePoint = null;
    this.directionPoint = null;
    this.previewObjects = [];
  }

  /**
   * Genera preview pattern
   * @param {number} dx - Spaziatura X
   * @param {number} dy - Spaziatura Y
   */
  generatePatternPreview(dx, dy) {
    this.previewObjects = [];

    for (let row = 0; row < this.countY; row++) {
      for (let col = 0; col < this.countX; col++) {
        // Salta prima posizione
        if (row === 0 && col === 0) continue;

        const offsetX = col * dx;
        const offsetY = row * dy;

        for (const obj of this.selectedObjects) {
          const copied = this.translateObject(obj, offsetX, offsetY);
          if (copied) {
            this.previewObjects.push(copied);
          }
        }
      }
    }
  }

  /**
   * Trasla un oggetto di (dx, dy)
   * @param {Object} object - Oggetto da traslare
   * @param {number} dx - Spostamento X
   * @param {number} dy - Spostamento Y
   * @returns {Object} Oggetto traslato
   */
  translateObject(object, dx, dy) {
    if (object.type === 'line') {
      return {
        ...object,
        p1: { x: object.p1.x + dx, y: object.p1.y + dy },
        p2: { x: object.p2.x + dx, y: object.p2.y + dy }
      };
    }

    if (object.type === 'circle') {
      return {
        ...object,
        cx: object.cx + dx,
        cy: object.cy + dy
      };
    }

    if (object.type === 'arc') {
      return {
        ...object,
        cx: object.cx + dx,
        cy: object.cy + dy
      };
    }

    if (object.type === 'rectangle') {
      return {
        ...object,
        x: object.x + dx,
        y: object.y + dy
      };
    }

    if (object.type === 'polyline') {
      return {
        ...object,
        points: object.points.map(p => ({ x: p.x + dx, y: p.y + dy }))
      };
    }

    if (object.type === 'dimension') {
      return {
        ...object,
        p1: object.p1 ? { x: object.p1.x + dx, y: object.p1.y + dy } : null,
        p2: object.p2 ? { x: object.p2.x + dx, y: object.p2.y + dy } : null,
        offset: object.offset ? { x: object.offset.x + dx, y: object.offset.y + dy } : null,
        vertex: object.vertex ? { x: object.vertex.x + dx, y: object.vertex.y + dy } : null,
        ray1Point: object.ray1Point ? { x: object.ray1Point.x + dx, y: object.ray1Point.y + dy } : null,
        ray2Point: object.ray2Point ? { x: object.ray2Point.x + dx, y: object.ray2Point.y + dy } : null
      };
    }

    return null;
  }

  /**
   * Render preview
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview(ctx) {
    if (!ctx) return;

    ctx.save();

    // Highlight oggetti selezionati
    ctx.strokeStyle = '#ff0000';
    ctx.lineWidth = 2;
    ctx.setLineDash([5, 5]);

    for (const obj of this.selectedObjects) {
      this.renderObjectOutline(ctx, obj);
    }

    ctx.setLineDash([]);

    // Preview pattern
    if (this.previewObjects.length > 0) {
      ctx.globalAlpha = 0.3;
      ctx.strokeStyle = '#00ff00';
      ctx.lineWidth = 1;

      for (const obj of this.previewObjects) {
        this.cad.drawObject(ctx, obj);
      }

      ctx.globalAlpha = 1;
    }

    // Griglia preview (linee tratteggiate)
    if (this.basePoint && this.previewObjects.length > 0) {
      ctx.strokeStyle = '#0000ff';
      ctx.lineWidth = 0.5;
      ctx.setLineDash([2, 2]);

      // Calcola bounds degli oggetti selezionati
      const bounds = this.getObjectsBounds(this.selectedObjects);

      if (bounds) {
        const centerX = (bounds.minX + bounds.maxX) / 2;
        const centerY = (bounds.minY + bounds.maxY) / 2;

        const dx = this.spacingX;
        const dy = this.spacingY;

        // Disegna griglia
        for (let row = 0; row <= this.countY; row++) {
          for (let col = 0; col <= this.countX; col++) {
            const x = centerX + col * dx;
            const y = centerY + row * dy;

            ctx.beginPath();
            ctx.arc(x, y, 2, 0, Math.PI * 2);
            ctx.stroke();
          }
        }
      }

      ctx.setLineDash([]);
    }

    ctx.restore();
  }

  /**
   * Render outline di oggetto
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   * @param {Object} object - Oggetto
   */
  renderObjectOutline(ctx, object) {
    if (object.type === 'line') {
      ctx.beginPath();
      ctx.moveTo(object.p1.x, object.p1.y);
      ctx.lineTo(object.p2.x, object.p2.y);
      ctx.stroke();
    }

    if (object.type === 'circle') {
      ctx.beginPath();
      ctx.arc(object.cx, object.cy, object.radius, 0, Math.PI * 2);
      ctx.stroke();
    }

    if (object.type === 'arc') {
      ctx.beginPath();
      ctx.arc(object.cx, object.cy, object.radius, object.startAngle, object.endAngle);
      ctx.stroke();
    }

    if (object.type === 'rectangle') {
      ctx.strokeRect(object.x, object.y, object.width, object.height);
    }

    if (object.type === 'polyline') {
      ctx.beginPath();
      ctx.moveTo(object.points[0].x, object.points[0].y);
      for (let i = 1; i < object.points.length; i++) {
        ctx.lineTo(object.points[i].x, object.points[i].y);
      }
      if (object.closed) ctx.closePath();
      ctx.stroke();
    }
  }

  /**
   * Calcola bounding box di oggetti
   * @param {Array} objects - Array di oggetti
   * @returns {Object|null} {minX, minY, maxX, maxY}
   */
  getObjectsBounds(objects) {
    if (objects.length === 0) return null;

    let minX = Infinity, minY = Infinity;
    let maxX = -Infinity, maxY = -Infinity;

    for (const obj of objects) {
      const bounds = this.getObjectBounds(obj);
      if (bounds) {
        minX = Math.min(minX, bounds.minX);
        minY = Math.min(minY, bounds.minY);
        maxX = Math.max(maxX, bounds.maxX);
        maxY = Math.max(maxY, bounds.maxY);
      }
    }

    return { minX, minY, maxX, maxY };
  }

  /**
   * Calcola bounding box di un oggetto
   * @param {Object} object - Oggetto
   * @returns {Object|null} {minX, minY, maxX, maxY}
   */
  getObjectBounds(object) {
    if (object.type === 'line') {
      return {
        minX: Math.min(object.p1.x, object.p2.x),
        minY: Math.min(object.p1.y, object.p2.y),
        maxX: Math.max(object.p1.x, object.p2.x),
        maxY: Math.max(object.p1.y, object.p2.y)
      };
    }

    if (object.type === 'circle' || object.type === 'arc') {
      return {
        minX: object.cx - object.radius,
        minY: object.cy - object.radius,
        maxX: object.cx + object.radius,
        maxY: object.cy + object.radius
      };
    }

    if (object.type === 'rectangle') {
      return {
        minX: object.x,
        minY: object.y,
        maxX: object.x + object.width,
        maxY: object.y + object.height
      };
    }

    if (object.type === 'polyline' && object.points.length > 0) {
      const xs = object.points.map(p => p.x);
      const ys = object.points.map(p => p.y);
      return {
        minX: Math.min(...xs),
        minY: Math.min(...ys),
        maxX: Math.max(...xs),
        maxY: Math.max(...ys)
      };
    }

    return null;
  }

  /**
   * Deattiva tool
   */
  deactivate() {
    this.selectedObjects = [];
    this.basePoint = null;
    this.directionPoint = null;
    this.previewObjects = [];
  }
}

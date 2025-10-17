/**
 * Rectangle Tool - Fusion 360 Style
 * Crea rettangoli con click-drag-release, centered mode, square mode
 *
 * @module RectangleTool
 * @author Box Designer CAD Engine
 */

export class RectangleTool {
  /**
   * Costruttore Rectangle Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'rectangle';
    this.cursor = 'crosshair';

    // Stato del tool
    this.startPoint = null;
    this.currentPoint = null;
    this.isDrawing = false;

    // Modalità
    this.centeredMode = false; // Alt key = centro invece di corner
    this.squareMode = false;   // Shift key = forza quadrato

    // Settings
    this.currentLineType = 'cut';
    this.snapToObjects = true;
    this.snapTolerance = 10; // mm
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.reset();
    this.updateStatus();
  }

  /**
   * Deattiva il tool
   */
  deactivate() {
    this.reset();
  }

  /**
   * Reset stato
   */
  reset() {
    this.startPoint = null;
    this.currentPoint = null;
    this.isDrawing = false;
    this.centeredMode = false;
    this.squareMode = false;
  }

  /**
   * Imposta tipo linea
   * @param {string} lineType - 'cut', 'crease', 'perforation', 'bleed'
   */
  setLineType(lineType) {
    this.currentLineType = lineType;
  }

  /**
   * Aggiorna status message
   */
  updateStatus() {
    if (!this.isDrawing) {
      let msg = 'RECTANGLE: Click primo corner (o Alt+Click per centered mode)';
      if (this.snapToObjects) msg += ' (Snap: ON)';
      this.cad.setStatus(msg);
    } else {
      let msg = 'RECTANGLE: Drag e release per secondo corner';

      if (this.centeredMode) {
        msg += ' [CENTERED]';
      }
      if (this.squareMode) {
        msg += ' [SQUARE]';
      }

      this.cad.setStatus(msg);
    }
  }

  /**
   * Mouse down handler (inizia rettangolo)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseDown(point, event) {
    // Snap to objects if enabled
    if (this.snapToObjects) {
      const snappedPoint = this.findSnapPoint(point);
      if (snappedPoint) {
        point = snappedPoint;
      }
    }

    this.startPoint = { ...point };
    this.currentPoint = { ...point };
    this.isDrawing = true;

    // Check for centered mode (Alt key)
    this.centeredMode = event.altKey;

    this.updateStatus();
  }

  /**
   * Mouse move handler (aggiorna preview)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseMove(point, event) {
    if (!this.isDrawing) return;

    // Snap to objects if enabled
    if (this.snapToObjects) {
      const snappedPoint = this.findSnapPoint(point);
      if (snappedPoint) {
        point = snappedPoint;
      }
    }

    // Check for square mode (Shift key)
    this.squareMode = event.shiftKey;

    // Apply square constraint if needed
    if (this.squareMode) {
      point = this.applySquareConstraint(point);
    }

    this.currentPoint = { ...point };
    this.cad.render();
  }

  /**
   * Mouse up handler (completa rettangolo)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseUp(point, event) {
    if (!this.isDrawing) return;

    // Snap to objects if enabled
    if (this.snapToObjects) {
      const snappedPoint = this.findSnapPoint(point);
      if (snappedPoint) {
        point = snappedPoint;
      }
    }

    // Apply square constraint if needed
    if (this.squareMode) {
      point = this.applySquareConstraint(point);
    }

    this.currentPoint = { ...point };
    this.createRectangle();
    this.reset();
    this.updateStatus();
    this.cad.render();
  }

  /**
   * Key press handler
   * @param {string} key - Tasto premuto
   * @param {Event} event - Keyboard event
   */
  onKeyPress(key, event) {
    // ESC - cancella
    if (key === 'Escape') {
      this.reset();
      this.updateStatus();
      this.cad.render();
      return;
    }

    // S - toggle snap to objects
    if (key === 's' || key === 'S') {
      this.snapToObjects = !this.snapToObjects;
      this.updateStatus();
      return;
    }
  }

  /**
   * Applica constraint quadrato
   * @param {Object} point - Punto da constrain
   * @returns {Object} Punto con constraint applicato
   */
  applySquareConstraint(point) {
    if (!this.startPoint) return point;

    const dx = point.x - this.startPoint.x;
    const dy = point.y - this.startPoint.y;

    // Use the larger dimension
    const size = Math.max(Math.abs(dx), Math.abs(dy));

    return {
      x: this.startPoint.x + (dx >= 0 ? size : -size),
      y: this.startPoint.y + (dy >= 0 ? size : -size)
    };
  }

  /**
   * Calcola coordinate rettangolo
   * @returns {Object} {x, y, width, height}
   */
  getRectangleCoordinates() {
    if (!this.startPoint || !this.currentPoint) return null;

    let x1 = this.startPoint.x;
    let y1 = this.startPoint.y;
    let x2 = this.currentPoint.x;
    let y2 = this.currentPoint.y;

    if (this.centeredMode) {
      // Centered mode: startPoint è il centro
      const halfWidth = Math.abs(x2 - x1);
      const halfHeight = Math.abs(y2 - y1);

      x1 = this.startPoint.x - halfWidth;
      y1 = this.startPoint.y - halfHeight;
      x2 = this.startPoint.x + halfWidth;
      y2 = this.startPoint.y + halfHeight;
    }

    // Normalizza coordinate (top-left corner + width/height)
    const x = Math.min(x1, x2);
    const y = Math.min(y1, y2);
    const width = Math.abs(x2 - x1);
    const height = Math.abs(y2 - y1);

    return { x, y, width, height };
  }

  /**
   * Trova punto di snap vicino
   * @param {Object} point - Punto da snappare
   * @returns {Object|null} Punto snappato o null
   */
  findSnapPoint(point) {
    const snapPoints = this.getSnapPoints();

    for (const snapPoint of snapPoints) {
      const dist = Math.hypot(point.x - snapPoint.x, point.y - snapPoint.y);
      if (dist < this.snapTolerance) {
        return snapPoint;
      }
    }

    return null;
  }

  /**
   * Ottieni tutti i punti di snap disponibili
   * @returns {Array} Array di punti {x, y}
   */
  getSnapPoints() {
    const points = [];

    for (const obj of this.cad.objects) {
      if (obj.type === 'line') {
        points.push(obj.p1, obj.p2);
      } else if (obj.type === 'rectangle') {
        points.push(
          { x: obj.x, y: obj.y },
          { x: obj.x + obj.width, y: obj.y },
          { x: obj.x + obj.width, y: obj.y + obj.height },
          { x: obj.x, y: obj.y + obj.height }
        );
      } else if (obj.type === 'circle') {
        points.push(
          { x: obj.cx + obj.radius, y: obj.cy },
          { x: obj.cx - obj.radius, y: obj.cy },
          { x: obj.cx, y: obj.cy + obj.radius },
          { x: obj.cx, y: obj.cy - obj.radius }
        );
      } else if (obj.type === 'polygon' && obj.points) {
        points.push(...obj.points);
      }
    }

    return points;
  }

  /**
   * Crea il rettangolo finale
   */
  createRectangle() {
    const coords = this.getRectangleCoordinates();
    if (!coords || coords.width < 1 || coords.height < 1) return;

    const rectangle = {
      type: 'rectangle',
      x: coords.x,
      y: coords.y,
      width: coords.width,
      height: coords.height,
      lineType: this.currentLineType
    };

    this.cad.addObject(rectangle);
    this.cad.saveHistory();
  }

  /**
   * Render preview
   * @param {CanvasRenderingContext2D} ctx - Context
   */
  renderPreview(ctx) {
    if (!this.isDrawing || !this.startPoint || !this.currentPoint) return;

    const coords = this.getRectangleCoordinates();
    if (!coords) return;

    ctx.save();

    // Preview rectangle (dashed, light color)
    ctx.strokeStyle = '#00aaff';
    ctx.lineWidth = 1 / this.cad.zoom;
    ctx.setLineDash([5 / this.cad.zoom, 5 / this.cad.zoom]);

    ctx.beginPath();
    ctx.rect(coords.x, coords.y, coords.width, coords.height);
    ctx.stroke();

    ctx.setLineDash([]);

    // Draw corner markers
    const markerSize = 4 / this.cad.zoom;
    ctx.fillStyle = '#00ff00';

    // Start point marker
    if (this.centeredMode) {
      // In centered mode, show center
      ctx.fillRect(
        this.startPoint.x - markerSize,
        this.startPoint.y - markerSize,
        markerSize * 2,
        markerSize * 2
      );
    } else {
      // Show corner
      ctx.fillRect(
        coords.x - markerSize,
        coords.y - markerSize,
        markerSize * 2,
        markerSize * 2
      );
    }

    // Current point marker
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(
      this.currentPoint.x - markerSize,
      this.currentPoint.y - markerSize,
      markerSize * 2,
      markerSize * 2
    );

    // Draw dimensions
    ctx.fillStyle = '#ffffff';
    ctx.font = `${12 / this.cad.zoom}px Arial`;

    const centerX = coords.x + coords.width / 2;
    const centerY = coords.y + coords.height / 2;

    // Width dimension (top)
    ctx.fillText(
      `W: ${coords.width.toFixed(2)}mm`,
      centerX,
      coords.y - 10 / this.cad.zoom
    );

    // Height dimension (right)
    ctx.save();
    ctx.translate(coords.x + coords.width + 10 / this.cad.zoom, centerY);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText(`H: ${coords.height.toFixed(2)}mm`, 0, 0);
    ctx.restore();

    // Area (center)
    const area = (coords.width * coords.height / 100).toFixed(2); // cm²
    ctx.fillText(
      `Area: ${area} cm²`,
      centerX,
      centerY
    );

    ctx.restore();
  }
}

/**
 * Circle Tool - Fusion 360 Style
 * Crea cerchi con center-radius (drag)
 *
 * @module CircleTool
 * @author Box Designer CAD Engine
 */

export class CircleTool {
  /**
   * Costruttore Circle Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'circle';
    this.cursor = 'crosshair';

    // Stato del tool
    this.centerPoint = null;
    this.currentPoint = null;
    this.isDrawing = false;

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
    this.centerPoint = null;
    this.currentPoint = null;
    this.isDrawing = false;
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
      let msg = 'CIRCLE: Click center point';
      if (this.snapToObjects) msg += ' (Snap: ON)';
      this.cad.setStatus(msg);
    } else {
      this.cad.setStatus('CIRCLE: Drag per definire raggio, release per completare');
    }
  }

  /**
   * Mouse down handler (imposta centro)
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

    this.centerPoint = { ...point };
    this.currentPoint = { ...point };
    this.isDrawing = true;

    this.updateStatus();
  }

  /**
   * Mouse move handler (aggiorna preview raggio)
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

    this.currentPoint = { ...point };
    this.cad.render();
  }

  /**
   * Mouse up handler (completa cerchio)
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

    this.currentPoint = { ...point };
    this.createCircle();
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
   * Calcola raggio corrente
   * @returns {number} Raggio in mm
   */
  getCurrentRadius() {
    if (!this.centerPoint || !this.currentPoint) return 0;

    const dx = this.currentPoint.x - this.centerPoint.x;
    const dy = this.currentPoint.y - this.centerPoint.y;

    return Math.sqrt(dx * dx + dy * dy);
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
        // Center + quadrants
        points.push(
          { x: obj.cx, y: obj.cy },
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
   * Crea il cerchio finale
   */
  createCircle() {
    const radius = this.getCurrentRadius();
    if (radius < 0.5) return; // Minimo 0.5mm

    const circle = {
      type: 'circle',
      cx: this.centerPoint.x,
      cy: this.centerPoint.y,
      radius: radius,
      lineType: this.currentLineType
    };

    this.cad.addObject(circle);
    this.cad.saveHistory();
  }

  /**
   * Render preview
   * @param {CanvasRenderingContext2D} ctx - Context
   */
  renderPreview(ctx) {
    if (!this.isDrawing || !this.centerPoint || !this.currentPoint) return;

    const radius = this.getCurrentRadius();
    if (radius < 0.1) return;

    ctx.save();

    // Preview circle (dashed, light color)
    ctx.strokeStyle = '#00aaff';
    ctx.lineWidth = 1 / this.cad.zoom;
    ctx.setLineDash([5 / this.cad.zoom, 5 / this.cad.zoom]);

    ctx.beginPath();
    ctx.arc(this.centerPoint.x, this.centerPoint.y, radius, 0, 2 * Math.PI);
    ctx.stroke();

    ctx.setLineDash([]);

    // Draw center marker
    const markerSize = 4 / this.cad.zoom;
    ctx.fillStyle = '#00ff00';
    ctx.fillRect(
      this.centerPoint.x - markerSize,
      this.centerPoint.y - markerSize,
      markerSize * 2,
      markerSize * 2
    );

    // Draw radius line
    ctx.strokeStyle = '#00aaff';
    ctx.lineWidth = 1 / this.cad.zoom;
    ctx.beginPath();
    ctx.moveTo(this.centerPoint.x, this.centerPoint.y);
    ctx.lineTo(this.currentPoint.x, this.currentPoint.y);
    ctx.stroke();

    // Draw current point marker
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(
      this.currentPoint.x - markerSize,
      this.currentPoint.y - markerSize,
      markerSize * 2,
      markerSize * 2
    );

    // Draw measurements
    ctx.fillStyle = '#ffffff';
    ctx.font = `${12 / this.cad.zoom}px Arial`;

    // Radius
    const midX = (this.centerPoint.x + this.currentPoint.x) / 2;
    const midY = (this.centerPoint.y + this.currentPoint.y) / 2;
    ctx.fillText(
      `R: ${radius.toFixed(2)}mm`,
      midX,
      midY - 10 / this.cad.zoom
    );

    // Diameter
    ctx.fillText(
      `Ø: ${(radius * 2).toFixed(2)}mm`,
      this.centerPoint.x,
      this.centerPoint.y - radius - 15 / this.cad.zoom
    );

    // Area
    const area = (Math.PI * radius * radius / 100).toFixed(2); // cm²
    ctx.fillText(
      `Area: ${area} cm²`,
      this.centerPoint.x,
      this.centerPoint.y + 5 / this.cad.zoom
    );

    // Circumference
    const circumference = (2 * Math.PI * radius).toFixed(2);
    ctx.fillText(
      `C: ${circumference}mm`,
      this.centerPoint.x,
      this.centerPoint.y + 20 / this.cad.zoom
    );

    ctx.restore();
  }
}

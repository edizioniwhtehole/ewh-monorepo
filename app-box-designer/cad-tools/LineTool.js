/**
 * Line Tool - Fusion 360 Style
 * Crea linee con click-click, constraints, snap
 *
 * @module LineTool
 * @author Box Designer CAD Engine
 */

export class LineTool {
  /**
   * Costruttore Line Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'line';
    this.cursor = 'crosshair';

    // Stato del tool
    this.startPoint = null;
    this.endPoint = null;
    this.previewPoint = null;

    // Modalità constraints
    this.constraintMode = null; // null, 'horizontal', 'vertical', 'angle'
    this.angleSnap = 15; // gradi (15, 30, 45, 90)

    // Settings
    this.currentLineType = 'cut';
    this.snapToObjects = true;
    this.snapTolerance = 10; // mm

    // Per catena di linee continue
    this.continuousMode = false;
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
    this.endPoint = null;
    this.previewPoint = null;
    this.constraintMode = null;
  }

  /**
   * Imposta tipo linea
   * @param {string} lineType - 'cut', 'crease', 'perforation', 'bleed'
   */
  setLineType(lineType) {
    this.currentLineType = lineType;
  }

  /**
   * Toggle continuous mode (catena di linee)
   * @param {boolean} enabled - Enable/disable
   */
  setContinuousMode(enabled) {
    this.continuousMode = enabled;
    if (!enabled) {
      this.reset();
    }
  }

  /**
   * Aggiorna status message
   */
  updateStatus() {
    if (!this.startPoint) {
      let msg = 'LINE: Click primo punto';
      if (this.snapToObjects) msg += ' (Snap: ON)';
      this.cad.setStatus(msg);
    } else {
      let msg = 'LINE: Click secondo punto';

      if (this.constraintMode === 'horizontal') {
        msg += ' [HORIZONTAL]';
      } else if (this.constraintMode === 'vertical') {
        msg += ' [VERTICAL]';
      } else if (this.constraintMode === 'angle') {
        msg += ` [ANGLE SNAP ${this.angleSnap}°]`;
      }

      if (this.continuousMode) {
        msg += ' (Continuous)';
      }

      this.cad.setStatus(msg);
    }
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Snap to objects if enabled
    if (this.snapToObjects) {
      const snappedPoint = this.findSnapPoint(point);
      if (snappedPoint) {
        point = snappedPoint;
      }
    }

    if (!this.startPoint) {
      // Primo punto
      this.startPoint = { ...point };
      this.updateStatus();
    } else {
      // Secondo punto - crea linea
      this.endPoint = { ...point };
      this.createLine();

      if (this.continuousMode) {
        // Modalità continua: nuovo startPoint = vecchio endPoint
        this.startPoint = { ...this.endPoint };
        this.endPoint = null;
      } else {
        // Reset per nuova linea
        this.reset();
      }

      this.updateStatus();
      this.cad.render();
    }
  }

  /**
   * Mouse move handler (per preview rubberband)
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onMouseMove(point, event) {
    if (!this.startPoint) {
      this.previewPoint = null;
      return;
    }

    // Snap to objects if enabled
    if (this.snapToObjects) {
      const snappedPoint = this.findSnapPoint(point);
      if (snappedPoint) {
        point = snappedPoint;
      }
    }

    // Applica constraints
    point = this.applyConstraints(point, event);

    this.previewPoint = { ...point };
    this.cad.render();
  }

  /**
   * Key press handler (per constraints e shortcuts)
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

    // Enter - conferma e reset
    if (key === 'Enter') {
      this.reset();
      this.updateStatus();
      this.cad.render();
      return;
    }

    // C - toggle continuous mode
    if (key === 'c' || key === 'C') {
      this.continuousMode = !this.continuousMode;
      this.updateStatus();
      return;
    }

    // H - horizontal constraint
    if (key === 'h' || key === 'H') {
      this.constraintMode = this.constraintMode === 'horizontal' ? null : 'horizontal';
      this.updateStatus();
      this.cad.render();
      return;
    }

    // V - vertical constraint
    if (key === 'v' || key === 'V') {
      this.constraintMode = this.constraintMode === 'vertical' ? null : 'vertical';
      this.updateStatus();
      this.cad.render();
      return;
    }

    // A - angle snap constraint
    if (key === 'a' || key === 'A') {
      this.constraintMode = this.constraintMode === 'angle' ? null : 'angle';
      this.updateStatus();
      this.cad.render();
      return;
    }

    // 1-4 - set angle snap increment
    if (key >= '1' && key <= '4') {
      const angles = { '1': 15, '2': 30, '3': 45, '4': 90 };
      this.angleSnap = angles[key];
      this.constraintMode = 'angle';
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
   * Applica constraints al punto
   * @param {Object} point - Punto da constrain
   * @param {Event} event - Mouse event (per Shift key)
   * @returns {Object} Punto con constraint applicato
   */
  applyConstraints(point, event) {
    if (!this.startPoint) return point;

    const constrainedPoint = { ...point };

    // Shift key = temporary horizontal/vertical snap
    if (event && event.shiftKey) {
      const dx = Math.abs(point.x - this.startPoint.x);
      const dy = Math.abs(point.y - this.startPoint.y);

      if (dx > dy) {
        // Horizontal
        constrainedPoint.y = this.startPoint.y;
      } else {
        // Vertical
        constrainedPoint.x = this.startPoint.x;
      }
      return constrainedPoint;
    }

    // Constraint modes
    if (this.constraintMode === 'horizontal') {
      constrainedPoint.y = this.startPoint.y;
    } else if (this.constraintMode === 'vertical') {
      constrainedPoint.x = this.startPoint.x;
    } else if (this.constraintMode === 'angle') {
      // Snap to angle increments
      const dx = point.x - this.startPoint.x;
      const dy = point.y - this.startPoint.y;
      const angle = Math.atan2(dy, dx);
      const length = Math.sqrt(dx * dx + dy * dy);

      // Snap angle to nearest increment
      const angleSnap = (this.angleSnap * Math.PI) / 180;
      const snappedAngle = Math.round(angle / angleSnap) * angleSnap;

      constrainedPoint.x = this.startPoint.x + length * Math.cos(snappedAngle);
      constrainedPoint.y = this.startPoint.y + length * Math.sin(snappedAngle);
    }

    return constrainedPoint;
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
      } else if (obj.type === 'circle') {
        // Quadrants
        points.push(
          { x: obj.cx + obj.radius, y: obj.cy },
          { x: obj.cx - obj.radius, y: obj.cy },
          { x: obj.cx, y: obj.cy + obj.radius },
          { x: obj.cx, y: obj.cy - obj.radius }
        );
      } else if (obj.type === 'arc') {
        // Start and end points of arc
        points.push(
          {
            x: obj.cx + obj.radius * Math.cos(obj.startAngle),
            y: obj.cy + obj.radius * Math.sin(obj.startAngle)
          },
          {
            x: obj.cx + obj.radius * Math.cos(obj.endAngle),
            y: obj.cy + obj.radius * Math.sin(obj.endAngle)
          }
        );
      } else if (obj.type === 'rectangle') {
        // 4 corners
        points.push(
          { x: obj.x, y: obj.y },
          { x: obj.x + obj.width, y: obj.y },
          { x: obj.x + obj.width, y: obj.y + obj.height },
          { x: obj.x, y: obj.y + obj.height }
        );
      } else if (obj.type === 'polygon' && obj.points) {
        points.push(...obj.points);
      }
    }

    return points;
  }

  /**
   * Crea la linea finale
   */
  createLine() {
    if (!this.startPoint || !this.endPoint) return;

    const line = {
      type: 'line',
      p1: { ...this.startPoint },
      p2: { ...this.endPoint },
      lineType: this.currentLineType
    };

    this.cad.addObject(line);
    this.cad.saveHistory();
  }

  /**
   * Render preview (rubberband)
   * @param {CanvasRenderingContext2D} ctx - Context
   */
  renderPreview(ctx) {
    if (!this.startPoint || !this.previewPoint) return;

    // Rubberband line (dashed, light color)
    ctx.save();
    ctx.strokeStyle = '#00aaff';
    ctx.lineWidth = 1 / this.cad.zoom;
    ctx.setLineDash([5 / this.cad.zoom, 5 / this.cad.zoom]);

    ctx.beginPath();
    ctx.moveTo(this.startPoint.x, this.startPoint.y);
    ctx.lineTo(this.previewPoint.x, this.previewPoint.y);
    ctx.stroke();

    ctx.setLineDash([]);

    // Draw start point marker
    ctx.fillStyle = '#00ff00';
    const markerSize = 4 / this.cad.zoom;
    ctx.fillRect(
      this.startPoint.x - markerSize,
      this.startPoint.y - markerSize,
      markerSize * 2,
      markerSize * 2
    );

    // Draw end point marker
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(
      this.previewPoint.x - markerSize,
      this.previewPoint.y - markerSize,
      markerSize * 2,
      markerSize * 2
    );

    // Draw dimension/length
    const dx = this.previewPoint.x - this.startPoint.x;
    const dy = this.previewPoint.y - this.startPoint.y;
    const length = Math.sqrt(dx * dx + dy * dy);
    const angle = (Math.atan2(dy, dx) * 180) / Math.PI;

    const midX = (this.startPoint.x + this.previewPoint.x) / 2;
    const midY = (this.startPoint.y + this.previewPoint.y) / 2;

    ctx.fillStyle = '#ffffff';
    ctx.font = `${12 / this.cad.zoom}px Arial`;
    ctx.fillText(
      `${length.toFixed(2)}mm @ ${angle.toFixed(1)}°`,
      midX,
      midY - 10 / this.cad.zoom
    );

    ctx.restore();
  }
}

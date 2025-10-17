/**
 * Angular Dimension Tool - Fusion 360 Style
 * Aggiunge quote angolari con arco e misura in gradi
 *
 * @module AngularDimensionTool
 * @author Box Designer CAD Engine
 */

export class AngularDimensionTool {
  /**
   * Costruttore Angular Dimension Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'angular_dimension';
    this.cursor = 'crosshair';

    // Punti della dimensione angolare
    this.vertex = null; // Vertice dell'angolo
    this.ray1Point = null; // Punto su primo raggio
    this.ray2Point = null; // Punto su secondo raggio
    this.arcRadiusPoint = null; // Punto per definire raggio arco

    // Stile dimensioni
    this.textHeight = 3; // mm
    this.arrowSize = 2; // mm
    this.precision = 1; // Decimali per gradi
    this.unit = '°'; // Gradi
    this.arcRadius = 20; // Default mm
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.vertex = null;
    this.ray1Point = null;
    this.ray2Point = null;
    this.arcRadiusPoint = null;
    this.cad.setStatus('ANGULAR: Click vertice dell\'angolo');
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    if (!this.vertex) {
      // Vertice (centro angolo)
      this.vertex = this.snapToObject(point);
      this.cad.setStatus('ANGULAR: Click punto su primo raggio');
      return;
    }

    if (!this.ray1Point) {
      // Punto su primo raggio
      this.ray1Point = this.snapToObject(point);
      this.cad.setStatus('ANGULAR: Click punto su secondo raggio');
      return;
    }

    if (!this.ray2Point) {
      // Punto su secondo raggio
      this.ray2Point = this.snapToObject(point);
      this.cad.setStatus('ANGULAR: Click per posizionare quota (raggio arco)');
      return;
    }

    if (!this.arcRadiusPoint) {
      // Punto per raggio arco
      this.arcRadiusPoint = point;
      this.createAngularDimension();
    }
  }

  /**
   * Mouse move handler - preview
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    if (this.vertex && !this.ray1Point) {
      // Preview primo raggio
      this.previewRay1 = point;
      this.cad.render();
    } else if (this.vertex && this.ray1Point && !this.ray2Point) {
      // Preview secondo raggio + angolo
      this.previewRay2 = point;
      this.cad.render();
    } else if (this.vertex && this.ray1Point && this.ray2Point && !this.arcRadiusPoint) {
      // Preview quota con raggio variabile
      this.previewArcRadius = point;
      this.cad.render();
    }
  }

  /**
   * Snap a oggetti esistenti
   * @param {Object} point - Punto {x, y}
   * @returns {Object} Punto snappato {x, y}
   */
  snapToObject(point) {
    const object = this.cad.getObjectAt(point, 5);

    if (object) {
      if (object.type === 'line') {
        const d1 = this.distance(point, object.p1);
        const d2 = this.distance(point, object.p2);

        if (d1 < 10) return object.p1;
        if (d2 < 10) return object.p2;

        return this.projectPointOnLine(point, object);
      }
    }

    return point;
  }

  /**
   * Crea la dimensione angolare
   */
  createAngularDimension() {
    // Calcola angoli
    const angle1 = Math.atan2(this.ray1Point.y - this.vertex.y, this.ray1Point.x - this.vertex.x);
    const angle2 = Math.atan2(this.ray2Point.y - this.vertex.y, this.ray2Point.x - this.vertex.x);

    // Calcola raggio arco dalla distanza del punto click
    const arcRadius = this.distance(this.vertex, this.arcRadiusPoint);

    const dimension = {
      type: 'dimension',
      dimensionType: 'angular',
      vertex: this.vertex,
      ray1Point: this.ray1Point,
      ray2Point: this.ray2Point,
      angle1: angle1,
      angle2: angle2,
      arcRadius: arcRadius,
      textHeight: this.textHeight,
      arrowSize: this.arrowSize,
      precision: this.precision,
      unit: this.unit
    };

    this.cad.addObject(dimension);
    this.cad.saveHistory();
    this.cad.render();

    const angleDeg = this.calculateAngleDegrees(angle1, angle2);
    this.cad.setStatus(`ANGULAR: Quota creata (${angleDeg.toFixed(this.precision)}°)`);

    // Reset
    this.vertex = null;
    this.ray1Point = null;
    this.ray2Point = null;
    this.arcRadiusPoint = null;
    this.previewRay1 = null;
    this.previewRay2 = null;
    this.previewArcRadius = null;
  }

  /**
   * Calcola angolo in gradi (sempre positivo, minore di 360°)
   * @param {number} angle1 - Primo angolo in radianti
   * @param {number} angle2 - Secondo angolo in radianti
   * @returns {number} Angolo in gradi
   */
  calculateAngleDegrees(angle1, angle2) {
    let diff = angle2 - angle1;

    // Normalizza tra -π e π
    while (diff > Math.PI) diff -= 2 * Math.PI;
    while (diff < -Math.PI) diff += 2 * Math.PI;

    // Converti in gradi e rendi positivo
    let degrees = Math.abs(diff * 180 / Math.PI);

    return degrees;
  }

  /**
   * Render preview
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview(ctx) {
    if (!ctx) return;

    ctx.save();

    // Preview vertice
    if (this.vertex) {
      ctx.fillStyle = '#ff0000';
      ctx.beginPath();
      ctx.arc(this.vertex.x, this.vertex.y, 3, 0, Math.PI * 2);
      ctx.fill();
    }

    // Preview primo raggio
    if (this.vertex && this.previewRay1) {
      ctx.strokeStyle = '#ff0000';
      ctx.lineWidth = 1;
      ctx.setLineDash([5, 5]);

      ctx.beginPath();
      ctx.moveTo(this.vertex.x, this.vertex.y);
      ctx.lineTo(this.previewRay1.x, this.previewRay1.y);
      ctx.stroke();

      ctx.setLineDash([]);
    }

    // Preview secondo raggio + angolo
    if (this.vertex && this.ray1Point && this.previewRay2) {
      ctx.strokeStyle = '#0000ff';
      ctx.lineWidth = 1;
      ctx.setLineDash([5, 5]);

      ctx.beginPath();
      ctx.moveTo(this.vertex.x, this.vertex.y);
      ctx.lineTo(this.previewRay2.x, this.previewRay2.y);
      ctx.stroke();

      ctx.setLineDash([]);

      // Preview arco angolo
      const angle1 = Math.atan2(this.ray1Point.y - this.vertex.y, this.ray1Point.x - this.vertex.x);
      const angle2 = Math.atan2(this.previewRay2.y - this.vertex.y, this.previewRay2.x - this.vertex.x);

      ctx.strokeStyle = '#00ff00';
      ctx.lineWidth = 1;

      ctx.beginPath();
      ctx.arc(this.vertex.x, this.vertex.y, this.arcRadius, angle1, angle2);
      ctx.stroke();

      // Mostra angolo temporaneo
      const angleDeg = this.calculateAngleDegrees(angle1, angle2);
      const midAngle = (angle1 + angle2) / 2;
      const textX = this.vertex.x + Math.cos(midAngle) * (this.arcRadius + 10);
      const textY = this.vertex.y + Math.sin(midAngle) * (this.arcRadius + 10);

      ctx.fillStyle = '#000';
      ctx.font = `${this.textHeight}px Arial`;
      ctx.fillText(`${angleDeg.toFixed(this.precision)}°`, textX, textY);
    }

    // Preview quota completa con raggio variabile
    if (this.vertex && this.ray1Point && this.ray2Point && this.previewArcRadius) {
      const angle1 = Math.atan2(this.ray1Point.y - this.vertex.y, this.ray1Point.x - this.vertex.x);
      const angle2 = Math.atan2(this.ray2Point.y - this.vertex.y, this.ray2Point.x - this.vertex.x);
      const arcRadius = this.distance(this.vertex, this.previewArcRadius);

      const dimension = {
        type: 'dimension',
        dimensionType: 'angular',
        vertex: this.vertex,
        ray1Point: this.ray1Point,
        ray2Point: this.ray2Point,
        angle1: angle1,
        angle2: angle2,
        arcRadius: arcRadius,
        textHeight: this.textHeight,
        arrowSize: this.arrowSize,
        precision: this.precision,
        unit: this.unit
      };

      this.renderAngularDimension(ctx, dimension);
    }

    ctx.restore();
  }

  /**
   * Render di una dimensione angolare
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   * @param {Object} dimension - Oggetto dimensione
   */
  renderAngularDimension(ctx, dimension) {
    const vertex = dimension.vertex;
    const angle1 = dimension.angle1;
    const angle2 = dimension.angle2;
    const radius = dimension.arcRadius;

    ctx.save();

    // Stile linea quota
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 0.5;

    // Linee di estensione (raggi)
    ctx.setLineDash([2, 2]);

    const ray1End = {
      x: vertex.x + Math.cos(angle1) * (radius + 10),
      y: vertex.y + Math.sin(angle1) * (radius + 10)
    };

    const ray2End = {
      x: vertex.x + Math.cos(angle2) * (radius + 10),
      y: vertex.y + Math.sin(angle2) * (radius + 10)
    };

    ctx.beginPath();
    ctx.moveTo(vertex.x, vertex.y);
    ctx.lineTo(ray1End.x, ray1End.y);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(vertex.x, vertex.y);
    ctx.lineTo(ray2End.x, ray2End.y);
    ctx.stroke();

    ctx.setLineDash([]);

    // Arco quota
    ctx.lineWidth = 1;

    ctx.beginPath();
    ctx.arc(vertex.x, vertex.y, radius, angle1, angle2);
    ctx.stroke();

    // Frecce agli estremi dell'arco
    const arc1Point = {
      x: vertex.x + Math.cos(angle1) * radius,
      y: vertex.y + Math.sin(angle1) * radius
    };

    const arc2Point = {
      x: vertex.x + Math.cos(angle2) * radius,
      y: vertex.y + Math.sin(angle2) * radius
    };

    // Freccia 1 (tangente all'arco)
    const tangent1 = {
      x: arc1Point.x + Math.cos(angle1 + Math.PI / 2) * dimension.arrowSize,
      y: arc1Point.y + Math.sin(angle1 + Math.PI / 2) * dimension.arrowSize
    };

    this.drawArcArrow(ctx, arc1Point, angle1 + Math.PI / 2, dimension.arrowSize);

    // Freccia 2
    this.drawArcArrow(ctx, arc2Point, angle2 - Math.PI / 2, dimension.arrowSize);

    // Testo misura
    const angleDeg = this.calculateAngleDegrees(angle1, angle2);
    const midAngle = (angle1 + angle2) / 2;
    const textX = vertex.x + Math.cos(midAngle) * (radius + 5);
    const textY = vertex.y + Math.sin(midAngle) * (radius + 5);

    const text = `${angleDeg.toFixed(dimension.precision)}${dimension.unit}`;

    ctx.fillStyle = '#000';
    ctx.font = `${dimension.textHeight}px Arial`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    // Background bianco
    const textWidth = ctx.measureText(text).width;
    ctx.fillStyle = '#fff';
    ctx.fillRect(textX - textWidth / 2 - 2, textY - dimension.textHeight / 2 - 1, textWidth + 4, dimension.textHeight + 2);

    ctx.fillStyle = '#000';
    ctx.fillText(text, textX, textY);

    ctx.restore();
  }

  /**
   * Disegna freccia tangente all'arco
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   * @param {Object} point - Punto sull'arco
   * @param {number} tangentAngle - Angolo tangente
   * @param {number} size - Dimensione freccia
   */
  drawArcArrow(ctx, point, tangentAngle, size) {
    const dirX = Math.cos(tangentAngle);
    const dirY = Math.sin(tangentAngle);

    // Punta freccia
    const tipX = point.x + dirX * size;
    const tipY = point.y + dirY * size;

    // Lati freccia
    const angle = 30 * Math.PI / 180;

    const side1X = point.x + Math.cos(tangentAngle - angle) * size;
    const side1Y = point.y + Math.sin(tangentAngle - angle) * size;

    const side2X = point.x + Math.cos(tangentAngle + angle) * size;
    const side2Y = point.y + Math.sin(tangentAngle + angle) * size;

    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.moveTo(point.x, point.y);
    ctx.lineTo(side1X, side1Y);
    ctx.lineTo(tipX, tipY);
    ctx.lineTo(side2X, side2Y);
    ctx.closePath();
    ctx.fill();
  }

  /**
   * Calcola distanza tra due punti
   * @param {Object} p1 - Punto {x, y}
   * @param {Object} p2 - Punto {x, y}
   * @returns {number} Distanza
   */
  distance(p1, p2) {
    const dx = p2.x - p1.x;
    const dy = p2.y - p1.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Proietta punto su linea
   * @param {Object} point - Punto {x, y}
   * @param {Object} line - Linea {p1, p2}
   * @returns {Object} Punto proiettato {x, y}
   */
  projectPointOnLine(point, line) {
    const dx = line.p2.x - line.p1.x;
    const dy = line.p2.y - line.p1.y;

    const fx = point.x - line.p1.x;
    const fy = point.y - line.p1.y;

    const t = (fx * dx + fy * dy) / (dx * dx + dy * dy);

    return {
      x: line.p1.x + t * dx,
      y: line.p1.y + t * dy
    };
  }

  /**
   * Imposta raggio arco di default
   * @param {number} radius - Raggio in mm
   */
  setArcRadius(radius) {
    this.arcRadius = Math.abs(radius);
  }

  /**
   * Imposta precisione decimali
   * @param {number} precision - Numero decimali
   */
  setPrecision(precision) {
    this.precision = Math.max(0, Math.min(2, precision));
  }

  /**
   * Deattiva tool
   */
  deactivate() {
    this.vertex = null;
    this.ray1Point = null;
    this.ray2Point = null;
    this.arcRadiusPoint = null;
    this.previewRay1 = null;
    this.previewRay2 = null;
    this.previewArcRadius = null;
  }
}

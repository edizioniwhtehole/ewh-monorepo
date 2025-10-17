/**
 * Linear Dimension Tool - Fusion 360 Style
 * Aggiunge quote lineari con frecce e misure precise
 *
 * @module LinearDimensionTool
 * @author Box Designer CAD Engine
 */

export class LinearDimensionTool {
  /**
   * Costruttore Linear Dimension Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'linear_dimension';
    this.cursor = 'crosshair';

    // Punti della dimensione
    this.point1 = null;
    this.point2 = null;
    this.offsetPoint = null;

    // Stile dimensioni
    this.textHeight = 3; // mm
    this.arrowSize = 2; // mm
    this.precision = 2; // Decimali
    this.unit = 'mm';
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.point1 = null;
    this.point2 = null;
    this.offsetPoint = null;
    this.cad.setStatus('DIMENSION: Click primo punto');
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    if (!this.point1) {
      // Primo punto
      this.point1 = this.snapToObject(point);
      this.cad.setStatus('DIMENSION: Click secondo punto');
      return;
    }

    if (!this.point2) {
      // Secondo punto
      this.point2 = this.snapToObject(point);
      this.cad.setStatus('DIMENSION: Click per posizionare la quota');
      return;
    }

    if (!this.offsetPoint) {
      // Punto offset (posizione linea quota)
      this.offsetPoint = point;
      this.createDimension();
    }
  }

  /**
   * Mouse move handler - preview
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    if (this.point1 && !this.point2) {
      // Preview linea di misura
      this.previewPoint = point;
      this.cad.render();
    } else if (this.point1 && this.point2 && !this.offsetPoint) {
      // Preview quota con offset
      this.previewOffset = point;
      this.cad.render();
    }
  }

  /**
   * Snap a oggetti esistenti (vertici, intersezioni, etc.)
   * @param {Object} point - Punto {x, y}
   * @returns {Object} Punto snappato {x, y}
   */
  snapToObject(point) {
    // Cerca oggetti vicini
    const object = this.cad.getObjectAt(point, 5); // 5mm di tolleranza

    if (object) {
      // Snap a vertici
      if (object.type === 'line') {
        const d1 = this.distance(point, object.p1);
        const d2 = this.distance(point, object.p2);

        if (d1 < 10) return object.p1;
        if (d2 < 10) return object.p2;

        // Snap a punto sulla linea
        return this.projectPointOnLine(point, object);
      }

      if (object.type === 'circle' || object.type === 'arc') {
        const center = { x: object.cx, y: object.cy };
        const angle = Math.atan2(point.y - center.y, point.x - center.x);

        return {
          x: center.x + Math.cos(angle) * object.radius,
          y: center.y + Math.sin(angle) * object.radius
        };
      }
    }

    return point;
  }

  /**
   * Crea la dimensione
   */
  createDimension() {
    const dimension = {
      type: 'dimension',
      dimensionType: 'linear',
      p1: this.point1,
      p2: this.point2,
      offset: this.offsetPoint,
      textHeight: this.textHeight,
      arrowSize: this.arrowSize,
      precision: this.precision,
      unit: this.unit
    };

    this.cad.addObject(dimension);
    this.cad.saveHistory();
    this.cad.render();

    const length = this.distance(this.point1, this.point2);
    this.cad.setStatus(`DIMENSION: Quota creata (${length.toFixed(this.precision)} ${this.unit})`);

    // Reset
    this.point1 = null;
    this.point2 = null;
    this.offsetPoint = null;
    this.previewPoint = null;
    this.previewOffset = null;
  }

  /**
   * Render preview
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview(ctx) {
    if (!ctx) return;

    ctx.save();

    // Preview primo punto
    if (this.point1) {
      ctx.fillStyle = '#ff0000';
      ctx.beginPath();
      ctx.arc(this.point1.x, this.point1.y, 3, 0, Math.PI * 2);
      ctx.fill();
    }

    // Preview linea tra punti
    if (this.point1 && this.previewPoint) {
      ctx.strokeStyle = '#ff0000';
      ctx.lineWidth = 1;
      ctx.setLineDash([5, 5]);

      ctx.beginPath();
      ctx.moveTo(this.point1.x, this.point1.y);
      ctx.lineTo(this.previewPoint.x, this.previewPoint.y);
      ctx.stroke();

      ctx.setLineDash([]);

      // Mostra lunghezza temporanea
      const length = this.distance(this.point1, this.previewPoint);
      const midX = (this.point1.x + this.previewPoint.x) / 2;
      const midY = (this.point1.y + this.previewPoint.y) / 2;

      ctx.fillStyle = '#000';
      ctx.font = `${this.textHeight}px Arial`;
      ctx.fillText(`${length.toFixed(this.precision)} ${this.unit}`, midX, midY - 5);
    }

    // Preview quota completa con offset
    if (this.point1 && this.point2 && this.previewOffset) {
      const dimension = {
        type: 'dimension',
        dimensionType: 'linear',
        p1: this.point1,
        p2: this.point2,
        offset: this.previewOffset,
        textHeight: this.textHeight,
        arrowSize: this.arrowSize,
        precision: this.precision,
        unit: this.unit
      };

      this.renderDimension(ctx, dimension);
    }

    ctx.restore();
  }

  /**
   * Render di una dimensione
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   * @param {Object} dimension - Oggetto dimensione
   */
  renderDimension(ctx, dimension) {
    const p1 = dimension.p1;
    const p2 = dimension.p2;
    const offset = dimension.offset;

    // Calcola direzione linea di misura
    const dx = p2.x - p1.x;
    const dy = p2.y - p1.y;
    const length = Math.sqrt(dx * dx + dy * dy);
    const dirX = dx / length;
    const dirY = dy / length;

    // Vettore perpendicolare
    const perpX = -dirY;
    const perpY = dirX;

    // Distanza offset dalla linea
    const offsetDist = this.distancePointToLine(offset, p1, p2);
    const offsetSide = this.sideOfLine(offset, p1, p2);

    // Punti della linea di quota
    const dimP1 = {
      x: p1.x + perpX * offsetDist * offsetSide,
      y: p1.y + perpY * offsetDist * offsetSide
    };

    const dimP2 = {
      x: p2.x + perpX * offsetDist * offsetSide,
      y: p2.y + perpY * offsetDist * offsetSide
    };

    ctx.save();

    // Stile linea quota
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 0.5;

    // Linee di estensione (da punti a linea quota)
    ctx.setLineDash([2, 2]);

    ctx.beginPath();
    ctx.moveTo(p1.x, p1.y);
    ctx.lineTo(dimP1.x, dimP1.y);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(p2.x, p2.y);
    ctx.lineTo(dimP2.x, dimP2.y);
    ctx.stroke();

    ctx.setLineDash([]);

    // Linea di quota principale
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(dimP1.x, dimP1.y);
    ctx.lineTo(dimP2.x, dimP2.y);
    ctx.stroke();

    // Frecce
    this.drawArrow(ctx, dimP1, dimP2, dimension.arrowSize);
    this.drawArrow(ctx, dimP2, dimP1, dimension.arrowSize);

    // Testo misura
    const midX = (dimP1.x + dimP2.x) / 2;
    const midY = (dimP1.y + dimP2.y) / 2;

    const text = `${length.toFixed(dimension.precision)} ${dimension.unit}`;

    ctx.fillStyle = '#000';
    ctx.font = `${dimension.textHeight}px Arial`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    // Background bianco per leggibilità
    const textWidth = ctx.measureText(text).width;
    ctx.fillStyle = '#fff';
    ctx.fillRect(midX - textWidth / 2 - 2, midY - dimension.textHeight / 2 - 1, textWidth + 4, dimension.textHeight + 2);

    ctx.fillStyle = '#000';
    ctx.fillText(text, midX, midY);

    ctx.restore();
  }

  /**
   * Disegna freccia
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   * @param {Object} from - Punto da cui parte la freccia
   * @param {Object} to - Punto verso cui punta la freccia (direzione)
   * @param {number} size - Dimensione freccia
   */
  drawArrow(ctx, from, to, size) {
    const dx = to.x - from.x;
    const dy = to.y - from.y;
    const len = Math.sqrt(dx * dx + dy * dy);
    const dirX = dx / len;
    const dirY = dy / len;

    // Punta freccia
    const tipX = from.x + dirX * size;
    const tipY = from.y + dirY * size;

    // Lati freccia (30 gradi)
    const angle = 30 * Math.PI / 180;
    const cos30 = Math.cos(angle);
    const sin30 = Math.sin(angle);

    const side1X = from.x + (dirX * cos30 - dirY * sin30) * size;
    const side1Y = from.y + (dirX * sin30 + dirY * cos30) * size;

    const side2X = from.x + (dirX * cos30 + dirY * sin30) * size;
    const side2Y = from.y + (-dirX * sin30 + dirY * cos30) * size;

    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.moveTo(from.x, from.y);
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
   * Distanza punto-linea
   * @param {Object} point - Punto {x, y}
   * @param {Object} lineP1 - Primo punto linea
   * @param {Object} lineP2 - Secondo punto linea
   * @returns {number} Distanza
   */
  distancePointToLine(point, lineP1, lineP2) {
    const dx = lineP2.x - lineP1.x;
    const dy = lineP2.y - lineP1.y;
    const len = Math.sqrt(dx * dx + dy * dy);

    const cross = Math.abs((point.x - lineP1.x) * dy - (point.y - lineP1.y) * dx);

    return cross / len;
  }

  /**
   * Determina su quale lato della linea si trova il punto
   * @param {Object} point - Punto {x, y}
   * @param {Object} lineP1 - Primo punto linea
   * @param {Object} lineP2 - Secondo punto linea
   * @returns {number} +1 o -1
   */
  sideOfLine(point, lineP1, lineP2) {
    const cross = (point.x - lineP1.x) * (lineP2.y - lineP1.y) - (point.y - lineP1.y) * (lineP2.x - lineP1.x);
    return cross > 0 ? 1 : -1;
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
   * Imposta precisione decimali
   * @param {number} precision - Numero decimali
   */
  setPrecision(precision) {
    this.precision = Math.max(0, Math.min(4, precision));
  }

  /**
   * Imposta unità di misura
   * @param {string} unit - Unità ('mm', 'cm', 'in')
   */
  setUnit(unit) {
    this.unit = unit;
  }

  /**
   * Deattiva tool
   */
  deactivate() {
    this.point1 = null;
    this.point2 = null;
    this.offsetPoint = null;
    this.previewPoint = null;
    this.previewOffset = null;
  }
}

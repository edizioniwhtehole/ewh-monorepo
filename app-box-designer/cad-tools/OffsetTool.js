/**
 * Offset Tool - Fusion 360 Style
 * Crea copie parallele di linee, archi e curve a distanza specificata
 *
 * @module OffsetTool
 * @author Box Designer CAD Engine
 */

export class OffsetTool {
  /**
   * Costruttore Offset Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'offset';
    this.cursor = 'crosshair';

    // Stato tool
    this.selectedObject = null;
    this.distance = 10; // Default 10mm
    this.side = null; // 'left' | 'right' | 'inside' | 'outside'
    this.previewObjects = [];
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.selectedObject = null;
    this.side = null;
    this.previewObjects = [];
    this.cad.setStatus('OFFSET: Seleziona oggetto da offsettare');
  }

  /**
   * Imposta distanza offset
   * @param {number} distance - Distanza in mm
   */
  setDistance(distance) {
    this.distance = Math.abs(parseFloat(distance) || 10);
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Se non ho ancora selezionato oggetto
    if (!this.selectedObject) {
      const object = this.cad.getObjectAt(point);

      if (!object) {
        this.cad.setStatus('OFFSET: Nessun oggetto trovato');
        return;
      }

      this.selectedObject = object;
      this.cad.setStatus(`OFFSET: Click su lato per offset di ${this.distance}mm`);
      return;
    }

    // Ho già oggetto, click determina il lato
    this.side = this.determineSide(this.selectedObject, point);

    // Crea offset
    const offsetObjects = this.createOffset(this.selectedObject, this.distance, this.side);

    if (offsetObjects && offsetObjects.length > 0) {
      offsetObjects.forEach(obj => this.cad.addObject(obj));
      this.cad.saveHistory();
      this.cad.render();
      this.cad.setStatus(`OFFSET: Creato offset di ${this.distance}mm`);
    } else {
      this.cad.setStatus('OFFSET: Impossibile creare offset');
    }

    // Reset per nuovo offset
    this.selectedObject = null;
    this.side = null;
    this.previewObjects = [];
  }

  /**
   * Determina su quale lato fare l'offset basandosi sul click
   * @param {Object} object - Oggetto selezionato
   * @param {Object} clickPoint - Punto clickato
   * @returns {string} 'left'|'right'|'inside'|'outside'
   */
  determineSide(object, clickPoint) {
    if (object.type === 'line') {
      // Calcola se click è a destra o sinistra della linea
      const dx = object.p2.x - object.p1.x;
      const dy = object.p2.y - object.p1.y;

      const cross = (clickPoint.x - object.p1.x) * dy - (clickPoint.y - object.p1.y) * dx;

      return cross > 0 ? 'left' : 'right';
    }

    if (object.type === 'circle' || object.type === 'arc') {
      // Calcola distanza dal centro
      const dx = clickPoint.x - object.cx;
      const dy = clickPoint.y - object.cy;
      const dist = Math.sqrt(dx * dx + dy * dy);

      return dist > object.radius ? 'outside' : 'inside';
    }

    if (object.type === 'rectangle') {
      // Determina se click è dentro o fuori
      const inside = clickPoint.x >= object.x &&
                     clickPoint.x <= object.x + object.width &&
                     clickPoint.y >= object.y &&
                     clickPoint.y <= object.y + object.height;

      return inside ? 'inside' : 'outside';
    }

    return 'right';
  }

  /**
   * Crea offset di un oggetto
   * @param {Object} object - Oggetto originale
   * @param {number} distance - Distanza offset
   * @param {string} side - Lato offset
   * @returns {Array} Array di oggetti offsettati
   */
  createOffset(object, distance, side) {
    if (object.type === 'line') {
      return [this.offsetLine(object, distance, side)];
    }

    if (object.type === 'circle') {
      return [this.offsetCircle(object, distance, side)];
    }

    if (object.type === 'arc') {
      return [this.offsetArc(object, distance, side)];
    }

    if (object.type === 'rectangle') {
      return this.offsetRectangle(object, distance, side);
    }

    if (object.type === 'polyline') {
      return this.offsetPolyline(object, distance, side);
    }

    return [];
  }

  /**
   * Offset di una linea
   * @param {Object} line - Linea originale {p1, p2}
   * @param {number} distance - Distanza
   * @param {string} side - Lato
   * @returns {Object} Linea offsettata
   */
  offsetLine(line, distance, side) {
    // Calcola vettore perpendicolare
    const dx = line.p2.x - line.p1.x;
    const dy = line.p2.y - line.p1.y;
    const len = Math.sqrt(dx * dx + dy * dy);

    // Vettore perpendicolare normalizzato
    let perpX = -dy / len;
    let perpY = dx / len;

    // Inverti se lato è right
    if (side === 'right') {
      perpX = -perpX;
      perpY = -perpY;
    }

    // Offset points
    const offsetDist = distance;

    return {
      type: 'line',
      lineType: line.lineType,
      p1: {
        x: line.p1.x + perpX * offsetDist,
        y: line.p1.y + perpY * offsetDist
      },
      p2: {
        x: line.p2.x + perpX * offsetDist,
        y: line.p2.y + perpY * offsetDist
      },
      metadata: {
        offsetFrom: line.id,
        offsetDistance: distance
      }
    };
  }

  /**
   * Offset di un cerchio
   * @param {Object} circle - Cerchio originale
   * @param {number} distance - Distanza
   * @param {string} side - 'inside' | 'outside'
   * @returns {Object} Cerchio offsettato
   */
  offsetCircle(circle, distance, side) {
    const newRadius = side === 'outside'
      ? circle.radius + distance
      : circle.radius - distance;

    // Verifica che raggio sia positivo
    if (newRadius <= 0) {
      return null;
    }

    return {
      type: 'circle',
      lineType: circle.lineType,
      cx: circle.cx,
      cy: circle.cy,
      radius: newRadius,
      metadata: {
        offsetFrom: circle.id,
        offsetDistance: distance
      }
    };
  }

  /**
   * Offset di un arco
   * @param {Object} arc - Arco originale
   * @param {number} distance - Distanza
   * @param {string} side - 'inside' | 'outside'
   * @returns {Object} Arco offsettato
   */
  offsetArc(arc, distance, side) {
    const newRadius = side === 'outside'
      ? arc.radius + distance
      : arc.radius - distance;

    if (newRadius <= 0) return null;

    return {
      type: 'arc',
      lineType: arc.lineType,
      cx: arc.cx,
      cy: arc.cy,
      radius: newRadius,
      startAngle: arc.startAngle,
      endAngle: arc.endAngle,
      metadata: {
        offsetFrom: arc.id,
        offsetDistance: distance
      }
    };
  }

  /**
   * Offset di un rettangolo
   * @param {Object} rect - Rettangolo originale
   * @param {number} distance - Distanza
   * @param {string} side - 'inside' | 'outside'
   * @returns {Array} Array di 4 linee offsettate
   */
  offsetRectangle(rect, distance, side) {
    const d = side === 'outside' ? distance : -distance;

    const newRect = {
      x: rect.x - d,
      y: rect.y - d,
      width: rect.width + 2 * d,
      height: rect.height + 2 * d
    };

    // Verifica che dimensioni siano positive
    if (newRect.width <= 0 || newRect.height <= 0) {
      return [];
    }

    // Crea 4 linee
    return [
      {
        type: 'line',
        lineType: rect.lineType,
        p1: { x: newRect.x, y: newRect.y },
        p2: { x: newRect.x + newRect.width, y: newRect.y }
      },
      {
        type: 'line',
        lineType: rect.lineType,
        p1: { x: newRect.x + newRect.width, y: newRect.y },
        p2: { x: newRect.x + newRect.width, y: newRect.y + newRect.height }
      },
      {
        type: 'line',
        lineType: rect.lineType,
        p1: { x: newRect.x + newRect.width, y: newRect.y + newRect.height },
        p2: { x: newRect.x, y: newRect.y + newRect.height }
      },
      {
        type: 'line',
        lineType: rect.lineType,
        p1: { x: newRect.x, y: newRect.y + newRect.height },
        p2: { x: newRect.x, y: newRect.y }
      }
    ];
  }

  /**
   * Offset di una polyline (catena di linee connesse)
   * @param {Object} polyline - Polyline originale
   * @param {number} distance - Distanza
   * @param {string} side - Lato
   * @returns {Array} Polyline offsettata
   */
  offsetPolyline(polyline, distance, side) {
    if (!polyline.points || polyline.points.length < 2) return [];

    const offsetPoints = [];

    // Offset ogni segmento e trova intersezioni
    for (let i = 0; i < polyline.points.length - 1; i++) {
      const p1 = polyline.points[i];
      const p2 = polyline.points[i + 1];

      const segmentLine = { p1, p2, lineType: polyline.lineType };
      const offsetSegment = this.offsetLine(segmentLine, distance, side);

      if (i === 0) {
        offsetPoints.push(offsetSegment.p1);
      }

      // Se non è ultimo segmento, trova intersezione con prossimo
      if (i < polyline.points.length - 2) {
        const p3 = polyline.points[i + 2];
        const nextSegmentLine = { p1: p2, p2: p3, lineType: polyline.lineType };
        const nextOffsetSegment = this.offsetLine(nextSegmentLine, distance, side);

        // Trova intersezione tra offsetSegment e nextOffsetSegment
        const intersection = this.lineLineIntersectionExtended(offsetSegment, nextOffsetSegment);

        if (intersection) {
          offsetPoints.push(intersection);
        } else {
          offsetPoints.push(offsetSegment.p2);
          offsetPoints.push(nextOffsetSegment.p1);
        }
      } else {
        offsetPoints.push(offsetSegment.p2);
      }
    }

    return [{
      type: 'polyline',
      lineType: polyline.lineType,
      points: offsetPoints,
      closed: polyline.closed,
      metadata: {
        offsetFrom: polyline.id,
        offsetDistance: distance
      }
    }];
  }

  /**
   * Intersezione tra due linee (anche estese)
   * @param {Object} line1 - Prima linea
   * @param {Object} line2 - Seconda linea
   * @returns {Object|null} Punto intersezione o null
   */
  lineLineIntersectionExtended(line1, line2) {
    const x1 = line1.p1.x, y1 = line1.p1.y;
    const x2 = line1.p2.x, y2 = line1.p2.y;
    const x3 = line2.p1.x, y3 = line2.p1.y;
    const x4 = line2.p2.x, y4 = line2.p2.y;

    const denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

    if (Math.abs(denom) < 1e-10) return null; // Parallele

    const t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;

    return {
      x: x1 + t * (x2 - x1),
      y: y1 + t * (y2 - y1)
    };
  }

  /**
   * Mouse move handler - mostra preview
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    // Se ho oggetto selezionato, mostra preview
    if (this.selectedObject) {
      const side = this.determineSide(this.selectedObject, point);
      this.previewObjects = this.createOffset(this.selectedObject, this.distance, side);
      this.cad.render();
    } else {
      // Highlight oggetto sotto cursore
      const object = this.cad.getObjectAt(point);
      this.cad.highlightObject = object;
      this.cad.render();
    }
  }

  /**
   * Key press handler
   * @param {String} key - Key name
   * @param {Event} event - Keyboard event
   */
  onKeyPress(key, event) {
    // D key - prompt for distance
    if (key.toLowerCase() === 'd' && !event.ctrlKey && !event.metaKey) {
      const newDistance = prompt(`Enter offset distance (mm):`, this.distance.toString());
      if (newDistance !== null) {
        const parsed = parseFloat(newDistance);
        if (!isNaN(parsed) && parsed > 0) {
          this.distance = parsed;
          this.cad.setStatus(`OFFSET: Distance set to ${this.distance}mm`);
          // Refresh preview if object selected
          if (this.selectedObject && this.previewObjects.length > 0) {
            this.cad.render();
          }
        }
      }
      return;
    }

    // ESC - cancel selection
    if (key === 'Escape') {
      this.selectedObject = null;
      this.side = null;
      this.previewObjects = [];
      this.cad.setStatus('OFFSET: Seleziona oggetto da offsettare');
      this.cad.render();
      return;
    }
  }

  /**
   * Render preview durante operazione
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview(ctx) {
    if (this.previewObjects.length === 0) return;

    ctx.save();
    ctx.globalAlpha = 0.6;
    ctx.strokeStyle = '#0e7afe';
    ctx.lineWidth = 2 / this.cad.zoom;
    ctx.setLineDash([5, 5]);

    this.previewObjects.forEach(obj => {
      this.cad.drawObject(ctx, obj);
    });

    ctx.setLineDash([]);

    // Draw distance measurement
    if (this.selectedObject && this.previewObjects.length > 0) {
      const preview = this.previewObjects[0];

      if (this.selectedObject.type === 'line' && preview.type === 'line') {
        // Draw arrow showing offset distance
        const midOrigX = (this.selectedObject.p1.x + this.selectedObject.p2.x) / 2;
        const midOrigY = (this.selectedObject.p1.y + this.selectedObject.p2.y) / 2;
        const midOffX = (preview.p1.x + preview.p2.x) / 2;
        const midOffY = (preview.p1.y + preview.p2.y) / 2;

        ctx.strokeStyle = '#ff9900';
        ctx.lineWidth = 1 / this.cad.zoom;
        ctx.beginPath();
        ctx.moveTo(midOrigX, midOrigY);
        ctx.lineTo(midOffX, midOffY);
        ctx.stroke();

        // Arrow head
        const dx = midOffX - midOrigX;
        const dy = midOffY - midOrigY;
        const angle = Math.atan2(dy, dx);
        const arrowSize = 8 / this.cad.zoom;

        ctx.beginPath();
        ctx.moveTo(midOffX, midOffY);
        ctx.lineTo(
          midOffX - arrowSize * Math.cos(angle - Math.PI / 6),
          midOffY - arrowSize * Math.sin(angle - Math.PI / 6)
        );
        ctx.moveTo(midOffX, midOffY);
        ctx.lineTo(
          midOffX - arrowSize * Math.cos(angle + Math.PI / 6),
          midOffY - arrowSize * Math.sin(angle + Math.PI / 6)
        );
        ctx.stroke();

        // Distance label
        ctx.fillStyle = '#ffffff';
        ctx.font = `${12 / this.cad.zoom}px Arial`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(`${this.distance.toFixed(2)}mm`, (midOrigX + midOffX) / 2, (midOrigY + midOffY) / 2 - 10 / this.cad.zoom);
      }
      else if ((this.selectedObject.type === 'circle' || this.selectedObject.type === 'arc') &&
               (preview.type === 'circle' || preview.type === 'arc')) {
        // Draw radial line showing offset
        const cx = this.selectedObject.cx;
        const cy = this.selectedObject.cy;
        const r1 = this.selectedObject.radius;
        const r2 = preview.radius;

        const angle = 0; // Top of circle
        const x1 = cx + r1 * Math.cos(angle);
        const y1 = cy + r1 * Math.sin(angle);
        const x2 = cx + r2 * Math.cos(angle);
        const y2 = cy + r2 * Math.sin(angle);

        ctx.strokeStyle = '#ff9900';
        ctx.lineWidth = 1 / this.cad.zoom;
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();

        // Distance label
        ctx.fillStyle = '#ffffff';
        ctx.font = `${12 / this.cad.zoom}px Arial`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(`${this.distance.toFixed(2)}mm`, cx, cy - (r1 + r2) / 2 - 10 / this.cad.zoom);
      }
    }

    ctx.restore();
  }

  /**
   * Deattiva tool
   */
  deactivate() {
    this.selectedObject = null;
    this.side = null;
    this.previewObjects = [];
    this.cad.highlightObject = null;
  }
}

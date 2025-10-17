/**
 * Arc Tool - Fusion 360 Style
 * Crea archi con 3 metodi: 3 punti, centro-punto, tangente
 *
 * @module ArcTool
 * @author Box Designer CAD Engine
 */

export class ArcTool {
  /**
   * Costruttore Arc Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'arc';
    this.cursor = 'crosshair';

    // Modalità: '3point', 'center', 'tangent'
    this.mode = '3point';

    // Punti per arco 3-point
    this.point1 = null;
    this.point2 = null;
    this.point3 = null;

    // Punti per arco center-based
    this.center = null;
    this.startPoint = null;
    this.endPoint = null;

    this.currentLineType = 'cut';
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.reset();
    this.updateStatus();
  }

  /**
   * Reset stato
   */
  reset() {
    this.point1 = null;
    this.point2 = null;
    this.point3 = null;
    this.center = null;
    this.startPoint = null;
    this.endPoint = null;
    this.previewPoint = null;
  }

  /**
   * Imposta modalità arco
   * @param {string} mode - '3point', 'center', 'tangent'
   */
  setMode(mode) {
    this.mode = mode;
    this.reset();
    this.updateStatus();
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
    if (this.mode === '3point') {
      if (!this.point1) {
        this.cad.setStatus('ARC (3-Point): Click primo punto');
      } else if (!this.point2) {
        this.cad.setStatus('ARC (3-Point): Click secondo punto');
      } else if (!this.point3) {
        this.cad.setStatus('ARC (3-Point): Click terzo punto');
      }
    } else if (this.mode === 'center') {
      if (!this.center) {
        this.cad.setStatus('ARC (Center): Click centro');
      } else if (!this.startPoint) {
        this.cad.setStatus('ARC (Center): Click punto inizio');
      } else if (!this.endPoint) {
        this.cad.setStatus('ARC (Center): Click punto fine');
      }
    }
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    if (this.mode === '3point') {
      this.onClick3Point(point);
    } else if (this.mode === 'center') {
      this.onClickCenter(point);
    }
  }

  /**
   * Click handler per modalità 3-point
   * @param {Object} point - Punto {x, y}
   */
  onClick3Point(point) {
    if (!this.point1) {
      this.point1 = point;
      this.updateStatus();
      return;
    }

    if (!this.point2) {
      this.point2 = point;
      this.updateStatus();
      return;
    }

    if (!this.point3) {
      this.point3 = point;

      // Crea arco da 3 punti
      const arc = this.createArcFrom3Points(this.point1, this.point2, this.point3);

      if (arc) {
        this.cad.addObject(arc);
        this.cad.saveHistory();
        this.cad.render();
        this.cad.setStatus(`ARC: Creato (radius ${arc.radius.toFixed(2)}mm)`);
      } else {
        this.cad.setStatus('ARC: Punti collineari, impossibile creare arco');
      }

      this.reset();
      this.updateStatus();
    }
  }

  /**
   * Click handler per modalità center
   * @param {Object} point - Punto {x, y}
   */
  onClickCenter(point) {
    if (!this.center) {
      this.center = point;
      this.updateStatus();
      return;
    }

    if (!this.startPoint) {
      this.startPoint = point;
      this.updateStatus();
      return;
    }

    if (!this.endPoint) {
      this.endPoint = point;

      // Crea arco da centro e due punti
      const arc = this.createArcFromCenter(this.center, this.startPoint, this.endPoint);

      if (arc) {
        this.cad.addObject(arc);
        this.cad.saveHistory();
        this.cad.render();
        this.cad.setStatus(`ARC: Creato (radius ${arc.radius.toFixed(2)}mm)`);
      }

      this.reset();
      this.updateStatus();
    }
  }

  /**
   * Mouse move handler - preview
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    this.previewPoint = point;
    this.cad.render();
  }

  /**
   * Crea arco da 3 punti
   * Algoritmo: Calcola centro del cerchio passante per 3 punti
   *
   * @param {Object} p1 - Primo punto {x, y}
   * @param {Object} p2 - Secondo punto {x, y}
   * @param {Object} p3 - Terzo punto {x, y}
   * @returns {Object|null} Oggetto arco o null se punti collineari
   */
  createArcFrom3Points(p1, p2, p3) {
    // Calcola centro cerchio passante per 3 punti
    const center = this.calculateCircleCenter(p1, p2, p3);

    if (!center) return null; // Punti collineari

    // Calcola raggio
    const radius = this.distance(center, p1);

    // Calcola angoli
    const angle1 = Math.atan2(p1.y - center.y, p1.x - center.x);
    const angle2 = Math.atan2(p2.y - center.y, p2.x - center.x);
    const angle3 = Math.atan2(p3.y - center.y, p3.x - center.x);

    // Determina ordine corretto angoli per arco che passa per p2
    // Usa il metodo del prodotto vettoriale per determinare la direzione
    let startAngle, endAngle, counterclockwise;

    // Calcola il prodotto vettoriale per determinare se l'arco è CCW o CW
    const cross = (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x);

    if (cross > 0) {
      // Arco in senso antiorario (CCW)
      startAngle = angle1;
      endAngle = angle3;
      counterclockwise = false;
    } else {
      // Arco in senso orario (CW)
      startAngle = angle1;
      endAngle = angle3;
      counterclockwise = true;
    }

    // Normalizza angoli per assicurarsi che endAngle > startAngle
    if (endAngle < startAngle && !counterclockwise) {
      endAngle += 2 * Math.PI;
    }

    return {
      type: 'arc',
      lineType: this.currentLineType,
      cx: center.x,
      cy: center.y,
      radius: radius,
      startAngle: startAngle,
      endAngle: endAngle,
      counterclockwise: counterclockwise
    };
  }

  /**
   * Crea arco da centro e due punti
   * @param {Object} center - Centro {x, y}
   * @param {Object} startPoint - Punto inizio {x, y}
   * @param {Object} endPoint - Punto fine {x, y}
   * @returns {Object} Oggetto arco
   */
  createArcFromCenter(center, startPoint, endPoint) {
    // Calcola raggio (media tra le distanze)
    const r1 = this.distance(center, startPoint);
    const r2 = this.distance(center, endPoint);
    const radius = (r1 + r2) / 2;

    // Calcola angoli
    const startAngle = Math.atan2(startPoint.y - center.y, startPoint.x - center.x);
    const endAngle = Math.atan2(endPoint.y - center.y, endPoint.x - center.x);

    return {
      type: 'arc',
      lineType: this.currentLineType,
      cx: center.x,
      cy: center.y,
      radius: radius,
      startAngle: startAngle,
      endAngle: endAngle
    };
  }

  /**
   * Calcola centro del cerchio passante per 3 punti
   * Formula: Intersezione delle perpendicolari alle corde
   *
   * @param {Object} p1 - Primo punto
   * @param {Object} p2 - Secondo punto
   * @param {Object} p3 - Terzo punto
   * @returns {Object|null} Centro {x, y} o null se collineari
   */
  calculateCircleCenter(p1, p2, p3) {
    const ax = p1.x, ay = p1.y;
    const bx = p2.x, by = p2.y;
    const cx = p3.x, cy = p3.y;

    const d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));

    if (Math.abs(d) < 1e-10) return null; // Punti collineari

    const ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d;
    const uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d;

    return { x: ux, y: uy };
  }

  /**
   * Verifica se angolo medio è tra start e end
   * @param {number} mid - Angolo medio
   * @param {number} start - Angolo start
   * @param {number} end - Angolo end
   * @returns {boolean}
   */
  isAngleBetween(mid, start, end) {
    // Normalizza angoli 0-2π
    const normalize = (a) => {
      while (a < 0) a += 2 * Math.PI;
      while (a >= 2 * Math.PI) a -= 2 * Math.PI;
      return a;
    };

    mid = normalize(mid);
    start = normalize(start);
    end = normalize(end);

    if (start <= end) {
      return mid >= start && mid <= end;
    } else {
      return mid >= start || mid <= end;
    }
  }

  /**
   * Render preview
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview(ctx) {
    if (!ctx) return;

    ctx.save();

    if (this.mode === '3point') {
      this.renderPreview3Point(ctx);
    } else if (this.mode === 'center') {
      this.renderPreviewCenter(ctx);
    }

    ctx.restore();
  }

  /**
   * Render preview 3-point
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview3Point(ctx) {
    // Primo punto
    if (this.point1) {
      ctx.fillStyle = '#ff0000';
      ctx.beginPath();
      ctx.arc(this.point1.x, this.point1.y, 3, 0, Math.PI * 2);
      ctx.fill();
    }

    // Linea al secondo punto
    if (this.point1 && this.previewPoint) {
      ctx.strokeStyle = '#ff0000';
      ctx.lineWidth = 1;
      ctx.setLineDash([5, 5]);

      ctx.beginPath();
      ctx.moveTo(this.point1.x, this.point1.y);
      ctx.lineTo(this.previewPoint.x, this.previewPoint.y);
      ctx.stroke();

      ctx.setLineDash([]);
    }

    // Secondo punto
    if (this.point2) {
      ctx.fillStyle = '#0000ff';
      ctx.beginPath();
      ctx.arc(this.point2.x, this.point2.y, 3, 0, Math.PI * 2);
      ctx.fill();
    }

    // Preview arco con terzo punto
    if (this.point1 && this.point2 && this.previewPoint) {
      const arc = this.createArcFrom3Points(this.point1, this.point2, this.previewPoint);

      if (arc) {
        ctx.strokeStyle = '#00ff00';
        ctx.lineWidth = 2 / this.cad.zoom;

        ctx.beginPath();
        ctx.arc(arc.cx, arc.cy, arc.radius, arc.startAngle, arc.endAngle, arc.counterclockwise);
        ctx.stroke();

        // Centro preview
        ctx.fillStyle = '#00ff00';
        ctx.beginPath();
        ctx.arc(arc.cx, arc.cy, 3 / this.cad.zoom, 0, Math.PI * 2);
        ctx.fill();

        // Linea dal centro al punto medio dell'arco
        const midAngle = (arc.startAngle + arc.endAngle) / 2;
        const midX = arc.cx + Math.cos(midAngle) * arc.radius;
        const midY = arc.cy + Math.sin(midAngle) * arc.radius;

        ctx.strokeStyle = '#00ff00';
        ctx.lineWidth = 1 / this.cad.zoom;
        ctx.setLineDash([3, 3]);
        ctx.beginPath();
        ctx.moveTo(arc.cx, arc.cy);
        ctx.lineTo(midX, midY);
        ctx.stroke();
        ctx.setLineDash([]);

        // Misurazioni
        ctx.fillStyle = '#ffffff';
        ctx.font = `${12 / this.cad.zoom}px Arial`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';

        // Raggio
        const textX = arc.cx + Math.cos(midAngle) * arc.radius * 0.6;
        const textY = arc.cy + Math.sin(midAngle) * arc.radius * 0.6;
        ctx.fillText(`R: ${arc.radius.toFixed(2)}mm`, textX, textY);

        // Angolo dell'arco
        let arcAngle = Math.abs(arc.endAngle - arc.startAngle);
        if (arc.counterclockwise && arcAngle < Math.PI) {
          arcAngle = 2 * Math.PI - arcAngle;
        }
        const arcDegrees = (arcAngle * 180 / Math.PI).toFixed(1);

        ctx.fillText(`${arcDegrees}°`, arc.cx, arc.cy - 15 / this.cad.zoom);

        // Lunghezza arco
        const arcLength = arc.radius * arcAngle;
        ctx.fillText(`L: ${arcLength.toFixed(2)}mm`, arc.cx, arc.cy + 15 / this.cad.zoom);
      }
    }
  }

  /**
   * Render preview center-based
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreviewCenter(ctx) {
    // Centro
    if (this.center) {
      ctx.fillStyle = '#ff0000';
      ctx.beginPath();
      ctx.arc(this.center.x, this.center.y, 3, 0, Math.PI * 2);
      ctx.fill();

      // Cerchio raggio preview
      if (this.previewPoint) {
        const radius = this.distance(this.center, this.previewPoint);

        ctx.strokeStyle = '#cccccc';
        ctx.lineWidth = 0.5;
        ctx.setLineDash([2, 2]);

        ctx.beginPath();
        ctx.arc(this.center.x, this.center.y, radius, 0, Math.PI * 2);
        ctx.stroke();

        ctx.setLineDash([]);
      }
    }

    // Punto inizio
    if (this.startPoint) {
      ctx.fillStyle = '#0000ff';
      ctx.beginPath();
      ctx.arc(this.startPoint.x, this.startPoint.y, 3, 0, Math.PI * 2);
      ctx.fill();

      // Linea al centro
      ctx.strokeStyle = '#0000ff';
      ctx.lineWidth = 1;
      ctx.setLineDash([5, 5]);

      ctx.beginPath();
      ctx.moveTo(this.center.x, this.center.y);
      ctx.lineTo(this.startPoint.x, this.startPoint.y);
      ctx.stroke();

      ctx.setLineDash([]);
    }

    // Preview arco con end point
    if (this.center && this.startPoint && this.previewPoint) {
      const arc = this.createArcFromCenter(this.center, this.startPoint, this.previewPoint);

      ctx.strokeStyle = '#00ff00';
      ctx.lineWidth = 2;

      ctx.beginPath();
      ctx.arc(arc.cx, arc.cy, arc.radius, arc.startAngle, arc.endAngle);
      ctx.stroke();
    }
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
   * Deattiva tool
   */
  deactivate() {
    this.reset();
  }
}

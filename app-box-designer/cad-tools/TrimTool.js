/**
 * Trim Tool - Fusion 360 Style
 * Taglia linee, archi e curve alle intersezioni con altri oggetti
 *
 * @module TrimTool
 * @author Box Designer CAD Engine
 */

export class TrimTool {
  /**
   * Costruttore Trim Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'trim';
    this.cursor = 'crosshair';
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.cad.setStatus('TRIM: Click sulla parte di oggetto da rimuovere');
  }

  /**
   * Click handler - trimma l'oggetto clickato
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Trova oggetto sotto il cursore
    const object = this.cad.getObjectAt(point);

    if (!object) {
      this.cad.setStatus('TRIM: Nessun oggetto trovato. Click su oggetto da trimmare.');
      return;
    }

    // Trova tutte le intersezioni di questo oggetto con altri oggetti
    const intersections = this.findAllIntersections(object);

    if (intersections.length === 0) {
      this.cad.setStatus('TRIM: Nessuna intersezione trovata');
      return;
    }

    // Determina quale segmento trimmare basandosi sul punto clickato
    const trimmedObjects = this.trimObjectAtPoint(object, point, intersections);

    if (trimmedObjects) {
      // Rimuovi oggetto originale
      this.cad.removeObject(object);

      // Aggiungi segmenti trimmati
      trimmedObjects.forEach(obj => this.cad.addObject(obj));

      this.cad.saveHistory();
      this.cad.render();
      this.cad.setStatus(`TRIM: Oggetto trimmato (${trimmedObjects.length} segmenti)`);
    } else {
      this.cad.setStatus('TRIM: Impossibile trimmare');
    }
  }

  /**
   * Trova tutte le intersezioni tra un oggetto e tutti gli altri oggetti
   * @param {Object} object - Oggetto da verificare
   * @returns {Array} Array di punti di intersezione con metadati
   */
  findAllIntersections(object) {
    const intersections = [];

    // Itera su tutti gli altri oggetti
    this.cad.objects.forEach(other => {
      if (other === object) return;

      const points = this.findIntersectionPoints(object, other);
      points.forEach(p => {
        intersections.push({
          point: p,
          object: other,
          t: this.getParameterAtPoint(object, p) // Parametro t lungo la curva
        });
      });
    });

    // Ordina per parametro t
    intersections.sort((a, b) => a.t - b.t);

    return intersections;
  }

  /**
   * Trova punti di intersezione tra due oggetti
   * @param {Object} obj1 - Primo oggetto
   * @param {Object} obj2 - Secondo oggetto
   * @returns {Array} Array di punti {x, y}
   */
  findIntersectionPoints(obj1, obj2) {
    // Line-Line
    if (obj1.type === 'line' && obj2.type === 'line') {
      return this.lineLineIntersection(obj1, obj2);
    }

    // Line-Circle
    if (obj1.type === 'line' && obj2.type === 'circle') {
      return this.lineCircleIntersection(obj1, obj2);
    }

    // Circle-Circle
    if (obj1.type === 'circle' && obj2.type === 'circle') {
      return this.circleCircleIntersection(obj1, obj2);
    }

    // Line-Arc (arc è circle con start/end angle)
    if (obj1.type === 'line' && obj2.type === 'arc') {
      return this.lineArcIntersection(obj1, obj2);
    }

    return [];
  }

  /**
   * Intersezione Line-Line
   * @param {Object} line1 - Prima linea {p1, p2}
   * @param {Object} line2 - Seconda linea {p1, p2}
   * @returns {Array} Array con 0 o 1 punto
   */
  lineLineIntersection(line1, line2) {
    const x1 = line1.p1.x, y1 = line1.p1.y;
    const x2 = line1.p2.x, y2 = line1.p2.y;
    const x3 = line2.p1.x, y3 = line2.p1.y;
    const x4 = line2.p2.x, y4 = line2.p2.y;

    const denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

    if (Math.abs(denom) < 1e-10) return []; // Parallele

    const t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;
    const u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom;

    // Verifica che intersezione sia sui segmenti (non estesi)
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return [{
        x: x1 + t * (x2 - x1),
        y: y1 + t * (y2 - y1)
      }];
    }

    return [];
  }

  /**
   * Intersezione Line-Circle
   * @param {Object} line - Linea {p1, p2}
   * @param {Object} circle - Cerchio {cx, cy, radius}
   * @returns {Array} Array con 0, 1 o 2 punti
   */
  lineCircleIntersection(line, circle) {
    const x1 = line.p1.x, y1 = line.p1.y;
    const x2 = line.p2.x, y2 = line.p2.y;
    const cx = circle.cx, cy = circle.cy, r = circle.radius;

    const dx = x2 - x1;
    const dy = y2 - y1;

    const fx = x1 - cx;
    const fy = y1 - cy;

    const a = dx * dx + dy * dy;
    const b = 2 * (fx * dx + fy * dy);
    const c = (fx * fx + fy * fy) - r * r;

    let discriminant = b * b - 4 * a * c;

    if (discriminant < 0) return []; // Nessuna intersezione

    discriminant = Math.sqrt(discriminant);

    const t1 = (-b - discriminant) / (2 * a);
    const t2 = (-b + discriminant) / (2 * a);

    const points = [];

    if (t1 >= 0 && t1 <= 1) {
      points.push({
        x: x1 + t1 * dx,
        y: y1 + t1 * dy
      });
    }

    if (t2 >= 0 && t2 <= 1) {
      points.push({
        x: x1 + t2 * dx,
        y: y1 + t2 * dy
      });
    }

    return points;
  }

  /**
   * Intersezione Circle-Circle
   * @param {Object} c1 - Primo cerchio {cx, cy, radius}
   * @param {Object} c2 - Secondo cerchio {cx, cy, radius}
   * @returns {Array} Array con 0, 1 o 2 punti
   */
  circleCircleIntersection(c1, c2) {
    const dx = c2.cx - c1.cx;
    const dy = c2.cy - c1.cy;
    const d = Math.sqrt(dx * dx + dy * dy);

    // Cerchi non si intersecano
    if (d > c1.radius + c2.radius || d < Math.abs(c1.radius - c2.radius)) {
      return [];
    }

    // Cerchi coincidenti
    if (d < 1e-10 && Math.abs(c1.radius - c2.radius) < 1e-10) {
      return []; // Infiniti punti
    }

    const a = (c1.radius * c1.radius - c2.radius * c2.radius + d * d) / (2 * d);
    const h = Math.sqrt(c1.radius * c1.radius - a * a);

    const px = c1.cx + a * dx / d;
    const py = c1.cy + a * dy / d;

    const points = [];

    points.push({
      x: px + h * dy / d,
      y: py - h * dx / d
    });

    if (h > 1e-10) { // Due punti distinti
      points.push({
        x: px - h * dy / d,
        y: py + h * dx / d
      });
    }

    return points;
  }

  /**
   * Intersezione Line-Arc
   * @param {Object} line - Linea
   * @param {Object} arc - Arco {cx, cy, radius, startAngle, endAngle}
   * @returns {Array} Punti sull'arco
   */
  lineArcIntersection(line, arc) {
    // Usa line-circle, poi filtra per angolo
    const circle = { cx: arc.cx, cy: arc.cy, radius: arc.radius };
    const points = this.lineCircleIntersection(line, circle);

    return points.filter(p => {
      const angle = Math.atan2(p.y - arc.cy, p.x - arc.cx);
      return this.isAngleInRange(angle, arc.startAngle, arc.endAngle);
    });
  }

  /**
   * Verifica se angolo è nel range dell'arco
   * @param {number} angle - Angolo da verificare
   * @param {number} start - Angolo start
   * @param {number} end - Angolo end
   * @returns {boolean}
   */
  isAngleInRange(angle, start, end) {
    // Normalizza angoli tra 0 e 2π
    const normalize = (a) => {
      while (a < 0) a += 2 * Math.PI;
      while (a > 2 * Math.PI) a -= 2 * Math.PI;
      return a;
    };

    angle = normalize(angle);
    start = normalize(start);
    end = normalize(end);

    if (start <= end) {
      return angle >= start && angle <= end;
    } else {
      return angle >= start || angle <= end;
    }
  }

  /**
   * Ottiene parametro t (0-1) lungo l'oggetto per un punto
   * @param {Object} object - Oggetto
   * @param {Object} point - Punto
   * @returns {number} Parametro t
   */
  getParameterAtPoint(object, point) {
    if (object.type === 'line') {
      const dx = object.p2.x - object.p1.x;
      const dy = object.p2.y - object.p1.y;
      const len = Math.sqrt(dx * dx + dy * dy);

      const dpx = point.x - object.p1.x;
      const dpy = point.y - object.p1.y;

      return Math.sqrt(dpx * dpx + dpy * dpy) / len;
    }

    if (object.type === 'circle') {
      const angle = Math.atan2(point.y - object.cy, point.x - object.cx);
      return (angle + Math.PI) / (2 * Math.PI); // Normalizza 0-1
    }

    return 0;
  }

  /**
   * Trimma oggetto al punto clickato, usando intersezioni
   * @param {Object} object - Oggetto da trimmare
   * @param {Object} clickPoint - Punto clickato
   * @param {Array} intersections - Intersezioni ordinate
   * @returns {Array|null} Nuovi oggetti o null
   */
  trimObjectAtPoint(object, clickPoint, intersections) {
    const clickT = this.getParameterAtPoint(object, clickPoint);

    // Trova segmento che contiene clickPoint
    let startT = 0;
    let endT = 1;

    for (let i = 0; i < intersections.length; i++) {
      if (intersections[i].t < clickT) {
        startT = intersections[i].t;
      } else {
        endT = intersections[i].t;
        break;
      }
    }

    // Crea nuovi oggetti per i segmenti rimanenti
    const segments = [];

    if (object.type === 'line') {
      // Segmento prima del click
      if (startT > 0) {
        segments.push({
          type: 'line',
          lineType: object.lineType,
          p1: object.p1,
          p2: this.interpolateLinePoint(object, startT)
        });
      }

      // Segmento dopo il click
      if (endT < 1) {
        segments.push({
          type: 'line',
          lineType: object.lineType,
          p1: this.interpolateLinePoint(object, endT),
          p2: object.p2
        });
      }
    }

    return segments.length > 0 ? segments : null;
  }

  /**
   * Interpola punto su linea dato parametro t
   * @param {Object} line - Linea
   * @param {number} t - Parametro 0-1
   * @returns {Object} Punto {x, y}
   */
  interpolateLinePoint(line, t) {
    return {
      x: line.p1.x + t * (line.p2.x - line.p1.x),
      y: line.p1.y + t * (line.p2.y - line.p1.y)
    };
  }

  /**
   * Mouse move handler
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    this.previewPoint = point;
    // Highlight oggetto sotto cursore
    const object = this.cad.getObjectAt(point);
    this.cad.highlightObject = object;
    this.cad.render();
  }

  /**
   * Render preview - mostra segmento che verrà rimosso
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  renderPreview(ctx) {
    if (!this.previewPoint) return;

    const object = this.cad.getObjectAt(this.previewPoint);
    if (!object) return;

    // Trova intersezioni
    const intersections = this.findAllIntersections(object);
    if (intersections.length === 0) return;

    const clickT = this.getParameterAtPoint(object, this.previewPoint);

    // Trova segmento che contiene il punto
    let startT = 0;
    let endT = 1;

    for (let i = 0; i < intersections.length; i++) {
      if (intersections[i].t < clickT) {
        startT = intersections[i].t;
      } else {
        endT = intersections[i].t;
        break;
      }
    }

    // Disegna il segmento che verrà rimosso in rosso
    ctx.save();
    ctx.strokeStyle = '#ff0000';
    ctx.lineWidth = 3 / this.cad.zoom;
    ctx.globalAlpha = 0.7;

    if (object.type === 'line') {
      const p1 = this.interpolateLinePoint(object, startT);
      const p2 = this.interpolateLinePoint(object, endT);

      ctx.beginPath();
      ctx.moveTo(p1.x, p1.y);
      ctx.lineTo(p2.x, p2.y);
      ctx.stroke();
    }

    // Disegna X sui punti di intersezione
    ctx.strokeStyle = '#00ff00';
    ctx.lineWidth = 2 / this.cad.zoom;

    for (const intersection of intersections) {
      const p = intersection.point;
      const size = 5 / this.cad.zoom;

      ctx.beginPath();
      ctx.moveTo(p.x - size, p.y - size);
      ctx.lineTo(p.x + size, p.y + size);
      ctx.moveTo(p.x - size, p.y + size);
      ctx.lineTo(p.x + size, p.y - size);
      ctx.stroke();
    }

    ctx.restore();
  }

  /**
   * Deattiva tool
   */
  deactivate() {
    this.cad.highlightObject = null;
    this.previewPoint = null;
  }
}

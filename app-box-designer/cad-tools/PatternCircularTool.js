/**
 * Pattern Circular Tool - Fusion 360 Style
 * Crea array circolari di oggetti attorno a un centro
 *
 * @module PatternCircularTool
 * @author Box Designer CAD Engine
 */

export class PatternCircularTool {
  /**
   * Costruttore Pattern Circular Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'pattern_circular';
    this.cursor = 'crosshair';

    // Oggetti selezionati per pattern
    this.selectedObjects = [];

    // Centro rotazione
    this.center = null;

    // Parametri pattern
    this.count = 6; // Numero copie
    this.angle = 360; // Angolo totale in gradi (360 = cerchio completo)
    this.radius = 100; // Raggio opzionale per spostamento radiale

    // Preview
    this.previewObjects = [];
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.selectedObjects = [];
    this.center = null;
    this.previewObjects = [];
    this.cad.setStatus('PATTERN CIRCULAR: Seleziona oggetti (Enter per confermare)');
  }

  /**
   * Imposta parametri pattern
   * @param {number} count - Numero copie
   * @param {number} angle - Angolo totale in gradi
   */
  setPatternParams(count, angle) {
    this.count = Math.max(2, Math.floor(count));
    this.angle = angle;
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Fase 1: Selezione oggetti
    if (!this.center) {
      const object = this.cad.getObjectAt(point);

      if (object && !this.selectedObjects.includes(object)) {
        this.selectedObjects.push(object);
        this.cad.setStatus(`PATTERN: ${this.selectedObjects.length} oggetti selezionati (Enter per confermare)`);
        this.cad.render();
      }
      return;
    }

    // Fase 2: Conferma centro (esegui pattern)
    if (this.center && this.selectedObjects.length > 0) {
      this.executePattern();
    }
  }

  /**
   * Handler tasto Enter - conferma selezione
   */
  onKeyPress(key) {
    if (key === 'Enter' && this.selectedObjects.length > 0 && !this.center) {
      this.cad.setStatus('PATTERN CIRCULAR: Click centro di rotazione');
      // Prossimo click definirà centro
    }
  }

  /**
   * Mouse move handler - preview
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    // Se abbiamo già confermato oggetti ma non il centro, mostra preview
    if (this.selectedObjects.length > 0 && !this.center) {
      // Usa punto mouse come centro temporaneo
      this.generatePatternPreview(point);
      this.cad.render();
    }
  }

  /**
   * Esegue il pattern circolare
   */
  executePattern() {
    if (this.selectedObjects.length === 0 || !this.center) return;

    const createdObjects = [];

    const angleStep = (this.angle * Math.PI / 180) / this.count;

    // Calcola centro degli oggetti selezionati
    const objectsCenter = this.getObjectsCenter(this.selectedObjects);

    // Crea copie ruotate
    for (let i = 1; i < this.count; i++) {
      const rotationAngle = angleStep * i;

      for (const obj of this.selectedObjects) {
        const rotated = this.rotateObject(obj, this.center, rotationAngle, objectsCenter);
        if (rotated) {
          this.cad.addObject(rotated);
          createdObjects.push(rotated);
        }
      }
    }

    this.cad.saveHistory();
    this.cad.render();

    this.cad.setStatus(`PATTERN CIRCULAR: Creati ${createdObjects.length} oggetti (${this.count} copie, ${this.angle}°)`);

    // Reset
    this.selectedObjects = [];
    this.center = null;
    this.previewObjects = [];
  }

  /**
   * Genera preview pattern
   * @param {Object} center - Centro rotazione {x, y}
   */
  generatePatternPreview(center) {
    this.previewObjects = [];

    const angleStep = (this.angle * Math.PI / 180) / this.count;
    const objectsCenter = this.getObjectsCenter(this.selectedObjects);

    for (let i = 1; i < this.count; i++) {
      const rotationAngle = angleStep * i;

      for (const obj of this.selectedObjects) {
        const rotated = this.rotateObject(obj, center, rotationAngle, objectsCenter);
        if (rotated) {
          this.previewObjects.push(rotated);
        }
      }
    }
  }

  /**
   * Ruota un oggetto attorno a un centro
   * @param {Object} object - Oggetto da ruotare
   * @param {Object} center - Centro rotazione {x, y}
   * @param {number} angle - Angolo in radianti
   * @param {Object} objectCenter - Centro dell'oggetto (per ruotare attorno a sé stesso)
   * @returns {Object} Oggetto ruotato
   */
  rotateObject(object, center, angle, objectCenter) {
    const cos = Math.cos(angle);
    const sin = Math.sin(angle);

    if (object.type === 'line') {
      return {
        ...object,
        p1: this.rotatePoint(object.p1, center, cos, sin),
        p2: this.rotatePoint(object.p2, center, cos, sin)
      };
    }

    if (object.type === 'circle') {
      const newCenter = this.rotatePoint({ x: object.cx, y: object.cy }, center, cos, sin);
      return {
        ...object,
        cx: newCenter.x,
        cy: newCenter.y
      };
    }

    if (object.type === 'arc') {
      const newCenter = this.rotatePoint({ x: object.cx, y: object.cy }, center, cos, sin);
      return {
        ...object,
        cx: newCenter.x,
        cy: newCenter.y,
        startAngle: object.startAngle + angle,
        endAngle: object.endAngle + angle
      };
    }

    if (object.type === 'rectangle') {
      // Converti in polyline per rotazione
      const points = [
        { x: object.x, y: object.y },
        { x: object.x + object.width, y: object.y },
        { x: object.x + object.width, y: object.y + object.height },
        { x: object.x, y: object.y + object.height }
      ];

      const rotatedPoints = points.map(p => this.rotatePoint(p, center, cos, sin));

      return {
        type: 'polyline',
        lineType: object.lineType,
        points: rotatedPoints,
        closed: true
      };
    }

    if (object.type === 'polyline') {
      return {
        ...object,
        points: object.points.map(p => this.rotatePoint(p, center, cos, sin))
      };
    }

    if (object.type === 'dimension') {
      return {
        ...object,
        p1: object.p1 ? this.rotatePoint(object.p1, center, cos, sin) : null,
        p2: object.p2 ? this.rotatePoint(object.p2, center, cos, sin) : null,
        offset: object.offset ? this.rotatePoint(object.offset, center, cos, sin) : null,
        vertex: object.vertex ? this.rotatePoint(object.vertex, center, cos, sin) : null,
        ray1Point: object.ray1Point ? this.rotatePoint(object.ray1Point, center, cos, sin) : null,
        ray2Point: object.ray2Point ? this.rotatePoint(object.ray2Point, center, cos, sin) : null
      };
    }

    return null;
  }

  /**
   * Ruota un punto attorno a un centro
   * Formula: p' = center + R(angle) * (p - center)
   *
   * @param {Object} point - Punto {x, y}
   * @param {Object} center - Centro rotazione {x, y}
   * @param {number} cos - Coseno angolo
   * @param {number} sin - Seno angolo
   * @returns {Object} Punto ruotato {x, y}
   */
  rotatePoint(point, center, cos, sin) {
    const dx = point.x - center.x;
    const dy = point.y - center.y;

    return {
      x: center.x + dx * cos - dy * sin,
      y: center.y + dx * sin + dy * cos
    };
  }

  /**
   * Calcola centro geometrico di oggetti
   * @param {Array} objects - Array di oggetti
   * @returns {Object} Centro {x, y}
   */
  getObjectsCenter(objects) {
    if (objects.length === 0) return { x: 0, y: 0 };

    let sumX = 0, sumY = 0, count = 0;

    for (const obj of objects) {
      const center = this.getObjectCenter(obj);
      if (center) {
        sumX += center.x;
        sumY += center.y;
        count++;
      }
    }

    return {
      x: sumX / count,
      y: sumY / count
    };
  }

  /**
   * Ottiene centro di un oggetto
   * @param {Object} object - Oggetto
   * @returns {Object|null} Centro {x, y}
   */
  getObjectCenter(object) {
    if (object.type === 'line') {
      return {
        x: (object.p1.x + object.p2.x) / 2,
        y: (object.p1.y + object.p2.y) / 2
      };
    }

    if (object.type === 'circle' || object.type === 'arc') {
      return { x: object.cx, y: object.cy };
    }

    if (object.type === 'rectangle') {
      return {
        x: object.x + object.width / 2,
        y: object.y + object.height / 2
      };
    }

    if (object.type === 'polyline' && object.points.length > 0) {
      const sumX = object.points.reduce((sum, p) => sum + p.x, 0);
      const sumY = object.points.reduce((sum, p) => sum + p.y, 0);
      return {
        x: sumX / object.points.length,
        y: sumY / object.points.length
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

    // Cerchio guida e raggi
    if (this.selectedObjects.length > 0 && this.previewObjects.length > 0) {
      const objectsCenter = this.getObjectsCenter(this.selectedObjects);

      // Assumiamo che il centro preview sia stato usato per generare previewObjects
      // Per ora usiamo l'ultimo centro calcolato

      ctx.strokeStyle = '#0000ff';
      ctx.lineWidth = 0.5;
      ctx.setLineDash([2, 2]);

      // Cerchio guida (raggio dalla distanza centro pattern al centro oggetti)
      const angleStep = (this.angle * Math.PI / 180) / this.count;

      for (let i = 0; i < this.count; i++) {
        const angle = angleStep * i;
        const endX = objectsCenter.x + Math.cos(angle) * 50;
        const endY = objectsCenter.y + Math.sin(angle) * 50;

        ctx.beginPath();
        ctx.moveTo(objectsCenter.x, objectsCenter.y);
        ctx.lineTo(endX, endY);
        ctx.stroke();
      }

      // Punto centro
      ctx.fillStyle = '#0000ff';
      ctx.beginPath();
      ctx.arc(objectsCenter.x, objectsCenter.y, 3, 0, Math.PI * 2);
      ctx.fill();

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
   * Deattiva tool
   */
  deactivate() {
    this.selectedObjects = [];
    this.center = null;
    this.previewObjects = [];
  }
}

/**
 * Move/Copy Tool - Fusion 360 Style
 * Sposta o copia oggetti con distanza e angolo specificati
 *
 * @module MoveCopyTool
 * @author Box Designer CAD Engine
 */

export class MoveCopyTool {
  /**
   * Costruttore Move/Copy Tool
   * @param {Object} cadEngine - Riferimento al CAD engine principale
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'move_copy';
    this.cursor = 'crosshair';

    // Modalità: 'move' o 'copy'
    this.mode = 'move';

    // Oggetti selezionati
    this.selectedObjects = [];

    // Punti per definire spostamento
    this.basePoint = null;
    this.targetPoint = null;

    // Preview
    this.previewObjects = [];
  }

  /**
   * Attiva il tool
   */
  activate() {
    this.selectedObjects = [];
    this.basePoint = null;
    this.targetPoint = null;
    this.previewObjects = [];
    this.cad.setStatus(`${this.mode.toUpperCase()}: Seleziona oggetti (Enter per confermare)`);
  }

  /**
   * Imposta modalità
   * @param {string} mode - 'move' o 'copy'
   */
  setMode(mode) {
    this.mode = mode;
    this.cad.setStatus(`${mode.toUpperCase()}: Seleziona oggetti`);
  }

  /**
   * Click handler
   * @param {Object} point - Punto world coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Fase 1: Selezione oggetti
    if (this.selectedObjects.length === 0 || (!this.basePoint && this.selectedObjects.length > 0)) {
      // Se non abbiamo ancora confermato la selezione
      if (!this.basePoint) {
        const object = this.cad.getObjectAt(point);

        if (object && !this.selectedObjects.includes(object)) {
          this.selectedObjects.push(object);
          this.cad.setStatus(`${this.mode.toUpperCase()}: ${this.selectedObjects.length} oggetti selezionati (Enter per confermare)`);
          this.cad.render();
        }
        return;
      }
    }

    // Fase 2: Punto base per spostamento
    if (!this.basePoint) {
      this.basePoint = point;
      this.cad.setStatus(`${this.mode.toUpperCase()}: Click punto di destinazione`);
      return;
    }

    // Fase 3: Punto target - esegui move/copy
    if (!this.targetPoint) {
      this.targetPoint = point;
      this.executeMoveCopy();
    }
  }

  /**
   * Handler tasto Enter - conferma selezione
   */
  onKeyPress(key) {
    if (key === 'Enter' && this.selectedObjects.length > 0 && !this.basePoint) {
      this.cad.setStatus(`${this.mode.toUpperCase()}: Click punto base`);
      // Forza a passare alla fase successiva
      this.basePoint = null; // Verrà settato al prossimo click
    }
  }

  /**
   * Mouse move handler - preview
   * @param {Object} point - Punto world coordinates
   */
  onMouseMove(point) {
    if (this.basePoint && !this.targetPoint && this.selectedObjects.length > 0) {
      // Preview spostamento
      const dx = point.x - this.basePoint.x;
      const dy = point.y - this.basePoint.y;

      this.previewObjects = [];

      for (const obj of this.selectedObjects) {
        const moved = this.translateObject(obj, dx, dy);
        if (moved) {
          this.previewObjects.push(moved);
        }
      }

      this.cad.render();
    }
  }

  /**
   * Esegue move o copy
   */
  executeMoveCopy() {
    if (!this.basePoint || !this.targetPoint || this.selectedObjects.length === 0) return;

    const dx = this.targetPoint.x - this.basePoint.x;
    const dy = this.targetPoint.y - this.basePoint.y;

    const distance = Math.sqrt(dx * dx + dy * dy);
    const angle = Math.atan2(dy, dx) * 180 / Math.PI;

    if (this.mode === 'move') {
      // Sposta oggetti
      for (const obj of this.selectedObjects) {
        const moved = this.translateObject(obj, dx, dy);
        if (moved) {
          // Aggiorna oggetto esistente
          Object.assign(obj, moved);
        }
      }

      this.cad.saveHistory();
      this.cad.render();
      this.cad.setStatus(`MOVE: Spostati ${this.selectedObjects.length} oggetti (${distance.toFixed(2)}mm, ${angle.toFixed(1)}°)`);
    } else if (this.mode === 'copy') {
      // Copia oggetti
      const copiedObjects = [];

      for (const obj of this.selectedObjects) {
        const copied = this.translateObject(obj, dx, dy);
        if (copied) {
          this.cad.addObject(copied);
          copiedObjects.push(copied);
        }
      }

      this.cad.saveHistory();
      this.cad.render();
      this.cad.setStatus(`COPY: Copiati ${copiedObjects.length} oggetti (${distance.toFixed(2)}mm, ${angle.toFixed(1)}°)`);
    }

    // Reset
    this.selectedObjects = [];
    this.basePoint = null;
    this.targetPoint = null;
    this.previewObjects = [];
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

    // Preview oggetti spostati/copiati
    if (this.previewObjects.length > 0) {
      ctx.globalAlpha = 0.5;
      ctx.strokeStyle = '#00ff00';
      ctx.lineWidth = 1;

      for (const obj of this.previewObjects) {
        this.cad.drawObject(ctx, obj);
      }

      ctx.globalAlpha = 1;
    }

    // Linea da basePoint a mouse
    if (this.basePoint && this.previewObjects.length > 0) {
      const lastPreview = this.previewObjects[this.previewObjects.length - 1];
      let previewCenter = this.getObjectCenter(lastPreview);

      if (previewCenter) {
        ctx.strokeStyle = '#0000ff';
        ctx.lineWidth = 1;
        ctx.setLineDash([5, 5]);

        ctx.beginPath();
        ctx.moveTo(this.basePoint.x, this.basePoint.y);
        ctx.lineTo(previewCenter.x, previewCenter.y);
        ctx.stroke();

        ctx.setLineDash([]);

        // Mostra distanza e angolo
        const dx = previewCenter.x - this.basePoint.x;
        const dy = previewCenter.y - this.basePoint.y;
        const distance = Math.sqrt(dx * dx + dy * dy);
        const angle = Math.atan2(dy, dx) * 180 / Math.PI;

        const midX = (this.basePoint.x + previewCenter.x) / 2;
        const midY = (this.basePoint.y + previewCenter.y) / 2;

        ctx.fillStyle = '#000';
        ctx.font = '3px Arial';
        ctx.fillText(`${distance.toFixed(2)}mm, ${angle.toFixed(1)}°`, midX, midY - 5);
      }
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
   * Deattiva tool
   */
  deactivate() {
    this.selectedObjects = [];
    this.basePoint = null;
    this.targetPoint = null;
    this.previewObjects = [];
  }
}

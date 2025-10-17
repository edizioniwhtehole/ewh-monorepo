/**
 * Mirror Tool - Professional CAD Mirroring
 * Reflection/symmetry operations with preview
 * Week 4 Day 17
 *
 * Features:
 * - Horizontal/Vertical/Custom axis mirroring
 * - Real-time preview with ghost objects
 * - Keep original option
 * - Works with all object types
 *
 * @module MirrorTool
 * @author Box Designer CAD Engine
 */

export class MirrorTool {
  /**
   * Constructor
   * @param {Object} cadEngine - Reference to CAD engine
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'mirror';
    this.cursor = 'crosshair';

    // Mirror modes: 'horizontal', 'vertical', 'custom'
    this.mode = 'horizontal';

    // Selection state
    this.selectedObjects = [];
    this.mirrorAxis = null; // { p1: {x, y}, p2: {x, y} }
    this.axisP1 = null;
    this.axisP2 = null;
    this.previewObjects = [];
    this.keepOriginal = true; // Keep originals or replace

    // Hover state for axis definition
    this.hoverPoint = null;
  }

  /**
   * Activate tool
   */
  activate() {
    this.selectedObjects = [];
    this.mirrorAxis = null;
    this.axisP1 = null;
    this.axisP2 = null;
    this.previewObjects = [];
    this.hoverPoint = null;
    this.updateStatusMessage();
  }

  /**
   * Update status message based on current state
   */
  updateStatusMessage() {
    let msg = 'MIRROR: ';

    if (this.selectedObjects.length === 0) {
      msg += `Select objects to mirror | Mode: ${this.mode.toUpperCase()} (H/V/C) | Keep: ${this.keepOriginal ? 'YES' : 'NO'} (K)`;
    } else if (!this.axisP1 && this.mode !== 'custom') {
      msg += `${this.selectedObjects.length} selected | Press ENTER to mirror ${this.mode} | ESC to clear`;
    } else if (!this.axisP1 && this.mode === 'custom') {
      msg += `${this.selectedObjects.length} selected | Click first point of mirror axis`;
    } else if (this.axisP1 && !this.axisP2) {
      msg += 'Click second point of mirror axis | ESC to cancel';
    }

    this.cad.setStatus(msg);
  }

  /**
   * Click handler - select objects or define axis
   * @param {Object} point - World coordinates {x, y}
   * @param {Event} event - Mouse event
   */
  onClick(point, event) {
    // Phase 1: Object selection
    if (!this.axisP1) {
      const object = this.cad.getObjectAt(point);

      if (object) {
        const index = this.selectedObjects.indexOf(object);

        if (index === -1) {
          // Add to selection
          this.selectedObjects.push(object);
          object._mirrorSelected = true;
        } else if (event.shiftKey) {
          // Remove from selection (Shift+Click)
          this.selectedObjects.splice(index, 1);
          delete object._mirrorSelected;
        }

        this.updatePreview();
        this.updateStatusMessage();
        this.cad.render();
      }
    }
    // Phase 2: Custom axis definition
    else if (!this.axisP2) {
      this.axisP2 = { ...point };
      this.mirrorAxis = { p1: this.axisP1, p2: this.axisP2 };
      this.updatePreview();
      this.cad.render();
    }
  }

  /**
   * Handle keyboard input
   */
  onKeyDown(event) {
    const key = event.key.toLowerCase();

    // Mode switches
    if (key === 'h') {
      this.setMode('horizontal');
      event.preventDefault();
      return true;
    } else if (key === 'v') {
      this.setMode('vertical');
      event.preventDefault();
      return true;
    } else if (key === 'c') {
      this.setMode('custom');
      event.preventDefault();
      return true;
    }

    // Keep original toggle
    if (key === 'k') {
      this.keepOriginal = !this.keepOriginal;
      this.updateStatusMessage();
      event.preventDefault();
      return true;
    }

    // Execute mirror (Enter or Space)
    if (key === 'enter' || key === ' ') {
      if (this.selectedObjects.length > 0) {
        if (this.mode === 'custom' && !this.axisP1) {
          // Start axis definition
          this.startAxisDefinition();
        } else if (this.mode !== 'custom' || (this.axisP1 && this.axisP2)) {
          // Execute mirror
          this.executeMirror();
        }
      }
      event.preventDefault();
      return true;
    }

    // Cancel / Clear
    if (key === 'escape') {
      if (this.axisP1) {
        // Cancel axis definition
        this.axisP1 = null;
        this.axisP2 = null;
        this.mirrorAxis = null;
        this.previewObjects = [];
        this.updateStatusMessage();
        this.cad.render();
      } else if (this.selectedObjects.length > 0) {
        // Clear selection
        this.clearSelection();
      }
      event.preventDefault();
      return true;
    }

    return false;
  }

  /**
   * Set mirror mode
   */
  setMode(mode) {
    this.mode = mode;
    this.axisP1 = null;
    this.axisP2 = null;
    this.mirrorAxis = null;
    this.updatePreview();
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Start axis definition for custom mode
   */
  startAxisDefinition() {
    // Use center of selection as default first point
    const bounds = this.getSelectionBounds();
    this.axisP1 = {
      x: (bounds.minX + bounds.maxX) / 2,
      y: (bounds.minY + bounds.maxY) / 2
    };
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Clear selection
   */
  clearSelection() {
    for (const obj of this.selectedObjects) {
      delete obj._mirrorSelected;
    }
    this.selectedObjects = [];
    this.previewObjects = [];
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Mouse move handler - preview
   * @param {Object} point - World coordinates
   */
  onMove(point) {
    this.hoverPoint = { ...point };

    if (this.axisP1 && !this.axisP2) {
      // Preview custom axis
      this.updatePreview();
      this.cad.render();
    } else if (this.selectedObjects.length > 0 && this.mode !== 'custom') {
      // Update preview for H/V modes
      this.updatePreview();
      this.cad.render();
    }
  }

  /**
   * Update preview objects based on current mode
   */
  updatePreview() {
    this.previewObjects = [];

    if (this.selectedObjects.length === 0) {
      return;
    }

    // Determine mirror axis based on mode
    let axis;

    if (this.mode === 'horizontal') {
      // Mirror across horizontal line through center of selection
      const bounds = this.getSelectionBounds();
      const centerY = (bounds.minY + bounds.maxY) / 2;
      axis = { p1: { x: 0, y: centerY }, p2: { x: 1, y: centerY } };
    } else if (this.mode === 'vertical') {
      // Mirror across vertical line through center of selection
      const bounds = this.getSelectionBounds();
      const centerX = (bounds.minX + bounds.maxX) / 2;
      axis = { p1: { x: centerX, y: 0 }, p2: { x: centerX, y: 1 } };
    } else if (this.mode === 'custom') {
      if (!this.axisP1) {
        return; // No axis yet
      }

      // Use hover point as second point if axis not complete
      const p2 = this.axisP2 || this.hoverPoint;
      if (!p2) return;

      axis = { p1: this.axisP1, p2 };
    } else {
      return;
    }

    // Mirror all selected objects
    for (const obj of this.selectedObjects) {
      const mirrored = this.mirrorObject(obj, axis);
      if (mirrored) {
        this.previewObjects.push(mirrored);
      }
    }
  }

  /**
   * Get bounding box of selected objects
   */
  getSelectionBounds() {
    let minX = Infinity, minY = Infinity;
    let maxX = -Infinity, maxY = -Infinity;

    for (const obj of this.selectedObjects) {
      const bounds = this.getObjectBounds(obj);
      minX = Math.min(minX, bounds.minX);
      minY = Math.min(minY, bounds.minY);
      maxX = Math.max(maxX, bounds.maxX);
      maxY = Math.max(maxY, bounds.maxY);
    }

    return { minX, minY, maxX, maxY };
  }

  /**
   * Get bounding box of single object
   */
  getObjectBounds(obj) {
    let minX = Infinity, minY = Infinity;
    let maxX = -Infinity, maxY = -Infinity;

    const updateBounds = (x, y) => {
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    };

    switch(obj.type) {
      case 'line':
        updateBounds(obj.p1.x, obj.p1.y);
        updateBounds(obj.p2.x, obj.p2.y);
        break;
      case 'rectangle':
        updateBounds(obj.x, obj.y);
        updateBounds(obj.x + obj.width, obj.y + obj.height);
        break;
      case 'circle':
        updateBounds(obj.cx - obj.radius, obj.cy - obj.radius);
        updateBounds(obj.cx + obj.radius, obj.cy + obj.radius);
        break;
      case 'arc':
        updateBounds(obj.cx - obj.radius, obj.cy - obj.radius);
        updateBounds(obj.cx + obj.radius, obj.cy + obj.radius);
        break;
    }

    return { minX, minY, maxX, maxY };
  }

  /**
   * Execute mirror operation
   */
  executeMirror() {
    if (this.selectedObjects.length === 0) return;

    // Ensure we have axis definition
    if (this.mode === 'custom' && (!this.axisP1 || !this.axisP2)) {
      return;
    }

    // Use preview objects (already calculated)
    if (this.previewObjects.length === 0) {
      this.updatePreview();
    }

    // Remove originals if not keeping
    if (!this.keepOriginal) {
      for (const obj of this.selectedObjects) {
        delete obj._mirrorSelected;
        this.cad.removeObject(obj);
      }
    } else {
      // Just clear selection flags
      for (const obj of this.selectedObjects) {
        delete obj._mirrorSelected;
      }
    }

    // Add mirrored objects
    for (const obj of this.previewObjects) {
      this.cad.addObject(obj);
    }

    this.cad.saveHistory();
    this.cad.setStatus(`MIRROR: Created ${this.previewObjects.length} mirrored object(s) ${this.mode} | ${this.keepOriginal ? 'Kept' : 'Removed'} original(s)`);

    // Reset
    this.selectedObjects = [];
    this.mirrorAxis = null;
    this.axisP1 = null;
    this.axisP2 = null;
    this.previewObjects = [];

    this.cad.render();
    this.updateStatusMessage();
  }

  /**
   * Specchia un singolo oggetto rispetto all'asse
   * @param {Object} object - Oggetto da specchiare
   * @param {Object} axis - Asse di simmetria { p1, p2 }
   * @returns {Object|null} Oggetto specchiato
   */
  mirrorObject(object, axis) {
    if (object.type === 'line') {
      return this.mirrorLine(object, axis);
    }

    if (object.type === 'circle') {
      return this.mirrorCircle(object, axis);
    }

    if (object.type === 'arc') {
      return this.mirrorArc(object, axis);
    }

    if (object.type === 'rectangle') {
      return this.mirrorRectangle(object, axis);
    }

    if (object.type === 'polyline') {
      return this.mirrorPolyline(object, axis);
    }

    return null;
  }

  /**
   * Specchia una linea
   * @param {Object} line - Linea { p1, p2 }
   * @param {Object} axis - Asse { p1, p2 }
   * @returns {Object} Linea specchiata
   */
  mirrorLine(line, axis) {
    return {
      type: 'line',
      lineType: line.lineType,
      p1: this.mirrorPoint(line.p1, axis),
      p2: this.mirrorPoint(line.p2, axis)
    };
  }

  /**
   * Specchia un cerchio
   * @param {Object} circle - Cerchio { cx, cy, radius }
   * @param {Object} axis - Asse { p1, p2 }
   * @returns {Object} Cerchio specchiato
   */
  mirrorCircle(circle, axis) {
    const mirroredCenter = this.mirrorPoint({ x: circle.cx, y: circle.cy }, axis);

    return {
      type: 'circle',
      lineType: circle.lineType,
      cx: mirroredCenter.x,
      cy: mirroredCenter.y,
      radius: circle.radius
    };
  }

  /**
   * Specchia un arco
   * @param {Object} arc - Arco { cx, cy, radius, startAngle, endAngle }
   * @param {Object} axis - Asse { p1, p2 }
   * @returns {Object} Arco specchiato
   */
  mirrorArc(arc, axis) {
    const mirroredCenter = this.mirrorPoint({ x: arc.cx, y: arc.cy }, axis);

    // Gli angoli vanno invertiti e ruotati
    const axisAngle = Math.atan2(axis.p2.y - axis.p1.y, axis.p2.x - axis.p1.x);

    const startAngleMirrored = 2 * axisAngle - arc.endAngle;
    const endAngleMirrored = 2 * axisAngle - arc.startAngle;

    return {
      type: 'arc',
      lineType: arc.lineType,
      cx: mirroredCenter.x,
      cy: mirroredCenter.y,
      radius: arc.radius,
      startAngle: startAngleMirrored,
      endAngle: endAngleMirrored
    };
  }

  /**
   * Specchia un rettangolo
   * @param {Object} rect - Rettangolo { x, y, width, height }
   * @param {Object} axis - Asse { p1, p2 }
   * @returns {Object} Rettangolo come polyline specchiata
   */
  mirrorRectangle(rect, axis) {
    // Converti rettangolo in 4 punti
    const points = [
      { x: rect.x, y: rect.y },
      { x: rect.x + rect.width, y: rect.y },
      { x: rect.x + rect.width, y: rect.y + rect.height },
      { x: rect.x, y: rect.y + rect.height }
    ];

    const mirroredPoints = points.map(p => this.mirrorPoint(p, axis));

    return {
      type: 'polyline',
      lineType: rect.lineType,
      points: mirroredPoints,
      closed: true
    };
  }

  /**
   * Specchia una polyline
   * @param {Object} polyline - Polyline { points: [{x, y}, ...], closed }
   * @param {Object} axis - Asse { p1, p2 }
   * @returns {Object} Polyline specchiata
   */
  mirrorPolyline(polyline, axis) {
    const mirroredPoints = polyline.points.map(p => this.mirrorPoint(p, axis));

    return {
      type: 'polyline',
      lineType: polyline.lineType,
      points: mirroredPoints,
      closed: polyline.closed
    };
  }

  /**
   * Specchia un punto rispetto all'asse
   * Formula: P' = P - 2 * dot(P - A, N) * N
   * Dove N è il vettore normale all'asse
   *
   * @param {Object} point - Punto { x, y }
   * @param {Object} axis - Asse { p1, p2 }
   * @returns {Object} Punto specchiato { x, y }
   */
  mirrorPoint(point, axis) {
    // Vettore direzione asse
    const dx = axis.p2.x - axis.p1.x;
    const dy = axis.p2.y - axis.p1.y;
    const len = Math.sqrt(dx * dx + dy * dy);

    // Vettore direzione normalizzato
    const dirX = dx / len;
    const dirY = dy / len;

    // Vettore normale (perpendicolare)
    const normX = -dirY;
    const normY = dirX;

    // Vettore da p1 dell'asse al punto
    const vx = point.x - axis.p1.x;
    const vy = point.y - axis.p1.y;

    // Proiezione su normale (distanza signed dall'asse)
    const dist = vx * normX + vy * normY;

    // Punto specchiato
    return {
      x: point.x - 2 * dist * normX,
      y: point.y - 2 * dist * normY
    };
  }

  /**
   * Custom render for preview and highlights
   * @param {CanvasRenderingContext2D} ctx - Canvas context
   */
  render(ctx) {
    if (!ctx) return;

    // Render preview objects (ghost)
    if (this.previewObjects.length > 0) {
      ctx.save();
      ctx.strokeStyle = '#4ec9b0';
      ctx.fillStyle = 'rgba(78, 201, 176, 0.1)';
      ctx.globalAlpha = 0.5;
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);

      for (const obj of this.previewObjects) {
        this.renderObject(ctx, obj);
      }

      ctx.restore();
    }

    // Render selected objects highlight
    for (const obj of this.selectedObjects) {
      if (obj._mirrorSelected) {
        ctx.save();
        ctx.strokeStyle = '#569cd6';
        ctx.lineWidth = 3;
        ctx.globalAlpha = 0.7;
        ctx.setLineDash([]);

        this.renderObject(ctx, obj);

        ctx.restore();
      }
    }

    // Render mirror axis
    this.renderMirrorAxis(ctx);

    // Render axis definition points (custom mode)
    if (this.axisP1) {
      ctx.save();
      ctx.fillStyle = '#ff9900';
      ctx.beginPath();
      ctx.arc(this.axisP1.x, this.axisP1.y, 5, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }

    if (this.axisP2) {
      ctx.save();
      ctx.fillStyle = '#ff9900';
      ctx.beginPath();
      ctx.arc(this.axisP2.x, this.axisP2.y, 5, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }

  /**
   * Render mirror axis line
   */
  renderMirrorAxis(ctx) {
    if (this.selectedObjects.length === 0) {
      return;
    }

    let axisStart, axisEnd;
    const bounds = this.getSelectionBounds();

    if (this.mode === 'horizontal') {
      const centerY = (bounds.minY + bounds.maxY) / 2;
      axisStart = { x: bounds.minX - 100, y: centerY };
      axisEnd = { x: bounds.maxX + 100, y: centerY };
    } else if (this.mode === 'vertical') {
      const centerX = (bounds.minX + bounds.maxX) / 2;
      axisStart = { x: centerX, y: bounds.minY - 100 };
      axisEnd = { x: centerX, y: bounds.maxY + 100 };
    } else if (this.mode === 'custom' && this.axisP1) {
      const p2 = this.axisP2 || this.hoverPoint;
      if (!p2) return;

      const dx = p2.x - this.axisP1.x;
      const dy = p2.y - this.axisP1.y;
      const length = Math.sqrt(dx * dx + dy * dy);
      if (length < 1) return;

      const extend = 200;
      axisStart = {
        x: this.axisP1.x - (dx / length) * extend,
        y: this.axisP1.y - (dy / length) * extend
      };
      axisEnd = {
        x: p2.x + (dx / length) * extend,
        y: p2.y + (dy / length) * extend
      };
    } else {
      return;
    }

    // Render axis line
    ctx.save();
    ctx.strokeStyle = '#ff9900';
    ctx.lineWidth = 1.5;
    ctx.setLineDash([10, 5]);
    ctx.globalAlpha = 0.7;

    ctx.beginPath();
    ctx.moveTo(axisStart.x, axisStart.y);
    ctx.lineTo(axisEnd.x, axisEnd.y);
    ctx.stroke();

    ctx.restore();
  }

  /**
   * Render an object (helper for ghost preview)
   */
  renderObject(ctx, obj) {
    ctx.beginPath();

    switch(obj.type) {
      case 'line':
        ctx.moveTo(obj.p1.x, obj.p1.y);
        ctx.lineTo(obj.p2.x, obj.p2.y);
        ctx.stroke();
        break;

      case 'rectangle':
        ctx.rect(obj.x, obj.y, obj.width, obj.height);
        ctx.stroke();
        break;

      case 'circle':
        ctx.arc(obj.cx, obj.cy, obj.radius, 0, Math.PI * 2);
        ctx.stroke();
        break;

      case 'arc':
        ctx.arc(obj.cx, obj.cy, obj.radius, obj.startAngle, obj.endAngle);
        ctx.stroke();
        break;

      case 'polyline':
        if (obj.points && obj.points.length > 0) {
          ctx.moveTo(obj.points[0].x, obj.points[0].y);
          for (let i = 1; i < obj.points.length; i++) {
            ctx.lineTo(obj.points[i].x, obj.points[i].y);
          }
          if (obj.closed) {
            ctx.closePath();
          }
          ctx.stroke();
        }
        break;
    }
  }

  /**
   * Imposta se mantenere originali
   * @param {boolean} keep - True per mantenere originali
   */
  setKeepOriginal(keep) {
    this.keepOriginal = keep;
  }

  /**
   * Deactivate tool
   */
  deactivate() {
    this.clearSelection();
    this.mirrorAxis = null;
    this.axisP1 = null;
    this.axisP2 = null;
    this.previewObjects = [];
    this.hoverPoint = null;
  }
}

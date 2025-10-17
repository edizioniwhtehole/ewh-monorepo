/**
 * Scale Tool - Professional CAD Scaling
 * Resize objects uniformly or non-uniformly
 * Week 4 Day 19
 *
 * Features:
 * - Uniform and non-uniform scaling
 * - Interactive base point selection
 * - Scale factor input (drag or manual)
 * - Lock aspect ratio option
 * - Real-time preview with ghost objects
 * - Quick scales (2x, 0.5x, 0.25x)
 * - Works with all object types
 *
 * @module ScaleTool
 * @author Box Designer CAD Engine
 */

export class ScaleTool {
  /**
   * Constructor
   * @param {CADEngine} cadEngine - Reference to CAD engine
   */
  constructor(cadEngine) {
    this.cad = cadEngine;
    this.name = 'scale';
    this.cursor = 'crosshair';

    // State
    this.state = 'selectObjects'; // 'selectObjects', 'selectBase', 'setScale', 'complete'
    this.selectedObjects = [];
    this.basePoint = null;
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.previewObjects = [];

    // Options
    this.uniformScale = true; // Lock aspect ratio
    this.keepOriginal = false;

    // Interaction
    this.isDragging = false;
    this.hoverPoint = null;
    this.dragStartPoint = null;
    this.dragStartDistance = 0;
  }

  /**
   * Activate tool
   */
  activate() {
    this.state = 'selectObjects';
    this.selectedObjects = [];
    this.basePoint = null;
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.previewObjects = [];
    this.isDragging = false;
    this.hoverPoint = null;
    this.updateStatusMessage();
  }

  /**
   * Update status message
   */
  updateStatusMessage() {
    let msg = 'SCALE: ';

    switch(this.state) {
      case 'selectObjects':
        msg += `Select objects to scale | Uniform: ${this.uniformScale ? 'ON' : 'OFF'} (U) | Keep: ${this.keepOriginal ? 'YES' : 'NO'} (K)`;
        break;
      case 'selectBase':
        msg += `${this.selectedObjects.length} selected | Click base point for scaling | Enter = use selection center`;
        break;
      case 'setScale':
        if (this.uniformScale) {
          msg += `Scale: ${this.scaleX.toFixed(2)}x | Drag to scale, S = input, Q = 2x, W = 0.5x, E = 0.25x, Enter = apply`;
        } else {
          msg += `Scale X: ${this.scaleX.toFixed(2)}, Y: ${this.scaleY.toFixed(2)} | Drag to scale, U = uniform, Enter = apply`;
        }
        break;
    }

    this.cad.setStatus(msg);
  }

  /**
   * Handle click
   */
  onClick(point, event) {
    switch(this.state) {
      case 'selectObjects':
        this.handleObjectSelection(point, event);
        break;
      case 'selectBase':
        this.handleBaseSelection(point);
        break;
      case 'setScale':
        // Click applies scale
        this.applyScale();
        break;
    }
  }

  /**
   * Handle object selection
   */
  handleObjectSelection(point, event) {
    const object = this.cad.getObjectAt(point);

    if (object) {
      const index = this.selectedObjects.indexOf(object);

      if (index === -1) {
        // Add to selection
        this.selectedObjects.push(object);
        object._scaleSelected = true;
      } else if (event.shiftKey) {
        // Remove from selection
        this.selectedObjects.splice(index, 1);
        delete object._scaleSelected;
      }

      this.updateStatusMessage();
      this.cad.render();
    }
  }

  /**
   * Handle base point selection
   */
  handleBaseSelection(point) {
    this.basePoint = { ...point };
    this.state = 'setScale';
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.updatePreview();
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Handle mouse down
   */
  onMouseDown(point, event) {
    if (this.state === 'setScale') {
      this.isDragging = true;
      this.dragStartPoint = { ...point };

      // Calculate starting distance from base
      const dx = point.x - this.basePoint.x;
      const dy = point.y - this.basePoint.y;
      this.dragStartDistance = Math.sqrt(dx * dx + dy * dy);

      if (this.dragStartDistance < 1) {
        this.dragStartDistance = 1; // Prevent division by zero
      }
    }
  }

  /**
   * Handle mouse up
   */
  onMouseUp(point, event) {
    if (this.isDragging) {
      this.isDragging = false;
      this.dragStartPoint = null;
    }
  }

  /**
   * Handle mouse move
   */
  onMove(point, event) {
    this.hoverPoint = { ...point };

    if (this.state === 'setScale') {
      if (this.isDragging) {
        // Calculate current distance
        const dx = point.x - this.basePoint.x;
        const dy = point.y - this.basePoint.y;
        const currentDistance = Math.sqrt(dx * dx + dy * dy);

        if (this.uniformScale) {
          // Uniform scaling
          const scale = currentDistance / this.dragStartDistance;
          this.scaleX = scale;
          this.scaleY = scale;
        } else {
          // Non-uniform scaling
          const startDx = this.dragStartPoint.x - this.basePoint.x;
          const startDy = this.dragStartPoint.y - this.basePoint.y;

          this.scaleX = Math.abs(startDx) > 1 ? dx / startDx : 1;
          this.scaleY = Math.abs(startDy) > 1 ? dy / startDy : 1;
        }

        this.updatePreview();
        this.updateStatusMessage();
      }
      this.cad.render();
    }
  }

  /**
   * Handle keyboard input
   */
  onKeyDown(event) {
    const key = event.key.toLowerCase();

    // Uniform scale toggle
    if (key === 'u') {
      this.uniformScale = !this.uniformScale;
      if (this.uniformScale && this.state === 'setScale') {
        // When switching to uniform, use average of X and Y
        this.scaleX = this.scaleY = (this.scaleX + this.scaleY) / 2;
        this.updatePreview();
      }
      this.updateStatusMessage();
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

    // Quick scales
    if (key === 'q') {
      // 2x scale
      if (this.state === 'setScale') {
        this.scaleX = 2.0;
        this.scaleY = 2.0;
        this.updatePreview();
        this.updateStatusMessage();
      }
      event.preventDefault();
      return true;
    }

    if (key === 'w') {
      // 0.5x scale
      if (this.state === 'setScale') {
        this.scaleX = 0.5;
        this.scaleY = 0.5;
        this.updatePreview();
        this.updateStatusMessage();
      }
      event.preventDefault();
      return true;
    }

    if (key === 'e') {
      // 0.25x scale
      if (this.state === 'setScale') {
        this.scaleX = 0.25;
        this.scaleY = 0.25;
        this.updatePreview();
        this.updateStatusMessage();
      }
      event.preventDefault();
      return true;
    }

    // Manual scale input
    if (key === 's') {
      if (this.state === 'setScale') {
        const current = this.uniformScale ? this.scaleX.toFixed(2) : `${this.scaleX.toFixed(2)}, ${this.scaleY.toFixed(2)}`;
        const input = prompt(`Enter scale factor (current: ${current}):`, current);
        if (input !== null) {
          if (this.uniformScale) {
            const scale = parseFloat(input);
            if (!isNaN(scale) && scale > 0) {
              this.scaleX = scale;
              this.scaleY = scale;
              this.updatePreview();
              this.updateStatusMessage();
              this.cad.render();
            }
          } else {
            const parts = input.split(',').map(s => parseFloat(s.trim()));
            if (parts.length === 2 && !isNaN(parts[0]) && !isNaN(parts[1]) && parts[0] > 0 && parts[1] > 0) {
              this.scaleX = parts[0];
              this.scaleY = parts[1];
              this.updatePreview();
              this.updateStatusMessage();
              this.cad.render();
            }
          }
        }
      }
      event.preventDefault();
      return true;
    }

    // Proceed to next step or apply
    if (key === 'enter' || key === ' ') {
      if (this.selectedObjects.length === 0) {
        return false;
      }

      if (this.state === 'selectObjects') {
        // Move to base selection
        this.state = 'selectBase';
        this.updateStatusMessage();
      } else if (this.state === 'selectBase') {
        // Use selection center
        this.useSelectionCenter();
      } else if (this.state === 'setScale') {
        // Apply scale
        this.applyScale();
      }
      event.preventDefault();
      return true;
    }

    // Cancel / Back
    if (key === 'escape') {
      if (this.state === 'setScale') {
        // Back to base selection
        this.state = 'selectBase';
        this.basePoint = null;
        this.scaleX = 1.0;
        this.scaleY = 1.0;
        this.previewObjects = [];
        this.updateStatusMessage();
        this.cad.render();
      } else if (this.state === 'selectBase') {
        // Back to object selection
        this.state = 'selectObjects';
        this.updateStatusMessage();
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
   * Use center of selection as base point
   */
  useSelectionCenter() {
    const bounds = this.getSelectionBounds();
    this.basePoint = {
      x: (bounds.minX + bounds.maxX) / 2,
      y: (bounds.minY + bounds.maxY) / 2
    };
    this.state = 'setScale';
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.updatePreview();
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Update preview objects
   */
  updatePreview() {
    this.previewObjects = [];

    if (this.selectedObjects.length === 0 || !this.basePoint) {
      return;
    }

    // Scale each selected object
    for (const obj of this.selectedObjects) {
      const scaled = this.scaleObject(obj, this.basePoint, this.scaleX, this.scaleY);
      if (scaled) {
        this.previewObjects.push(scaled);
      }
    }
  }

  /**
   * Scale an object
   */
  scaleObject(obj, basePoint, scaleX, scaleY) {
    const scaled = { ...obj };
    delete scaled._scaleSelected;

    switch(obj.type) {
      case 'line':
        scaled.p1 = this.scalePoint(obj.p1, basePoint, scaleX, scaleY);
        scaled.p2 = this.scalePoint(obj.p2, basePoint, scaleX, scaleY);
        break;

      case 'rectangle':
        // Scale corners
        const topLeft = this.scalePoint({ x: obj.x, y: obj.y }, basePoint, scaleX, scaleY);
        const bottomRight = this.scalePoint(
          { x: obj.x + obj.width, y: obj.y + obj.height },
          basePoint,
          scaleX,
          scaleY
        );

        scaled.x = Math.min(topLeft.x, bottomRight.x);
        scaled.y = Math.min(topLeft.y, bottomRight.y);
        scaled.width = Math.abs(bottomRight.x - topLeft.x);
        scaled.height = Math.abs(bottomRight.y - topLeft.y);
        break;

      case 'circle':
        const center = this.scalePoint({ x: obj.cx, y: obj.cy }, basePoint, scaleX, scaleY);
        scaled.cx = center.x;
        scaled.cy = center.y;
        // Scale radius by average of scaleX and scaleY (for uniform appearance)
        scaled.radius = obj.radius * (scaleX + scaleY) / 2;
        break;

      case 'arc':
        const arcCenter = this.scalePoint({ x: obj.cx, y: obj.cy }, basePoint, scaleX, scaleY);
        scaled.cx = arcCenter.x;
        scaled.cy = arcCenter.y;
        scaled.radius = obj.radius * (scaleX + scaleY) / 2;
        // Angles don't change for uniform scaling
        // For non-uniform, this is approximate
        break;

      case 'polyline':
        scaled.points = obj.points.map(p => this.scalePoint(p, basePoint, scaleX, scaleY));
        break;
    }

    return scaled;
  }

  /**
   * Scale a point relative to base point
   */
  scalePoint(point, basePoint, scaleX, scaleY) {
    const dx = point.x - basePoint.x;
    const dy = point.y - basePoint.y;

    return {
      x: basePoint.x + dx * scaleX,
      y: basePoint.y + dy * scaleY
    };
  }

  /**
   * Apply scale
   */
  applyScale() {
    if (this.selectedObjects.length === 0 || !this.basePoint) {
      return;
    }

    // Prevent scaling to zero or negative
    if (this.scaleX <= 0 || this.scaleY <= 0) {
      this.cad.setStatus('SCALE: Invalid scale factor (must be > 0)');
      return;
    }

    if (this.previewObjects.length === 0) {
      this.updatePreview();
    }

    // Remove originals if not keeping
    if (!this.keepOriginal) {
      for (const obj of this.selectedObjects) {
        delete obj._scaleSelected;
        this.cad.removeObject(obj);
      }
    } else {
      for (const obj of this.selectedObjects) {
        delete obj._scaleSelected;
      }
    }

    // Add scaled objects
    for (const obj of this.previewObjects) {
      this.cad.addObject(obj);
    }

    const scaleDesc = this.uniformScale
      ? `${this.scaleX.toFixed(2)}x`
      : `X:${this.scaleX.toFixed(2)}, Y:${this.scaleY.toFixed(2)}`;

    this.cad.saveHistory();
    this.cad.setStatus(`SCALE: Scaled ${this.previewObjects.length} object(s) by ${scaleDesc} | ${this.keepOriginal ? 'Kept' : 'Removed'} original(s)`);

    // Reset
    this.clearSelection();
    this.state = 'selectObjects';
    this.basePoint = null;
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.previewObjects = [];

    this.cad.render();
    this.updateStatusMessage();
  }

  /**
   * Clear selection
   */
  clearSelection() {
    for (const obj of this.selectedObjects) {
      delete obj._scaleSelected;
    }
    this.selectedObjects = [];
    this.previewObjects = [];
    this.updateStatusMessage();
    this.cad.render();
  }

  /**
   * Get selection bounds
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
   * Get object bounds
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
      case 'polyline':
        for (const p of obj.points) {
          updateBounds(p.x, p.y);
        }
        break;
    }

    return { minX, minY, maxX, maxY };
  }

  /**
   * Custom render
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
      if (obj._scaleSelected) {
        ctx.save();
        ctx.strokeStyle = '#569cd6';
        ctx.lineWidth = 3;
        ctx.globalAlpha = 0.7;
        ctx.setLineDash([]);

        this.renderObject(ctx, obj);

        ctx.restore();
      }
    }

    // Render base point
    if (this.basePoint) {
      ctx.save();
      ctx.fillStyle = '#ff9900';
      ctx.strokeStyle = '#ff9900';
      ctx.lineWidth = 2;

      // Cross
      ctx.beginPath();
      ctx.moveTo(this.basePoint.x - 10, this.basePoint.y);
      ctx.lineTo(this.basePoint.x + 10, this.basePoint.y);
      ctx.moveTo(this.basePoint.x, this.basePoint.y - 10);
      ctx.lineTo(this.basePoint.x, this.basePoint.y + 10);
      ctx.stroke();

      // Square
      ctx.strokeRect(this.basePoint.x - 5, this.basePoint.y - 5, 10, 10);

      ctx.restore();
    }

    // Render scale indicators (lines from base to corners of selection)
    if (this.state === 'setScale' && this.basePoint && this.selectedObjects.length > 0) {
      const bounds = this.getSelectionBounds();

      ctx.save();
      ctx.strokeStyle = '#ff9900';
      ctx.lineWidth = 1;
      ctx.setLineDash([3, 3]);
      ctx.globalAlpha = 0.5;

      // Lines to corners
      ctx.beginPath();
      ctx.moveTo(this.basePoint.x, this.basePoint.y);
      ctx.lineTo(bounds.minX, bounds.minY);
      ctx.moveTo(this.basePoint.x, this.basePoint.y);
      ctx.lineTo(bounds.maxX, bounds.maxY);
      ctx.stroke();

      ctx.restore();
    }
  }

  /**
   * Render an object
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
   * Deactivate tool
   */
  deactivate() {
    this.clearSelection();
    this.basePoint = null;
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.previewObjects = [];
    this.isDragging = false;
    this.hoverPoint = null;
    this.dragStartPoint = null;
  }
}
